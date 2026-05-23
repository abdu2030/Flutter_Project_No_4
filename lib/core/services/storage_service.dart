import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../config/cloudinary_config.dart';

class StorageService {
  late final CloudinaryPublic _cloudinary;

  StorageService() {
    // Print config for debugging
    CloudinaryConfig.printConfig();

    _cloudinary = CloudinaryPublic(
      CloudinaryConfig.cloudName,
      CloudinaryConfig.uploadPreset,
      cache: false,
    );
  }

  // ✅ Upload video with full debugging
  Future<String?> uploadVideo({
    required File file,
    required String courseId,
    required Function(double) onProgress,
  }) async {
 
    try {

      final exists = await file.exists();

      if (!exists) {
        throw Exception('File does not exist at path: ${file.path}');
      }

      final fileSize = await file.length();
      final sizeMB = fileSize / (1024 * 1024);
      

      if (sizeMB > 100) {
        throw Exception(
          'Video too large. Maximum size is 100MB. Your file is ${sizeMB.toStringAsFixed(2)} MB',
        );
      }

      // Step 2: Prepare upload
      final folder = '${CloudinaryConfig.baseFolder}/courses/$courseId/videos';
    
      onProgress(0.1);
      
      // Step 3: Upload to Cloudinary
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Video,
        ),
      );

      // // Step 4: Check response
      // print('═══════════════════════════════════════════');
      // print('✅ CLOUDINARY UPLOAD RESPONSE');
      // print('═══════════════════════════════════════════');
      // print('📎 Secure URL: ${response.secureUrl}');
      // print('📎 Public ID: ${response.publicId}');
      // print('📎 Original Filename: ${response.originalFilename}');
      // print('═══════════════════════════════════════════');

      onProgress(1.0);

      return response.secureUrl;
    } catch (e) {
      // print('═══════════════════════════════════════════');
      // print('❌ CLOUDINARY UPLOAD FAILED');
      // print('═══════════════════════════════════════════');
      // print('Error: $e');
      // print('Error Type: ${e.runtimeType}');
      // print('═══════════════════════════════════════════');
      rethrow;
    }
  }

  // ✅ Upload document with full debugging
  Future<String?> uploadDocument({
    required File file,
    required String courseId,
    required Function(double) onProgress,
  }) async {
    try {
      final exists = await file.exists();

      if (!exists) {
        throw Exception('File does not exist');
      }

      final fileSize = await file.length();
      final sizeMB = fileSize / (1024 * 1024);

      if (sizeMB > 10) {
        throw Exception('Document too large. Maximum is 10MB');
      }

      final folder =
          '${CloudinaryConfig.baseFolder}/courses/$courseId/documents';

      onProgress(0.1);

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Raw,
        ),
      );

      onProgress(1.0);
      return response.secureUrl;
    } catch (e) {
      
      rethrow;
    }
  }

  // ✅ Upload thumbnail
  Future<String?> uploadThumbnail({
    required File file,
    required String courseId,
  }) async {
    
    try {
      if (!await file.exists()) {
        throw Exception('Thumbnail file does not exist');
      }

      final folder =
          '${CloudinaryConfig.baseFolder}/courses/$courseId/thumbnails';

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ Test Cloudinary connection
  Future<bool> testConnection() async {

    try {

      // Try to upload a small test from URL
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromUrl(
          'https://picsum.photos/100/100',
          folder: '${CloudinaryConfig.baseFolder}/test',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      print('📎 Test URL: ${response.secureUrl}');
      return true;
    } catch (e) {
     
      return false;
    }
  }

  Future<void> deleteFile(String url) async {
    print('⚠️ Cloudinary deletion requires backend');
  }
}
