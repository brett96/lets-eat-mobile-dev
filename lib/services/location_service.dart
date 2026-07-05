import 'package:geolocator/geolocator.dart';

/// Wraps geolocator with the permission flow required on modern
/// Android (10+) and iOS. Location is used transiently and never stored.
class LocationService {
  Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationException('Location permission denied.');
    }
    return Geolocator.getCurrentPosition();
  }
}

class LocationException implements Exception {
  const LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}
