#!/usr/bin/env dart
/// Test script to verify PDF serial number extraction
///
/// Usage: dart test_pdf_extraction.dart

import 'dart:io';
import 'lib/serial_number_ocr.dart';

void main() async {
  print('=== PDF Serial Number Extraction Test ===\n');

  final ocrService = OCRService();

  // Test PDF files from your directory
  final pdfDirectory = Directory('/Users/swapnil/Downloads/invoices_pdf');

  if (!await pdfDirectory.exists()) {
    print('ERROR: PDF directory not found: ${pdfDirectory.path}');
    exit(1);
  }

  final pdfFiles = pdfDirectory
      .listSync()
      .where((file) => file.path.toLowerCase().endsWith('.pdf'))
      .take(3) // Test first 3 PDFs
      .toList();

  if (pdfFiles.isEmpty) {
    print('ERROR: No PDF files found in ${pdfDirectory.path}');
    exit(1);
  }

  print('Found ${pdfFiles.length} PDF files to test\n');
  print('='*80 + '\n');

  for (var i = 0; i < pdfFiles.length; i++) {
    final pdfFile = File(pdfFiles[i].path);
    final fileName = pdfFile.path.split('/').last;

    print('${i + 1}. Testing: $fileName');
    print('-'*80);

    try {
      final result = await ocrService.extractSerialNumberFromPdfFile(pdfFile);

      if (result.success) {
        print('✓ Success! Found ${result.allSerialNumbers.length} serial numbers\n');

        print('First Serial Number: ${result.serialNumber}');

        if (result.allSerialNumbers.length > 1) {
          print('\nAll Serial Numbers (${result.allSerialNumbers.length} total):');
          for (var j = 0; j < result.allSerialNumbers.length && j < 10; j++) {
            print('  ${j + 1}. ${result.allSerialNumbers[j]}');
          }
          if (result.allSerialNumbers.length > 10) {
            print('  ... and ${result.allSerialNumbers.length - 10} more');
          }
        }

        // Show sample of OCR text
        print('\nOCR Text Sample (first 200 chars):');
        final textSample = result.rawText.replaceAll('\n', ' ').substring(
          0, result.rawText.length > 200 ? 200 : result.rawText.length
        );
        print('  "$textSample..."');
      } else {
        print('✗ No serial numbers found');
        print('\nOCR Text Sample:');
        final textSample = result.rawText.substring(
          0, result.rawText.length > 300 ? 300 : result.rawText.length
        );
        print('  $textSample');
      }
    } catch (e) {
      print('✗ Error processing PDF: $e');
    }

    print('\n' + '='*80 + '\n');
  }

  await ocrService.dispose();
  print('Test complete!');
}
