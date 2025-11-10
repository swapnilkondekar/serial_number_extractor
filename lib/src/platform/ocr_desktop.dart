import 'ocr_platform_interface.dart';
import 'ocr_desktop_stub.dart'
    if (dart.library.io) 'ocr_desktop_io.dart';

/// Factory function to create desktop OCR implementation
OCRPlatformInterface createDesktopOCR() => createDesktopOCRImpl();

