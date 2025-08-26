import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
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
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        final sdk = info.version.sdkInt;
        DebugLogger.log('Android SDK version: $sdk');
        
        if (sdk >= 33) {
          // Android 13+: Use READ_MEDIA_IMAGES permission
          final status = await Permission.photos.status;
          DebugLogger.log('Photos permission status (API 33+): $status');
          
          if (status.isDenied) {
            final result = await Permission.photos.request();
            DebugLogger.log('Photos permission request result: $result');
            return result.isGranted;
          }
          return status.isGranted;
        } else {
          // Android 12 and below: Use READ_EXTERNAL_STORAGE
          final status = await Permission.storage.status;
          DebugLogger.log('Storage permission status (API <=32): $status');
          
          if (status.isDenied) {
            final result = await Permission.storage.request();
            DebugLogger.log('Storage permission request result: $result');
            return result.isGranted;
          }
          return status.isGranted;
        }
      } catch (e) {
        DebugLogger.log('Error checking Android version or permissions: $e');
        return false;
      }
    }
    
    return true; // iOS handles permissions automatically
  }

  Future<String?> pickImageForThumbnail(String songPath) async {
    try {
      DebugLogger.log('Starting image picker for thumbnail');
      
      // Configure Android Photo Picker for better experience on Android 12 and below
      final impl = ImagePickerPlatform.instance;
      if (impl is ImagePickerAndroid) {
        impl.useAndroidPhotoPicker = true;
        DebugLogger.log('Android Photo Picker enabled');
      }
      
      // On Android 13+, the system Photo Picker handles permissions automatically
      // On older versions, we need to request permission first
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        final sdk = info.version.sdkInt;
        
        if (sdk < 33) {
          // Android 12 and below: Request permission first
          final hasPermission = await requestPhotoPermission();
          if (!hasPermission) {
            DebugLogger.log('Permission denied for Android API $sdk');
            return null;
          }
        }
        // Android 13+: No permission request needed, Photo Picker handles it
      }
      
      // Pick image from gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );
      
      DebugLogger.log('Image picker result: ${image?.path ?? 'null'}');
      
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
