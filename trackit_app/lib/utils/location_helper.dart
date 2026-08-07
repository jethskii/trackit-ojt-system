import 'package:geolocator/geolocator.dart';

/// A user-facing reason the device position couldn't be read (permission
/// denied, location services off, etc.), as opposed to a generic failure.
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);
}

/// Requests permission (if needed) and returns the device's current GPS
/// position. Throws [LocationException] with a message ready to show
/// directly to the user.
Future<Position> getCurrentPosition() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw const LocationException(
      'Turn on location services, then try again.',
    );
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw const LocationException(
      'Location permission is required for this action.',
    );
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
}
