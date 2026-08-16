import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/booking_model.dart';
import '../services/location_tracking_service.dart';

const kPrimaryPurple = Color(0xFF6C5CE7);

class CustomerTrackingScreen extends StatefulWidget {
  final BookingModel booking;
  const CustomerTrackingScreen({super.key, required this.booking});

  @override
  State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen> {
  final _locationService = LocationTrackingService();
  final MapController _mapController = MapController();
  LatLng? _providerLocation;
  bool _isConnecting = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _locationService.connect();
    await _locationService.joinBookingGroup(widget.booking.id);

    _locationService.onLocationReceived((lat, lng) {
      if (!mounted) return;
      setState(() => _providerLocation = LatLng(lat, lng));
      _mapController.move(LatLng(lat, lng), 15);
    });

    if (!mounted) return;
    setState(() => _isConnecting = false);
  }

  @override
  void dispose() {
    _locationService.leaveBookingGroup(widget.booking.id);
    _locationService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Provider"),
        backgroundColor: kPrimaryPurple,
        foregroundColor: Colors.white,
      ),
      body: _isConnecting
          ? const Center(child: CircularProgressIndicator(color: kPrimaryPurple))
          : _providerLocation == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "Waiting for provider to start the service...",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _providerLocation!,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.upyogi.service_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _providerLocation!,
                          width: 50,
                          height: 50,
                          child: const Icon(Icons.directions_car,
                              color: kPrimaryPurple, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
