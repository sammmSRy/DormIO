import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/converters.dart';

class RoomType {
  static const single = 'single';
  static const twin = 'twin';
  static const shared = 'shared';
  static const studio = 'studio';
  static const all = [single, twin, shared, studio];
}

class PropertyType {
  static const dorm = 'dorm';
  static const condo = 'condo';
  static const apartment = 'apartment';
  static const all = [dorm, condo, apartment];

  static String label(String t) =>
      t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

class Dormitory {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String address;
  final String city;
  final String roomType;

  /// 'dorm', 'condo' or 'apartment' (older listings without it count as dorm)
  final String propertyType;
  final double pricePerMonth;
  final int capacity;
  final int availableSlots;
  final List<String> amenities;
  final List<String> photos;
  final String houseRules;
  final bool isActive;

  /// Map location (optional). Both are set together, or both stay null.
  final double? latitude;
  final double? longitude;

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
    this.propertyType = PropertyType.dorm,
    required this.pricePerMonth,
    required this.capacity,
    required this.availableSlots,
    this.amenities = const [],
    this.photos = const [],
    this.houseRules = '',
    this.isActive = true,
    this.latitude,
    this.longitude,
    this.residentIds = const [],
    this.createdAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

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
      propertyType: d['propertyType'] ?? PropertyType.dorm,
      pricePerMonth: toDouble(d['pricePerMonth']),
      capacity: toInt(d['capacity']),
      availableSlots: toInt(d['availableSlots']),
      amenities: stringList(d['amenities']),
      photos: stringList(d['photos']),
      houseRules: d['houseRules'] ?? '',
      isActive: d['isActive'] ?? true,
      latitude: d['latitude'] is num ? (d['latitude'] as num).toDouble() : null,
      longitude: d['longitude'] is num ? (d['longitude'] as num).toDouble() : null,
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
    if (!PropertyType.all.contains(propertyType)) return 'Invalid property type';
    if (pricePerMonth <= 0 || pricePerMonth > 1000000) {
      return 'Price must be between 1 and 1,000,000';
    }
    if (capacity < 1 || capacity > 50) return 'Capacity must be 1-50';
    if (availableSlots < 0 || availableSlots > capacity) {
      return 'Available slots must be between 0 and capacity';
    }
    if ((latitude == null) != (longitude == null)) {
      return 'Set both latitude and longitude, or neither';
    }
    if (latitude != null && (latitude! < -90 || latitude! > 90)) {
      return 'Latitude must be between -90 and 90';
    }
    if (longitude != null && (longitude! < -180 || longitude! > 180)) {
      return 'Longitude must be between -180 and 180';
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
        'propertyType': propertyType,
        'pricePerMonth': pricePerMonth,
        'capacity': capacity,
        'availableSlots': availableSlots,
        'amenities': amenities,
        'photos': photos,
        'houseRules': houseRules,
        'isActive': isActive,
        if (latitude != null && longitude != null) 'latitude': latitude,
        if (latitude != null && longitude != null) 'longitude': longitude,
        'residentIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
