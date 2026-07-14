import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraService {
  static final ImagePicker _picker = ImagePicker();

  // Take photo with camera
  static Future<String?> takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (photo != null) {
      final bytes = await File(photo.path).readAsBytes();
      return base64Encode(bytes);
    }
    return null;
  }

  // Pick from gallery
  static Future<String?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      return base64Encode(bytes);
    }
    return null;
  }
}
