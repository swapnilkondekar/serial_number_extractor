import 'dart:core';

/// Extracts serial numbers from OCR text using configurable patterns
class SerialNumberExtractor {
  /// Default patterns for common serial number formats
  static final List<String> _defaultPatterns = [
    // Dell-style serial numbers (high priority): 1S12XDS00H00PG04YY0P, 1S12UDS00U00PG04WDQX (20 chars)
    // Pattern: digit + letter + digits + letters/digits mixed (allow OCR errors)
    r'([0-9][A-Z@eQoil]{1,3}[0-9]{2}[A-Z@eQoil0-9]{14,18})',
    // Lenovo/HP style: PG04YA4M (8+ chars, starts with letters)
    r'\b([A-Z@eQoil]{2}[0-9@eQoil]{2}[A-Z@eQoil0-9]{4,16})\b',
    // Serial Numbers: SGM089BRZ, SGM08AAVV, V0QSN0, VTV0QSN8
    r'\b([A-Z@eQoil]{2,4}[0-9@eQoil]{2,4}[A-Z@eQoil]{2,6})\b',
    // Alphanumeric: SN-ABC123XYZ, SN123456, Serial Number: ABC123
    r'(?:Serial\s*(?:Number|No|#)?|S[/-]?N|SN)\s*[:-]?\s*([A-Z@eQoil0-9]{6,20})',
    // Simple alphanumeric: ABC123XYZ, 1234567890ABCD
    r'\b([A-Z@eQoil]{2,4}[0-9@eQoil]{4,12}[A-Z@eQoil]{0,4})\b',
    // Numeric with separators: 1234-5678-9012
    r'\b([0-9]{4}[-][0-9]{4}[-][0-9]{4})\b',
    // Comma-separated serial numbers: V0QSN0,VTV0QSN8,VTV0QSN9
    r'\b([A-Z@eQoil0-9]{6,20})(?:[,]\s*[A-Z@eQoil0-9]{6,20})+\b',
    // Space-separated serial numbers: V0QSN0 VTV0QSN8 VTV0QSN9
    r'\b([A-Z@eQoil0-9]{6,20})(?:\s+[A-Z@eQoil0-9]{6,20})+\b',
    // Hexadecimal: ABC123DEF456
    r'\b([A-F@eQoil0-9]{8,16})\b',
    // Generic alphanumeric (backup pattern) - matches 6+ chars
    r'\b([A-Z@eQoil0-9]{6,20})\b',
  ];

  final List<String> _customPatterns;

  /// Creates a SerialNumberExtractor with optional custom patterns
  /// 
  /// [customPatterns] - List of regex patterns to match serial numbers.
  /// If provided, only these patterns will be used. If null, default patterns are used.
  SerialNumberExtractor({List<String>? customPatterns})
      : _customPatterns = customPatterns ?? _defaultPatterns;

  /// Extracts serial number from OCR text
  /// 
  /// [ocrText] - The text extracted from OCR
  /// Returns the first matching serial number, or null if none found
  String? extractSerialNumber(String ocrText) {
    if (ocrText.isEmpty) return null;

    // Try each pattern in order
    for (final pattern in _customPatterns) {
      final regex = RegExp(pattern, caseSensitive: false, multiLine: true);
      final match = regex.firstMatch(ocrText);

      if (match != null) {
        // Return the first capture group (serial number)
        final serialNumber = match.group(1);
        if (serialNumber != null && serialNumber.isNotEmpty) {
          // Clean up common OCR errors
          return _cleanSerialNumber(serialNumber);
        }
      }
    }

    return null;
  }

  /// Extracts all potential serial numbers from OCR text
  ///
  /// [ocrText] - The text extracted from OCR
  /// Returns a list of all matching serial numbers (including duplicates)
  List<String> extractAllSerialNumbers(String ocrText) {
    if (ocrText.isEmpty) return [];

    final List<String> serialNumbers = [];
    final Set<String> processedMatches = {}; // Track what we've already processed

    // First, handle comma-separated serial numbers explicitly
    // Pattern: V0QSN0,VTV0QSN8,VTV0QSN9,VTV0QSND
    final commaSeparatedPattern = r'\b([A-Z@eQo0-9]{6,20}(?:[,]\s*[A-Z@eQo0-9]{6,20})+)\b';
    final commaRegex = RegExp(commaSeparatedPattern, caseSensitive: false, multiLine: true);
    final commaMatches = commaRegex.allMatches(ocrText);

    for (final match in commaMatches) {
      final fullMatch = match.group(1);
      if (fullMatch != null && !processedMatches.contains(fullMatch)) {
        processedMatches.add(fullMatch);
        // Split by comma and extract each serial number
        final parts = fullMatch.split(RegExp(r'[,]\s*'));
        for (final part in parts) {
          final cleaned = _cleanSerialNumber(part.trim());
          if (cleaned.length >= 6 && !_isFalsePositive(cleaned)) {
            serialNumbers.add(cleaned); // Keep duplicates
          }
        }
      }
    }

    // Handle space-separated serial numbers
    // Pattern: V0QSN0 VTV0QSN8 VTV0QSN9
    final spaceSeparatedPattern = r'\b([A-Z@eQo0-9]{6,20}(?:\s+[A-Z@eQo0-9]{6,20})+)\b';
    final spaceRegex = RegExp(spaceSeparatedPattern, caseSensitive: false, multiLine: true);
    final spaceMatches = spaceRegex.allMatches(ocrText);

    for (final match in spaceMatches) {
      final fullMatch = match.group(1);
      if (fullMatch != null && !processedMatches.contains(fullMatch)) {
        processedMatches.add(fullMatch);
        // Split by whitespace and extract each serial number
        final parts = fullMatch.split(RegExp(r'\s+'));
        for (final part in parts) {
          final cleaned = _cleanSerialNumber(part.trim());
          if (cleaned.length >= 6 && !_isFalsePositive(cleaned)) {
            serialNumbers.add(cleaned); // Keep duplicates
          }
        }
      }
    }

    // Then, use all other patterns
    for (final pattern in _customPatterns) {
      // Skip the comma-separated and space-separated patterns as we already handled them
      if (pattern.contains('[,]') || pattern.contains(r'\s+')) continue;

      final regex = RegExp(pattern, caseSensitive: false, multiLine: true);
      final matches = regex.allMatches(ocrText);

      for (final match in matches) {
        final serialNumber = match.group(1);
        if (serialNumber != null && serialNumber.isNotEmpty) {
          final cleaned = _cleanSerialNumber(serialNumber);
          // Filter out very short matches and common false positives
          if (cleaned.length >= 6 && !_isFalsePositive(cleaned)) {
            serialNumbers.add(cleaned); // Keep duplicates
          }
        }
      }
    }

    // Return all serial numbers (including duplicates), sorted for consistency
    return serialNumbers..sort();
  }

  /// Checks if a potential serial number is likely a false positive
  bool _isFalsePositive(String value) {
    // Filter out common false positives like dates, prices, etc.
    final falsePositives = [
      r'^\d{4}-\d{2}-\d{2}$', // Dates: 2025-01-15
      r'^\d+\.\d+$', // Decimal numbers: 123.45
      r'^[A-Z]{1,2}\d{1,3}$', // Too short: A1, AB12
    ];
    
    for (final pattern in falsePositives) {
      if (RegExp(pattern).hasMatch(value)) {
        return true;
      }
    }
    
    return false;
  }

  /// Cleans serial number by removing common OCR errors
  String _cleanSerialNumber(String serialNumber) {
    // Remove leading/trailing whitespace
    var cleaned = serialNumber.trim();

    // Replace common OCR mistakes where characters are misread as similar-looking characters
    // These corrections are based on common serial number formats where certain characters
    // are more likely to be numbers than letters

    // Fix common OCR errors specific to serial numbers:
    // @ is commonly misread instead of 0 (zero)
    cleaned = cleaned.replaceAll('@', '0');

    // lowercase 'e' or 'o' are often misread instead of 0 (zero)
    cleaned = cleaned.replaceAll('e', '0');
    cleaned = cleaned.replaceAll('o', '0');

    // Uppercase 'O' (letter O) is often misread instead of 0 (zero) in serial numbers
    // Since most serial numbers use digits, we convert O to 0
    cleaned = cleaned.replaceAll('O', '0');

    // 'Q' is sometimes misread instead of 0 (zero)
    cleaned = cleaned.replaceAll('Q', '0');

    // lowercase 'l' (L) or 'i' are often misread instead of 1 (one)
    cleaned = cleaned.replaceAll('l', '1');
    cleaned = cleaned.replaceAll('i', '1');

    // Uppercase 'I' (letter I) is often misread instead of 1 (one)
    cleaned = cleaned.replaceAll('I', '1');

    // Convert to uppercase for consistency
    cleaned = cleaned.toUpperCase();

    // Remove invalid characters that might be OCR errors (keep only alphanumeric and dash)
    cleaned = cleaned.replaceAll(RegExp(r'[^A-Z0-9\-]'), '');

    return cleaned;
  }
}

