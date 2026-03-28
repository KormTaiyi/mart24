import 'package:geolocator/geolocator.dart';

enum PostLocationFailure {
  permissionDenied,
  permissionDeniedForever,
  servicesDisabled,
  positionUnavailable,
}

class PostLocationResult {
  const PostLocationResult._({this.position, this.failure});

  const PostLocationResult.success(Position position)
    : this._(position: position);

  const PostLocationResult.failure(PostLocationFailure failure)
    : this._(failure: failure);

  final Position? position;
  final PostLocationFailure? failure;

  bool get isSuccess => position != null;
}

class PostLocationRequirement {
  const PostLocationRequirement._();

  static Future<PostLocationResult> ensureCurrentPosition({
    bool openAppSettingsOnDeniedForever = false,
    bool openLocationSettingsOnServicesDisabled = false,
  }) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const PostLocationResult.failure(
        PostLocationFailure.permissionDenied,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      if (openAppSettingsOnDeniedForever) {
        await Geolocator.openAppSettings();
      }
      return const PostLocationResult.failure(
        PostLocationFailure.permissionDeniedForever,
      );
    }

    final bool servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!servicesEnabled) {
      if (openLocationSettingsOnServicesDisabled) {
        await Geolocator.openLocationSettings();
      }
      return const PostLocationResult.failure(
        PostLocationFailure.servicesDisabled,
      );
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return PostLocationResult.success(position);
    } catch (_) {
      return const PostLocationResult.failure(
        PostLocationFailure.positionUnavailable,
      );
    }
  }
}
