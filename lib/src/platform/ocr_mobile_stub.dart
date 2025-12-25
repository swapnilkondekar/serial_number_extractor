import 'ocr_platform_interface.dart';

OCRPlatformInterface createMobileOCRImpl() {
  throw UnsupportedError(
    'Mobile OCR is not supported on this platform. '
    'Please use ocr_mobile_io.dart or ocr_mobile_web.dart',
  );
}









