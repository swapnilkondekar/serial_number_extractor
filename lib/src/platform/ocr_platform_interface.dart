import '../models/ocr_text_result.dart';

/// Platform-agnostic interface for OCR operations
abstract class OCRPlatformInterface {
  /// Performs OCR on an image file
  /// 
  /// [imagePath] - Path to the image file
  /// Returns [OCRTextResult] with extracted text and metadata
  Future<OCRTextResult> recognizeText(String imagePath);

  /// Disposes any resources used by the OCR engine
  Future<void> dispose();
}









