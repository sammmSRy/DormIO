import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/db_exception.dart';
import '../core/firestore_paths.dart';
import '../core/validators.dart';
import '../models/app_user.dart';

/// users/{uid}  — the document id is ALWAYS the Firebase Auth uid.
class UserRepository {
  UserRepository([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.users);

  /// Call this right after FirebaseAuth.createUserWithEmailAndPassword()
  /// (Member 2) from the Create Account screen (Member 1).
  Future<void> createProfile({
    required String uid,
    required String fullName,
    required String email,
    required String phone, // use Validators.toE164('+81', input)
    required String role, // UserRole.seeker or UserRole.host
  }) async {
    final error = Validators.fullName(fullName) ??
        Validators.email(email) ??
        Validators.phone(phone);
    if (error != null) throw DbException(error);
    if (!UserRole.all.contains(role)) throw DbException('Invalid role');

    await _col.doc(uid).set({
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'phone': Validators.normalizePhone(phone),
      'role': role,
      'isVerified': false, // only an admin / Cloud Function may change this
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final snap = await _col.doc(uid).get();
    return snap.exists ? AppUser.fromDoc(snap) : null;
  }

  Stream<AppUser?> watchUser(String uid) => _col
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? AppUser.fromDoc(s) : null);

  Future<void> updateProfile(
    String uid, {
    String? fullName,
    String? phone,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) {
      final e = Validators.fullName(fullName);
      if (e != null) throw DbException(e);
      updates['fullName'] = fullName.trim();
    }
    if (phone != null) {
      final e = Validators.phone(phone);
      if (e != null) throw DbException(e);
      updates['phone'] = Validators.normalizePhone(phone);
    }
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (updates.isEmpty) return;
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(uid).update(updates);
  }
}
