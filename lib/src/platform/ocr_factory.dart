import 'dart:io';
import 'ocr_platform_interface.dart';
import 'ocr_mobile.dart';
import 'ocr_desktop.dart';

/// Factory to create the appropriate OCR implementation based on platform
class OCRFactory {
  /// Creates an OCR implementation for the current platform
  /// 
  /// Returns:
  /// - Mobile OCR (Google ML Kit) on iOS/Android
  /// - Desktop OCR (Tesseract) on Windows/macOS/Linux
  /// - Throws UnsupportedError on web
  static OCRPlatformInterface create() {
    if (Platform.isIOS || Platform.isAndroid) {
      return createMobileOCR();
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return createDesktopOCR();
    } else {
      throw UnsupportedError(
        'OCR is not supported on this platform. '
        'Supported platforms: iOS, Android, Windows, macOS, Linux',
      );
    }
  }
}









