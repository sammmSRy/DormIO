import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../core/firestore_paths.dart';
import '../maps/dorm_map_page.dart';
import '../repositories/repositories.dart';
import 'sample_data.dart';

/// Developer-only screen: proves Firebase, the rules, the indexes and the
/// repositories all work together, and loads sample dorms + condos so the
/// map has something to show.
/// Needs "Anonymous" sign-in enabled in Firebase Console > Authentication.
class DbSmokeTestPage extends StatefulWidget {
  const DbSmokeTestPage({super.key});

  @override
  State<DbSmokeTestPage> createState() => _DbSmokeTestPageState();
}

class _DbSmokeTestPageState extends State<DbSmokeTestPage> {
  final List<String> _log = [];
  bool _busy = false;

  void _add(String line) {
    if (mounted) setState(() => _log.add(line));
  }

  @override
  void initState() {
    super.initState();
    _signInQuietly(); // so "Open dorm map" works even before running the test
  }

  Future<void> _signInQuietly() async {
    try {
      await _ensureSignedIn();
    } catch (e) {
      _add('✘ Could not sign in: $e');
    }
  }

  Future<User> _ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    return auth.currentUser ?? (await auth.signInAnonymously()).user!;
  }

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _log.clear();
    });
    try {
      final uid = (await _ensureSignedIn()).uid;
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

      // Remove this account's earlier sample listings so they don't pile up.
      final old = await FirebaseFirestore.instance
          .collection(FirestorePaths.dormitories)
          .where('ownerId', isEqualTo: uid)
          .get();
      for (final doc in old.docs) {
        await dorms.deleteDormitory(doc.id);
      }
      _add('✔ Removed ${old.docs.length} old sample listing(s)');

      final samples = buildSampleListings(uid);
      await Future.wait(samples.map(dorms.createDormitory));
      _add('✔ Added ${samples.length} sample dorms and condos');

      final result = await dorms.search(city: 'Manila', maxPrice: 4000);
      _add('✔ Search (Manila, up to ₱4,000): ${result.items.length} result(s)');
      for (final d in result.items.take(8)) {
        _add('    • ${d.name} (${d.propertyType}) — ₱${d.pricePerMonth.toStringAsFixed(0)}');
      }
      _add('🎉 Smoke test passed — tap "Open dorm map"');
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
              child: Text(_busy ? 'Running…' : 'Run database smoke test + load sample listings'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DormMapPage()),
              ),
              child: const Text('Open dorm map'),
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
