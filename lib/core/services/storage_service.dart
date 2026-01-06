// lib/core/services/storage_service.dart

import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../config/cloudinary_config.dart';

class StorageService {
  late final CloudinaryPublic _cloudinary;

  StorageService() {
    // Print config for debugging
    CloudinaryConfig.printConfig();

    print('🔧 Initializing Cloudinary...');
    print('   Cloud Name: ${CloudinaryConfig.cloudName}');
    print('   Upload Preset: ${CloudinaryConfig.uploadPreset}');

    _cloudinary = CloudinaryPublic(
      CloudinaryConfig.cloudName,
      CloudinaryConfig.uploadPreset,
      cache: false,
    );

    print('✅ Cloudinary initialized');
  }

  // ✅ Upload video with full debugging
  Future<String?> uploadVideo({
    required File file,
    required String courseId,
    required Function(double) onProgress,
  }) async {
    print('═══════════════════════════════════════════');
    print('📹 UPLOAD VIDEO STARTED');
    print('═══════════════════════════════════════════');

    try {
      // Step 1: Check file
      print('📁 File path: ${file.path}');

      final exists = await file.exists();
      print('📁 File exists: $exists');

      if (!exists) {
        throw Exception('File does not exist at path: ${file.path}');
      }

      final fileSize = await file.length();
      final sizeMB = fileSize / (1024 * 1024);
      print('📁 File size: ${sizeMB.toStringAsFixed(2)} MB');

      if (sizeMB > 100) {
        throw Exception(
          'Video too large. Maximum size is 100MB. Your file is ${sizeMB.toStringAsFixed(2)} MB',
        );
      }

      // Step 2: Prepare upload
      final folder = '${CloudinaryConfig.baseFolder}/courses/$courseId/videos';
      print('📂 Upload folder: $folder');

      onProgress(0.1);
      print('📤 Starting Cloudinary upload...');

      // Step 3: Upload to Cloudinary
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Video,
        ),
      );

      // Step 4: Check response
      print('═══════════════════════════════════════════');
      print('✅ CLOUDINARY UPLOAD RESPONSE');
      print('═══════════════════════════════════════════');
      print('📎 Secure URL: ${response.secureUrl}');
      print('📎 Public ID: ${response.publicId}');
      print('📎 Original Filename: ${response.originalFilename}');
      print('═══════════════════════════════════════════');

      onProgress(1.0);

      return response.secureUrl;
    } catch (e) {
      print('═══════════════════════════════════════════');
      print('❌ CLOUDINARY UPLOAD FAILED');
      print('═══════════════════════════════════════════');
      print('Error: $e');
      print('Error Type: ${e.runtimeType}');
      print('═══════════════════════════════════════════');
      rethrow;
    }
  }

  // ✅ Upload document with full debugging
  Future<String?> uploadDocument({
    required File file,
    required String courseId,
    required Function(double) onProgress,
  }) async {
    print('═══════════════════════════════════════════');
    print('📄 UPLOAD DOCUMENT STARTED');
    print('═══════════════════════════════════════════');

    try {
      print('📁 File path: ${file.path}');

      final exists = await file.exists();
      print('📁 File exists: $exists');

      if (!exists) {
        throw Exception('File does not exist');
      }

      final fileSize = await file.length();
      final sizeMB = fileSize / (1024 * 1024);
      print('📁 File size: ${sizeMB.toStringAsFixed(2)} MB');

      if (sizeMB > 10) {
        throw Exception('Document too large. Maximum is 10MB');
      }

      final folder =
          '${CloudinaryConfig.baseFolder}/courses/$courseId/documents';
      print('📂 Upload folder: $folder');

      onProgress(0.1);
      print('📤 Starting Cloudinary upload...');

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Raw,
        ),
      );

      print('✅ Upload successful!');
      print('📎 URL: ${response.secureUrl}');

      onProgress(1.0);
      return response.secureUrl;
    } catch (e) {
      print('❌ Document upload failed: $e');
      rethrow;
    }
  }

  // ✅ Upload thumbnail
  Future<String?> uploadThumbnail({
    required File file,
    required String courseId,
  }) async {
    print('🖼️ Uploading thumbnail...');

    try {
      if (!await file.exists()) {
        throw Exception('Thumbnail file does not exist');
      }

      final folder =
          '${CloudinaryConfig.baseFolder}/courses/$courseId/thumbnails';
      print('📂 Folder: $folder');

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      print('✅ Thumbnail uploaded: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      print('❌ Thumbnail upload failed: $e');
      rethrow;
    }
  }

  // ✅ Test Cloudinary connection
  Future<bool> testConnection() async {
    print('═══════════════════════════════════════════');
    print('🧪 TESTING CLOUDINARY CONNECTION');
    print('═══════════════════════════════════════════');

    try {
      print('Cloud Name: ${CloudinaryConfig.cloudName}');
      print('Upload Preset: ${CloudinaryConfig.uploadPreset}');

      // Try to upload a small test from URL
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromUrl(
          'https://picsum.photos/100/100',
          folder: '${CloudinaryConfig.baseFolder}/test',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      print('✅ TEST PASSED!');
      print('📎 Test URL: ${response.secureUrl}');
      return true;
    } catch (e) {
      print('❌ TEST FAILED!');
      print('Error: $e');
      return false;
    }
  }

  Future<void> deleteFile(String url) async {
    print('⚠️ Cloudinary deletion requires backend');
  }
}
