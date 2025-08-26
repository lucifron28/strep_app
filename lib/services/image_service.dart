import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/debug_logger.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<bool> requestPhotoPermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.photos.status;
      
      if (status.isDenied) {
        status = await Permission.photos.request();
      }
      
      // If photos permission is denied, try storage permission as fallback
      if (status.isDenied) {
        var storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          storageStatus = await Permission.storage.request();
        }
        return storageStatus.isGranted;
      }
      
      return status.isGranted;
    }
    
    return true; // iOS handles permissions automatically
  }

  Future<String?> pickImageForThumbnail(String songPath) async {
    try {
      // Request permission first
      final hasPermission = await requestPhotoPermission();
      if (!hasPermission) {
        DebugLogger.log('Photo permission not granted');
        return null;
      }

      // Pick image from gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );
      
      if (image == null) {
        DebugLogger.log('No image selected');
        return null;
      }
      
      // Get app documents directory to store thumbnails
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory thumbnailDir = Directory('${appDocDir.path}/thumbnails');
      
      // Create thumbnails directory if it doesn't exist
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
        DebugLogger.log('Created thumbnails directory: ${thumbnailDir.path}');
      }
      
      // Generate unique filename based on song path hash
      final String filename = 'thumb_${songPath.hashCode.abs()}.jpg';
      final String thumbnailPath = '${thumbnailDir.path}/$filename';
      
      // Copy selected image to thumbnails directory
      final File sourceFile = File(image.path);
      await sourceFile.copy(thumbnailPath);
      
      DebugLogger.log('Thumbnail saved to: $thumbnailPath');
      return thumbnailPath;
      
    } catch (e) {
      DebugLogger.log('Error picking image for thumbnail: $e');
      return null;
    }
  }

  Future<void> deleteThumbnail(String thumbnailPath) async {
    try {
      final file = File(thumbnailPath);
      if (await file.exists()) {
        await file.delete();
        DebugLogger.log('Deleted thumbnail: $thumbnailPath');
      }
    } catch (e) {
      DebugLogger.log('Error deleting thumbnail: $e');
    }
  }
}
