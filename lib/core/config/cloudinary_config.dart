// lib/core/config/cloudinary_config.dart

class CloudinaryConfig {
  // ✅ Replace with YOUR values from Cloudinary Dashboard
  static const String cloudName = 'dljqnuaep'; // e.g., 'dxxxxxxxxx'
  static const String uploadPreset = 'eduvox_uploads'; // e.g., 'eduvox_uploads'

  // Optional: Base folder for all uploads
  static const String baseFolder = 'eduvox';

  static void printConfig() {
    print('═══════════════════════════════════════════');
    print('☁️ CLOUDINARY CONFIG');
    print('═══════════════════════════════════════════');
    print('Cloud Name: $cloudName');
    print('Upload Preset: $uploadPreset');
    print('Base Folder: $baseFolder');
    print('═══════════════════════════════════════════');
  }
}
