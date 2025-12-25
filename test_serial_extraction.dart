import 'lib/src/serial_number_extractor.dart';

void main() {
  // Test OCR text with common errors
  final ocrText = '''
1S12XDSQ@@HEEPGE4YYeP 1S12XDSQ@Q@HOOPGE4YZ42 1S12XDSQ@@HOEPGE5057)9
1S12XDSQ@HOEPGE4YZ44 1S12XDSQ@Q@HOOPGE4YZ47 1S12XDSQ@Q@HOOPGE4YZ48
1S12XDSQ@HOEPGE4YZ4C 1S12XDSQ@@HEOPGE4YZ4D 1S12XDSQQ@HOOPGO4YZ4E
''';

  final extractor = SerialNumberExtractor();

  print('Testing serial number extraction with OCR errors...\n');
  print('OCR Text (with errors):');
  print(ocrText);
  print('\n' + '='*80 + '\n');

  final allSerialNumbers = extractor.extractAllSerialNumbers(ocrText);

  print('Extracted Serial Numbers (${allSerialNumbers.length} found):');
  for (var i = 0; i < allSerialNumbers.length; i++) {
    print('${i + 1}. ${allSerialNumbers[i]}');
  }

  print('\n' + '='*80 + '\n');

  // Expected format: 1S12XDS00H00PG04YY0P
  print('Expected format: 1S12XDS00H00PG04YY0P (20 characters)');
  print('Checking first result: ${allSerialNumbers.isNotEmpty ? allSerialNumbers.first : "NONE"}');
  print('Length: ${allSerialNumbers.isNotEmpty ? allSerialNumbers.first.length : 0}');

  // Test with provided examples
  print('\n' + '='*80 + '\n');
  print('Testing with provided serial number examples:');

  final testSerials = [
    '1S12UDS00U00PG04WDQX',
    '1S12XDS00H00PG04YY0P',
    'PG04YA4M',
  ];

  for (final serial in testSerials) {
    // Simulate OCR errors
    var ocrVersion = serial
        .replaceAll('0', '@')  // Simulate OCR error: 0 -> @
        .replaceAll('O', 'Q'); // Simulate OCR error: O -> Q

    print('\nOriginal: $serial');
    print('OCR read: $ocrVersion');

    final extracted = extractor.extractAllSerialNumbers(ocrVersion);
    print('Extracted: ${extracted.isNotEmpty ? extracted.first : "NONE"}');
    print('Match: ${extracted.isNotEmpty && extracted.first == serial ? "✓" : "✗"}');
  }
}
