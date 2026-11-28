import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../repositories/repositories.dart';

/// Developer-only screen: proves Firebase, the rules, the indexes and the
/// repositories all work together. Delete it (or keep it for demos) later.
/// Needs "Anonymous" sign-in enabled in Firebase Console > Authentication.
class DbSmokeTestPage extends StatefulWidget {
  const DbSmokeTestPage({super.key});

  @override
  State<DbSmokeTestPage> createState() => _DbSmokeTestPageState();
}

class _DbSmokeTestPageState extends State<DbSmokeTestPage> {
  final List<String> _log = [];
  bool _busy = false;

  void _add(String line) => setState(() => _log.add(line));

  List<Dormitory> _samples(String ownerId) => [
        Dormitory(
          ownerId: ownerId,
          name: 'Sampaloc Quiet Dorm',
          description: 'Five minutes from UST.',
          address: 'Dapitan St, Sampaloc',
          city: 'Manila',
          roomType: RoomType.shared,
          pricePerMonth: 4500,
          capacity: 4,
          availableSlots: 3,
          amenities: const ['wifi', 'laundry'],
        ),
        Dormitory(
          ownerId: ownerId,
          name: 'Espana Studio Suites',
          address: 'Espana Blvd',
          city: 'Manila',
          roomType: RoomType.studio,
          pricePerMonth: 7800,
          capacity: 2,
          availableSlots: 2,
          amenities: const ['wifi', 'aircon'],
        ),
        Dormitory(
          ownerId: ownerId,
          name: 'Katipunan Twin Rooms',
          address: 'Katipunan Ave',
          city: 'Quezon City',
          roomType: RoomType.twin,
          pricePerMonth: 9500,
          capacity: 2,
          availableSlots: 1,
          amenities: const ['wifi'],
        ),
      ];

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _log.clear();
    });
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      final uid = cred.user!.uid;
      _add('✔ Signed in (anonymous): $uid');

      final users = UserRepository();
      if (await users.getUser(uid) == null) {
        await users.createProfile(
          uid: uid,
          fullName: 'Test Host',
          email: 'host@example.com',
          phone: Validators.toE164('+63', '0917 123 4567'),
          role: UserRole.host,
        );
        _add('✔ Created host profile');
      }

      final dorms = DormitoryRepository();
      for (final d in _samples(uid)) {
        final id = await dorms.createDormitory(d);
        _add('✔ Created "${d.name}" -> $id');
      }

      final result = await dorms.search(city: 'Manila', maxPrice: 8000);
      _add('✔ Search (Manila, <= ₱8,000): ${result.items.length} result(s)');
      for (final d in result.items) {
        _add('    • ${d.name} — ₱${d.pricePerMonth.toStringAsFixed(0)}');
      }
      _add('🎉 Smoke test passed');
    } on FirebaseException catch (e) {
      _add('✘ Firebase error [${e.code}]: ${e.message}');
      if (e.code == 'failed-precondition') {
        _add('  → The composite index is still building, or not deployed.');
        _add('    Run: firebase deploy --only firestore:indexes');
      }
      if (e.code == 'permission-denied') {
        _add('  → A security rule blocked this. Run: firebase deploy --only firestore:rules');
      }
    } on DbException catch (e) {
      _add('✘ ${e.message}');
    } catch (e) {
      _add('✘ $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DormIO · Database check')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: _busy ? null : _run,
              child: Text(_busy ? 'Running…' : 'Run database smoke test'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [for (final l in _log) Text(l)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
