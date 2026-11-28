# DormIO — Member 3: Database & Integration

Firestore structure, validation, security rules, indexes, data layer ("APIs"), tests.

## Folder map
| Path | What it is |
|---|---|
| `lib/core/` | collection names, validators, error type, converters |
| `lib/models/` | Dart classes: AppUser, Dormitory, Reservation, Expense, Chore, Conversation, ChatMessage |
| `lib/repositories/` | the data API used by Member 1 (UI) and Member 2 (logic) |
| `lib/dev/db_smoke_test_page.dart` | one-button check that everything is connected |
| `firestore.rules` | security rules + server-side validation |
| `firestore.indexes.json` | composite indexes for the search/sort queries |
| `firebase.json` | rules/indexes/emulator config |
| `test/` | Flutter unit tests (fake Firestore, no internet needed) |
| `rules_test/` | security-rule tests (run on the Firebase emulator) |

## Database structure
```
users/{uid}                       uid = Firebase Auth uid
dormitories/{dormId}              ownerId -> users, residentIds[] -> users
reservations/{id}                 tenantId -> users, ownerId -> users, dormId -> dormitories
expenses/{id}                     dormId -> dormitories, paidBy -> users, shares{uid: amount}
chores/{id}                       dormId -> dormitories, assignedTo -> users
conversations/{uidA_uidB}         participantIds[2]
   └─ messages/{id}               senderId, text, createdAt
```

Relationships
- user (host) 1 ── * dormitories (`ownerId`)
- user (seeker) 1 ── * reservations (`tenantId`); dormitory 1 ── * reservations (`dormId`)
- an **approved** reservation adds the tenant to `dormitories.residentIds` and lowers `availableSlots`
- residents (and the host) can read/write that dorm's expenses and chores — enforced by the rules

## Integration contract (what to tell Members 1 and 2)
```dart
import 'package:dormio/repositories/repositories.dart';

// After FirebaseAuth.createUserWithEmailAndPassword(...)  (Member 2)
await UserRepository().createProfile(
  uid: cred.user!.uid, fullName: name, email: email,
  phone: Validators.toE164('+81', phoneInput), role: UserRole.seeker);

// Form validation (Member 1)
TextFormField(validator: Validators.email)
TextFormField(validator: Validators.password)

// Dormitory finder
final page = await DormitoryRepository().search(city: 'Manila', maxPrice: 8000);

// Reservation
await ReservationRepository().createReservation(
  dormId: id, tenantId: uid, moveInDate: date, durationMonths: 6);
await ReservationRepository().hostUpdateStatus(
  reservationId: rid, newStatus: ReservationStatus.approved);

// Live lists for the UI
StreamBuilder<List<Reservation>>(stream: ReservationRepository().watchTenantReservations(uid), ...)
```
Every repository throws `DbException` with a message that is safe to show to the user.
