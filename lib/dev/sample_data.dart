import '../models/dormitory.dart';

/// Sample listings for testing and for your demo. These are made-up listings
/// placed near well-known campuses in Metro Manila (not real businesses).
/// Prices are per month and are meant to be student-budget friendly:
///   bedspace  P1,500 - P3,500  |  private room  P4,500 - P5,500
///   condo (shared)  P5,500 - P6,500  |  condo studio  P6,800 - P7,500
List<Dormitory> buildSampleListings(String ownerId) {
  Dormitory d(
    String name,
    String type, // PropertyType
    String room, // RoomType
    String address,
    String city,
    double price,
    int capacity,
    int slots,
    double lat,
    double lng,
    List<String> amenities,
  ) =>
      Dormitory(
        ownerId: ownerId,
        name: name,
        propertyType: type,
        roomType: room,
        address: address,
        city: city,
        pricePerMonth: price,
        capacity: capacity,
        availableSlots: slots,
        latitude: lat,
        longitude: lng,
        amenities: amenities,
        description: 'Sample listing for the DormIO demo.',
      );

  const dorm = PropertyType.dorm;
  const condo = PropertyType.condo;

  return [
    // ---------- Manila: U-Belt / Sampaloc / Recto ----------
    d('Sampaloc Bedspace Haven', dorm, RoomType.shared, 'Dapitan St, Sampaloc', 'Manila', 2200, 8, 3, 14.6112, 120.9895, ['wifi', 'laundry', 'study area']),
    d('Espana Budget Dorm', dorm, RoomType.shared, 'Espana Blvd, Sampaloc', 'Manila', 1800, 10, 4, 14.6089, 120.9922, ['wifi', 'cctv']),
    d('Lacson Student Lodge', dorm, RoomType.twin, 'Lacson Ave, Sampaloc', 'Manila', 3200, 4, 2, 14.6123, 120.9871, ['wifi', 'aircon', 'laundry']),
    d('Morayta Study Nook', dorm, RoomType.single, 'Morayta St, Sampaloc', 'Manila', 4800, 6, 1, 14.6044, 120.9886, ['wifi', 'aircon', 'private bathroom']),
    d('Recto Bedspace Corner', dorm, RoomType.shared, 'CM Recto Ave', 'Manila', 1900, 12, 5, 14.6034, 120.9835, ['wifi', 'cctv']),
    d('U-Belt Condo Studio', condo, RoomType.studio, 'Legarda St, Sampaloc', 'Manila', 6800, 2, 1, 14.6021, 120.9930, ['wifi', 'aircon', 'kitchen']),
    // ---------- Manila: Taft / Intramuros / Sta. Mesa ----------
    d('Taft Scholar Dorm', dorm, RoomType.twin, 'Taft Ave, Malate', 'Manila', 3800, 6, 2, 14.5648, 120.9932, ['wifi', 'aircon', 'laundry']),
    d('Taft Condo Share', condo, RoomType.shared, 'Taft Ave, Malate', 'Manila', 5500, 4, 2, 14.5671, 120.9937, ['wifi', 'aircon', 'gym', 'pool']),
    d('Intramuros Lodge', dorm, RoomType.shared, 'Muralla St, Intramuros', 'Manila', 2800, 8, 3, 14.5906, 120.9757, ['wifi', 'laundry']),
    d('Sta. Mesa Bedspaces', dorm, RoomType.shared, 'Pureza St, Sta. Mesa', 'Manila', 1500, 12, 6, 14.5979, 121.0110, ['wifi', 'kitchen']),
    d('Sta. Mesa Twin Rooms', dorm, RoomType.twin, 'Ramon Magsaysay Blvd, Sta. Mesa', 'Manila', 3000, 6, 3, 14.6041, 121.0049, ['wifi', 'aircon']),
    // ---------- Quezon City: Katipunan / UP / Cubao ----------
    d('Katipunan Student Dorm', dorm, RoomType.shared, 'Katipunan Ave', 'Quezon City', 3500, 8, 3, 14.6396, 121.0775, ['wifi', 'aircon', 'study area']),
    d('Katipunan Condo Share', condo, RoomType.shared, 'Katipunan Ave', 'Quezon City', 6500, 4, 2, 14.6350, 121.0760, ['wifi', 'aircon', 'pool', 'gym']),
    d('Maginhawa Budget Dorm', dorm, RoomType.shared, 'Maginhawa St, Teachers Village', 'Quezon City', 2800, 10, 4, 14.6526, 121.0587, ['wifi', 'laundry', 'kitchen']),
    d('Maginhawa Single Rooms', dorm, RoomType.single, 'Maginhawa St, Teachers Village', 'Quezon City', 5200, 6, 2, 14.6537, 121.0609, ['wifi', 'aircon', 'private bathroom']),
    d('Cubao Commuter Condo', condo, RoomType.shared, 'Aurora Blvd, Cubao', 'Quezon City', 5800, 4, 3, 14.6200, 121.0510, ['wifi', 'aircon', 'elevator']),
    d('Anonas Bedspace Hub', dorm, RoomType.shared, 'Anonas St', 'Quezon City', 2000, 10, 7, 14.6280, 121.0640, ['wifi', 'cctv']),
    // ---------- Mandaluyong / Makati ----------
    d('Shaw Student Condo', condo, RoomType.shared, 'Shaw Blvd', 'Mandaluyong', 6200, 4, 2, 14.5810, 121.0530, ['wifi', 'aircon', 'gym']),
    d('Poblacion Condo Studio', condo, RoomType.studio, 'Poblacion', 'Makati', 7500, 2, 1, 14.5650, 121.0290, ['wifi', 'aircon', 'kitchen']),
  ];
}
