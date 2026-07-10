import 'package:bikinevent/services/event_service.dart';
import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../models/event_model.dart';
import '../theme/app_colors.dart';
import '../widgets/event_card_large.dart';
import 'event_detail_page.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final _eventService = EventService();
  final _locationService = LocationService();
  final _mapController = MapController();

  Position? _userPosition;
  List<EventModel> _nearbyEvents = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Flag di memori saja -- modal muncul lagi tiap kali app dibuka ulang
  // (per sesi), sesuai permintaan "saat session belum berakhir"
  static bool _infoModalShown = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        setState(
          () => _errorMessage =
              'Tidak bisa mengakses lokasi. Pastikan izin lokasi & GPS aktif.',
        );
        return;
      }

      final allEvents = await _eventService.getEvents();
      final nearby = filterNearbyEvents(allEvents, position, 1); // radius 1km

      setState(() {
        _userPosition = position;
        _nearbyEvents = nearby;
      });

      if (!_infoModalShown) {
        _infoModalShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showInfoModal());
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showInfoModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: AppColors.primary, size: 40),
            SizedBox(height: 8),
            Text('Cari Event Disekitarmu', textAlign: TextAlign.center),
          ],
        ),
        content: const Text(
          'Kami menampilkan event yang berada dalam radius 1 km dari lokasimu saat ini.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  void _recenter() {
    if (_userPosition != null) {
      _mapController.move(
        latlong.LatLng(_userPosition!.latitude, _userPosition!.longitude),
        15,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView());
    if (_errorMessage != null) {
      return Scaffold(
        body: ErrorView(message: _errorMessage!, onRetry: _load),
      );
    }

    final center = latlong.LatLng(
      _userPosition!.latitude,
      _userPosition!.longitude,
    );

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: center, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bikinevent',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.blue,
                      size: 30,
                    ),
                  ),
                  ..._nearbyEvents.map(
                    (e) => Marker(
                      point: latlong.LatLng(e.latitude!, e.longitude!),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailPage(eventId: e.id),
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.event,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 50,
            right: 16,
            child: GestureDetector(
              onTap: _recenter,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.my_location, color: AppColors.primary),
              ),
            ),
          ),

          if (_nearbyEvents.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _nearbyEvents.length,
                  itemBuilder: (context, index) {
                    final event = _nearbyEvents[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 250,
                        child: EventCardLarge(
                          event: event,
                          lowestPrice: event.lowestPrice,
                          soldCount: event.totalSold,
                          posterHeight: 130,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EventDetailPage(eventId: event.id),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          else
            const Positioned(
              left: 20,
              right: 20,
              bottom: 30,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Belum ada event dalam radius 1 km dari lokasimu',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
