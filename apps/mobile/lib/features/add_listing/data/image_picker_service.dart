import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// A single picked file — just the platform-independent path `image_picker` already hands
/// back (works on mobile and web alike). Kept as a tiny value type of our own rather than
/// exposing `XFile` past this file, so [WizardImageEntry] and the step-3 widget don't carry
/// an `image_picker` import.
class PickedImage {
  const PickedImage({required this.path, required this.name});

  final String path;
  final String name;
}

/// Wraps `image_picker` behind an interface so widget tests can fake picking without a real
/// platform channel (`ImagePicker` throws `MissingPluginException` under plain `flutter
/// test`). Brief P9 item 4: "client-side compression to ≤1600px / ~1MB before upload" —
/// `image_picker`'s own `maxWidth`/`imageQuality` params do this resize+recompress for us,
/// so no extra image-processing package (not in brief §7's list) is needed.
abstract class ImagePickerService {
  Future<List<PickedImage>> pickFromGallery({required int remainingSlots});
  Future<PickedImage?> pickFromCamera();
}

class DeviceImagePickerService implements ImagePickerService {
  final _picker = ImagePicker();

  static const _maxDimension = 1600.0;
  static const _quality = 85;

  @override
  Future<List<PickedImage>> pickFromGallery({
    required int remainingSlots,
  }) async {
    final files = await _picker.pickMultiImage(
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _quality,
      limit: remainingSlots,
    );
    return files.map((f) => PickedImage(path: f.path, name: f.name)).toList();
  }

  @override
  Future<PickedImage?> pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _quality,
    );
    if (file == null) return null;
    return PickedImage(path: file.path, name: file.name);
  }
}

final imagePickerServiceProvider = Provider<ImagePickerService>(
  (ref) => DeviceImagePickerService(),
);
