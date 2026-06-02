import 'package:geolocator/geolocator.dart';

class GeofenceService {
  // Approximate boundaries of Pila, Laguna
  // These coordinates define a polygon around Pila municipality
  static const List<Map<String, double>> pilaBoundary = [
    {'lat': 14.2500, 'lng': 121.3500}, // Northwest
    {'lat': 14.2500, 'lng': 121.3900}, // Northeast
    {'lat': 14.2100, 'lng': 121.3900}, // Southeast
    {'lat': 14.2100, 'lng': 121.3500}, // Southwest
  ];

  // Check if a point is inside Pila municipality using ray casting algorithm
  static bool isInsidePila(double latitude, double longitude) {
    int intersectCount = 0;

    for (int i = 0; i < pilaBoundary.length; i++) {
      final p1 = pilaBoundary[i];
      final p2 = pilaBoundary[(i + 1) % pilaBoundary.length];

      if (_rayIntersectsSegment(latitude, longitude, p1, p2)) {
        intersectCount++;
      }
    }

    // If odd number of intersections, point is inside
    return intersectCount % 2 == 1;
  }

  static bool _rayIntersectsSegment(
    double lat,
    double lng,
    Map<String, double> p1,
    Map<String, double> p2,
  ) {
    final lat1 = p1['lat']!;
    final lng1 = p1['lng']!;
    final lat2 = p2['lat']!;
    final lng2 = p2['lng']!;

    if (lng1 == lng2) return false;

    final minLng = lng1 < lng2 ? lng1 : lng2;
    final maxLng = lng1 > lng2 ? lng1 : lng2;

    if (lng < minLng) return false;
    if (lng >= maxLng) return false;

    final slope = (lat2 - lat1) / (lng2 - lng1);
    final intersectLat = lat1 + slope * (lng - lng1);

    return lat >= intersectLat;
  }

  // Get current location and check if inside Pila
  static Future<LocationCheckResult> checkCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationCheckResult(
          isInsidePila: false,
          latitude: null,
          longitude: null,
          error: 'Location services are disabled.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationCheckResult(
            isInsidePila: false,
            latitude: null,
            longitude: null,
            error: 'Location permission denied.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationCheckResult(
          isInsidePila: false,
          latitude: null,
          longitude: null,
          error: 'Location permission permanently denied.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final isInside = isInsidePila(position.latitude, position.longitude);

      return LocationCheckResult(
        isInsidePila: isInside,
        latitude: position.latitude,
        longitude: position.longitude,
        error: null,
      );
    } catch (e) {
      return LocationCheckResult(
        isInsidePila: false,
        latitude: null,
        longitude: null,
        error: 'Could not get location: $e',
      );
    }
  }
}

class LocationCheckResult {
  final bool isInsidePila;
  final double? latitude;
  final double? longitude;
  final String? error;

  LocationCheckResult({
    required this.isInsidePila,
    required this.latitude,
    required this.longitude,
    required this.error,
  });
}
