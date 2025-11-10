/// Result of OCR operation with extracted serial numbers
class SerialNumberResult {
  /// The extracted serial number (null if not found)
  /// For PDFs with multiple serial numbers, this is the first one found
  final String? serialNumber;

  /// All serial numbers found in the document (empty if none found)
  final List<String> allSerialNumbers;

  /// All text blocks found during OCR
  final List<String> allTextBlocks;

  /// Whether a serial number was successfully extracted
  final bool success;

  /// Confidence score (0.0 to 1.0) if available
  final double? confidence;

  /// Raw OCR text result
  final String rawText;

  SerialNumberResult({
    required this.serialNumber,
    required this.allTextBlocks,
    required this.success,
    this.confidence,
    required this.rawText,
    List<String>? allSerialNumbers,
  }) : allSerialNumbers = allSerialNumbers ?? (serialNumber != null ? [serialNumber] : []);

  @override
  String toString() {
    return 'SerialNumberResult(serialNumber: $serialNumber, success: $success, confidence: $confidence)';
  }
}

