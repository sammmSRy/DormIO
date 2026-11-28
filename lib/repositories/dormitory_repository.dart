import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/db_exception.dart';
import '../core/firestore_paths.dart';
import '../models/dormitory.dart';

class DormSearchResult {
  final List<Dormitory> items;

  /// Pass this as `startAfter` to load the next page.
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  const DormSearchResult(this.items, this.lastDoc, this.hasMore);
}

/// dormitories/{dormId}
class DormitoryRepository {
  DormitoryRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.dormitories);

  Future<String> createDormitory(Dormitory dorm) async {
    final error = dorm.validate();
    if (error != null) throw DbException(error);
    final ref = await _col.add(dorm.toCreateMap());
    return ref.id;
  }

  Future<Dormitory?> getById(String id) async {
    final snap = await _col.doc(id).get();
    return snap.exists ? Dormitory.fromDoc(snap) : null;
  }

  Stream<Dormitory?> watchById(String id) => _col
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? Dormitory.fromDoc(s) : null);

  /// Dormitory Finder (search + filter + pagination).
  /// Results are sorted by price (cheapest first).
  /// Needs the composite indexes in firestore.indexes.json.
  Future<DormSearchResult> search({
    String? city,
    String? roomType,
    String? amenity,
    double? minPrice,
    double? maxPrice,
    String? nameQuery, // filtered on the device (Firestore has no "contains")
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _col.where('isActive', isEqualTo: true);
    if (city != null && city.trim().isNotEmpty) {
      q = q.where('city', isEqualTo: city.trim());
    }
    if (roomType != null) q = q.where('roomType', isEqualTo: roomType);
    if (amenity != null) q = q.where('amenities', arrayContains: amenity);
    if (minPrice != null) {
      q = q.where('pricePerMonth', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      q = q.where('pricePerMonth', isLessThanOrEqualTo: maxPrice);
    }
    q = q.orderBy('pricePerMonth');
    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snap = await q.limit(limit).get();
    var items = snap.docs.map(Dormitory.fromDoc).toList();

    final text = nameQuery?.trim().toLowerCase() ?? '';
    if (text.isNotEmpty) {
      items = items
          .where((d) =>
              d.name.toLowerCase().contains(text) ||
              d.address.toLowerCase().contains(text))
          .toList();
    }
    return DormSearchResult(
      items,
      snap.docs.isEmpty ? null : snap.docs.last,
      snap.docs.length == limit,
    );
  }

  /// Dorms owned by a host ("List or Manage" role).
  Stream<List<Dormitory>> watchByOwner(String ownerId) => _col
      .where('ownerId', isEqualTo: ownerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Dormitory.fromDoc).toList());

  /// Only the fields you pass are changed (ownerId can never change).
  Future<void> updateDormitory(String id, Map<String, dynamic> fields) async {
    fields.remove('ownerId');
    fields['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(id).update(fields);
  }

  Future<void> setActive(String id, bool active) =>
      updateDormitory(id, {'isActive': active});

  Future<void> deleteDormitory(String id) => _col.doc(id).delete();
}
