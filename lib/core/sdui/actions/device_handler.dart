import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

/// Handles device capability actions: geolocation, pickFile, camera, health.
class DeviceHandler {
  static Future<Map<String, dynamic>> handle(
    String target,
    Map<String, dynamic>? props,
  ) async {
    switch (target) {
      case 'geolocation':
        return _handleGeolocation();
      case 'pickFile':
        return _handlePickFile(props);
      case 'camera':
        return _handleCamera(props);
      case 'health':
        return _handleHealth(props);
      default:
        return {'error': 'Unknown device target: $target'};
    }
  }

  static Future<Map<String, dynamic>> _handleGeolocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {'error': 'Location services are disabled'};
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {'error': 'Location permission denied'};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {'error': 'Location permission permanently denied'};
      }

      final position = await Geolocator.getCurrentPosition();
      return {
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _handlePickFile(
    Map<String, dynamic>? props,
  ) async {
    try {
      final allowedExtensions = <String>[];
      final accept = props?['accept'] as String?;
      if (accept != null && accept.isNotEmpty) {
        allowedExtensions.addAll(
          accept.split(',').map((e) => e.trim().replaceAll('.', '')),
        );
      }

      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions.isNotEmpty ? FileType.custom : FileType.any,
        allowedExtensions:
            allowedExtensions.isNotEmpty ? allowedExtensions : null,
      );

      if (result == null || result.files.isEmpty) {
        return {'cancelled': true};
      }

      final file = result.files.first;
      return {
        'path': file.path ?? '',
        'name': file.name,
        'size': file.size,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _handleCamera(
    Map<String, dynamic>? props,
  ) async {
    try {
      final picker = ImagePicker();
      final mode = props?['mode'] as String? ?? 'photo';

      XFile? file;
      if (mode == 'video') {
        file = await picker.pickVideo(source: ImageSource.camera);
      } else {
        file = await picker.pickImage(source: ImageSource.camera);
      }

      if (file == null) {
        return {'cancelled': true};
      }

      return {
        'path': file.path,
        'name': file.name,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _handleHealth(
    Map<String, dynamic>? props,
  ) async {
    // Health package requires extensive platform setup; stub for now
    return {
      'status': 'not_implemented',
      'message': 'Health integration requires platform-specific setup',
    };
  }
}
