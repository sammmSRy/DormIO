import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/converters.dart';

/// Matches the two cards on the Create Account screen.
class UserRole {
  static const seeker = 'seeker'; // "Looking for a Room"
  static const host = 'host'; // "List or Manage"
  static const all = [seeker, host];
}

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final bool isVerified;
  final String? photoUrl;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.isVerified = false,
    this.photoUrl,
    this.createdAt,
  });

  bool get isHost => role == UserRole.host;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      fullName: d['fullName'] ?? '',
      email: d['email'] ?? '',
      phone: d['phone'] ?? '',
      role: d['role'] ?? UserRole.seeker,
      isVerified: d['isVerified'] ?? false,
      photoUrl: d['photoUrl'],
      createdAt: toDate(d['createdAt']),
    );
  }
}
