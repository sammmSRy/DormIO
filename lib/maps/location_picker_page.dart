import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Lets a host tap the map to choose where their dorm is (free OpenStreetMap).
/// Returns the chosen LatLng (or null if they go back without saving).
///
/// Use it on the "List a dorm" form (Member 1):
///   final LatLng? spot = await Navigator.push<LatLng>(context,
///       MaterialPageRoute(builder: (_) => const LocationPickerPage()));
///   if (spot != null) {
///     // pass spot.latitude and spot.longitude into Dormitory(...)
///   }
/// (LatLng comes from: import 'package:latlong2/latlong.dart';)
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.initial});

  final LatLng? initial;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static final _manila = LatLng(14.5995, 120.9842);
  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick dorm location'),
        actions: [
          TextButton(
            onPressed: _picked == null ? null : () => Navigator.pop(context, _picked),
            child: const Text('Save'),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _picked ?? _manila,
          initialZoom: 13,
          onTap: (_, point) => setState(() => _picked = point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.dormio',
          ),
          if (_picked != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _picked!,
                  width: 44,
                  height: 44,
                  child: const Icon(Icons.location_on, size: 44, color: Colors.red),
                ),
              ],
            ),
          const RichAttributionWidget(
            attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
          ),
        ],
      ),
    );
  }
}
