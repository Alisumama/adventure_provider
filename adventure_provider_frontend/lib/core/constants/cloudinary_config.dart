/// Cloudinary upload configuration for client-side image uploads.
///
/// Fill these values to enable `ProfileController.updateProfileImage()`.
class CloudinaryConfig {
  CloudinaryConfig._();

  /// Example: `demo` for `https://api.cloudinary.com/v1_1/demo/image/upload`
  static const String cloudName = '';

  /// Unsigned upload preset name created in Cloudinary.
  static const String uploadPreset = '';

  static bool get isConfigured =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}

