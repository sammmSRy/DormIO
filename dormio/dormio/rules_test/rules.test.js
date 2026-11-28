// Run with the emulator:  firebase emulators:exec --only firestore "cd rules_test && npm test"
const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');

const now = () => firebase.firestore.FieldValue.serverTimestamp();
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'dormio-rules-test',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});
after(async () => env.cleanup());
beforeEach(async () => env.clearFirestore());

const userDoc = (role, extra = {}) => ({
  fullName: 'Test User',
  email: 'test@example.com',
  phone: '+639171234567',
  role,
  isVerified: false,
  createdAt: now(),
  updatedAt: now(),
  ...extra,
});

const dormDoc = (ownerId) => ({
  ownerId,
  name: 'Test Dorm',
  description: '',
  address: '123 Test St',
  city: 'Manila',
  roomType: 'shared',
  pricePerMonth: 5000,
  capacity: 2,
  availableSlots: 2,
  amenities: [],
  photos: [],
  houseRules: '',
  isActive: true,
  residentIds: [],
  createdAt: now(),
  updatedAt: now(),
});

async function seed(fn) {
  await env.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

test('user can create own profile as seeker or host', async () => {
  const db = env.authenticatedContext('u1').firestore();
  await assertSucceeds(db.doc('users/u1').set(userDoc('seeker')));
});

test('user cannot create a profile with role "admin" or isVerified=true', async () => {
  const db = env.authenticatedContext('u1').firestore();
  await assertFails(db.doc('users/u1').set(userDoc('admin')));
  await assertFails(db.doc('users/u1').set(userDoc('seeker', { isVerified: true })));
});

test('user cannot create a profile for someone else', async () => {
  const db = env.authenticatedContext('u1').firestore();
  await assertFails(db.doc('users/u2').set(userDoc('seeker')));
});

test('user cannot change their own role', async () => {
  await seed((db) => db.doc('users/u1').set(userDoc('seeker')));
  const db = env.authenticatedContext('u1').firestore();
  await assertFails(db.doc('users/u1').update({ role: 'host', updatedAt: now() }));
});

test('only a host can create a dormitory', async () => {
  await seed(async (db) => {
    await db.doc('users/seeker1').set(userDoc('seeker'));
    await db.doc('users/host1').set(userDoc('host'));
  });
  await assertFails(env.authenticatedContext('seeker1').firestore().collection('dormitories').add(dormDoc('seeker1')));
  await assertSucceeds(env.authenticatedContext('host1').firestore().collection('dormitories').add(dormDoc('host1')));
});

test('signed-out users cannot read dormitories', async () => {
  await assertFails(env.unauthenticatedContext().firestore().collection('dormitories').get());
});

test('strangers cannot read someone else\'s reservation', async () => {
  await seed((db) =>
    db.doc('reservations/r1').set({ tenantId: 't1', ownerId: 'h1', dormId: 'd1', status: 'pending' }));
  await assertSucceeds(env.authenticatedContext('t1').firestore().doc('reservations/r1').get());
  await assertSucceeds(env.authenticatedContext('h1').firestore().doc('reservations/r1').get());
  await assertFails(env.authenticatedContext('stranger').firestore().doc('reservations/r1').get());
});

test('non-residents cannot read expenses of a dorm', async () => {
  await seed(async (db) => {
    await db.doc('dormitories/d1').set({ ...dormDoc('h1'), residentIds: ['t1'] });
    await db.doc('expenses/e1').set({ dormId: 'd1', paidBy: 't1', title: 'Water', amount: 100 });
  });
  await assertSucceeds(env.authenticatedContext('t1').firestore().doc('expenses/e1').get());
  await assertFails(env.authenticatedContext('stranger').firestore().doc('expenses/e1').get());
});
