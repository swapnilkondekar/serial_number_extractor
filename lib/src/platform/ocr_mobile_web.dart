import 'ocr_platform_interface.dart';

/// Web implementation placeholder
/// Note: Google ML Kit doesn't support web, would need alternative OCR
OCRPlatformInterface createMobileOCRImpl() {
  throw UnsupportedError(
    'OCR is not yet supported on web platform. '
    'Please use mobile (iOS/Android) or desktop (Windows/macOS/Linux) platforms.',
  );
}

