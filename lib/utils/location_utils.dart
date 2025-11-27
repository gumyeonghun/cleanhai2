import 'dart:math';

class LocationUtils {
  static const double _earthRadiusKm = 6371.0;

  static double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    final dLat = _degreesToRadians(endLat - startLat);
    final dLng = _degreesToRadians(endLng - startLng);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(startLat)) *
            cos(_degreesToRadians(endLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return _earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
  
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    }
    return '${distanceKm.toStringAsFixed(1)}km';
  }
}
