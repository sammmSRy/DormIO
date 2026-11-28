import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/dormitory.dart';
import '../repositories/dormitory_repository.dart';

/// Free map (OpenStreetMap) - NO API key, NO billing.
/// Shows every dormitory that has a location as a pin.
/// Tap a pin to see the name, price and free slots.
///
/// Member 1 can open it from the Dormitory Finder screen:
///   Navigator.push(context, MaterialPageRoute(
///       builder: (_) => const DormMapPage(city: 'Manila', maxPrice: 8000)));
class DormMapPage extends StatefulWidget {
  const DormMapPage({super.key, this.city, this.maxPrice});

  final String? city;
  final double? maxPrice;

  @override
  State<DormMapPage> createState() => _DormMapPageState();
}

class _DormMapPageState extends State<DormMapPage> {
  static final _manila = LatLng(14.5995, 120.9842);

  final _repo = DormitoryRepository();
  List<Dormitory> _dorms = [];
  Dormitory? _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _repo.search(
        city: widget.city,
        maxPrice: widget.maxPrice,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _dorms = result.items.where((d) => d.hasLocation).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// olive = dorm, blue = condo, red = the pin you tapped
  Color _pinColor(Dormitory d) {
    if (_selected?.id == d.id) return Colors.red;
    return d.propertyType == PropertyType.condo
        ? const Color(0xFF2F6DB5)
        : const Color(0xFF5F5F42);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dorms near you')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _manila,
              initialZoom: 12,
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dormio',
              ),
              MarkerLayer(
                markers: [
                  for (final d in _dorms)
                    Marker(
                      point: LatLng(d.latitude!, d.longitude!),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = d),
                        child: Icon(
                          Icons.location_on,
                          size: 44,
                          color: _pinColor(d),
                        ),
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          const Positioned(
            top: 12,
            left: 12,
            child: Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: Color(0xFF5F5F42)),
                    Text('Dorm  '),
                    Icon(Icons.location_on, color: Color(0xFF2F6DB5)),
                    Text('Condo'),
                  ],
                ),
              ),
            ),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (!_loading && _error == null && _dorms.isEmpty)
            const Align(
              alignment: Alignment.topCenter,
              child: Card(
                margin: EdgeInsets.all(12),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No dorms with a location yet.'),
                ),
              ),
            ),
          if (_error != null)
            Align(
              alignment: Alignment.topCenter,
              child: Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Could not load dorms: $_error'),
                ),
              ),
            ),
          if (_selected != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(_selected!.name),
                  subtitle: Text(
                    '${PropertyType.label(_selected!.propertyType)} · '
                    '${_selected!.address}, ${_selected!.city}\n'
                    '₱${_selected!.pricePerMonth.toStringAsFixed(0)} / month · '
                    '${_selected!.availableSlots} slot(s) left',
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
