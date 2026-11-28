import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/converters.dart';

class RoomType {
  static const single = 'single';
  static const twin = 'twin';
  static const shared = 'shared';
  static const studio = 'studio';
  static const all = [single, twin, shared, studio];
}

class Dormitory {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String address;
  final String city;
  final String roomType;
  final double pricePerMonth;
  final int capacity;
  final int availableSlots;
  final List<String> amenities;
  final List<String> photos;
  final String houseRules;
  final bool isActive;

  /// uids of tenants whose reservation was approved. Used by security rules
  /// to decide who may read/write expenses and chores of this dorm.
  final List<String> residentIds;
  final DateTime? createdAt;

  const Dormitory({
    this.id = '',
    required this.ownerId,
    required this.name,
    this.description = '',
    required this.address,
    required this.city,
    required this.roomType,
    required this.pricePerMonth,
    required this.capacity,
    required this.availableSlots,
    this.amenities = const [],
    this.photos = const [],
    this.houseRules = '',
    this.isActive = true,
    this.residentIds = const [],
    this.createdAt,
  });

  factory Dormitory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Dormitory(
      id: doc.id,
      ownerId: d['ownerId'] ?? '',
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      address: d['address'] ?? '',
      city: d['city'] ?? '',
      roomType: d['roomType'] ?? RoomType.single,
      pricePerMonth: toDouble(d['pricePerMonth']),
      capacity: toInt(d['capacity']),
      availableSlots: toInt(d['availableSlots']),
      amenities: stringList(d['amenities']),
      photos: stringList(d['photos']),
      houseRules: d['houseRules'] ?? '',
      isActive: d['isActive'] ?? true,
      residentIds: stringList(d['residentIds']),
      createdAt: toDate(d['createdAt']),
    );
  }

  /// Returns an error message, or null when valid. Mirrors firestore.rules.
  String? validate() {
    if (name.trim().length < 3 || name.trim().length > 80) {
      return 'Dorm name must be 3-80 characters';
    }
    if (address.trim().length < 3) return 'Address is required';
    if (city.trim().length < 2) return 'City is required';
    if (!RoomType.all.contains(roomType)) return 'Invalid room type';
    if (pricePerMonth <= 0 || pricePerMonth > 1000000) {
      return 'Price must be between 1 and 1,000,000';
    }
    if (capacity < 1 || capacity > 50) return 'Capacity must be 1-50';
    if (availableSlots < 0 || availableSlots > capacity) {
      return 'Available slots must be between 0 and capacity';
    }
    return null;
  }

  /// Map used when CREATING a dorm (timestamps are set by the server).
  Map<String, dynamic> toCreateMap() => {
        'ownerId': ownerId,
        'name': name.trim(),
        'description': description.trim(),
        'address': address.trim(),
        'city': city.trim(),
        'roomType': roomType,
        'pricePerMonth': pricePerMonth,
        'capacity': capacity,
        'availableSlots': availableSlots,
        'amenities': amenities,
        'photos': photos,
        'houseRules': houseRules,
        'isActive': isActive,
        'residentIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
