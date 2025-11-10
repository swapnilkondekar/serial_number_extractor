/// Result from OCR operation containing text and metadata
class OCRTextResult {
  /// The extracted text
  final String text;

  /// Text blocks found during OCR (for compatibility with ML Kit structure)
  final List<String> textBlocks;

  OCRTextResult({
    required this.text,
    required this.textBlocks,
  });
}





