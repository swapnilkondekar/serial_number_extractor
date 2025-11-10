import 'ocr_platform_interface.dart';
import 'ocr_mobile_stub.dart'
    if (dart.library.io) 'ocr_mobile_io.dart'
    if (dart.library.html) 'ocr_mobile_web.dart';

/// Factory function to create mobile OCR implementation
OCRPlatformInterface createMobileOCR() => createMobileOCRImpl();

