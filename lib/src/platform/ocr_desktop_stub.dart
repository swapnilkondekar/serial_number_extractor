import 'ocr_platform_interface.dart';

OCRPlatformInterface createDesktopOCRImpl() {
  throw UnsupportedError(
    'Desktop OCR is not supported on this platform. '
    'Please use ocr_desktop_io.dart',
  );
}





