import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import '../models/serial_number_result.dart';
import '../platform/ocr_platform_interface.dart';
import '../serial_number_extractor.dart';

/// PDF rendering implementation for Windows using pdfx
/// 
/// pdfx supports Windows, macOS, Linux, and web platforms
Future<SerialNumberResult> extractSerialNumberFromPdfWindows(
  String pdfPath,
  OCRPlatformInterface ocrEngine,
  SerialNumberExtractor extractor, {
  int? pageIndex,
}) async {
  PdfDocument? document;
  try {
    debugPrint('Opening PDF file with pdfx: $pdfPath');
    document = await PdfDocument.openFile(pdfPath);
    final pageCount = document.pagesCount;
    debugPrint('PDF opened successfully. Page count: $pageCount');
    
    if (pageCount == 0) {
      await document.close();
      return SerialNumberResult(
        serialNumber: null,
        allSerialNumbers: [],
        allTextBlocks: [],
        success: false,
        rawText: '',
      );
    }

    final pagesToProcess = pageIndex != null
        ? [pageIndex]
        : List.generate(pageCount, (i) => i);

    String combinedRawText = '';
    List<String> combinedTextBlocks = [];
    String? foundSerialNumber;
    final Set<String> allSerialNumbersSet = <String>{};

    // Process each page
    for (final pageNum in pagesToProcess) {
      if (pageNum >= pageCount) continue;

      PdfPage? page;
      try {
        // Get the page from the document (page numbers start from 1)
        page = await document.getPage(pageNum + 1);
        
        // Render page to image
        final tempDir = await getTemporaryDirectory();
        final imagePath = '${tempDir.path}/pdf_page_${pageNum}_${DateTime.now().millisecondsSinceEpoch}.png';
        
        // Render the page to an image with pdfx
        // pdfx's render() returns PdfPageImage with bytes directly
        final pageImage = await page.render(
          width: 2048,
          height: 2048,
          format: PdfPageImageFormat.png,
        );
        
        if (pageImage != null) {
          // PdfPageImage.bytes contains the image data directly
          await File(imagePath).writeAsBytes(pageImage.bytes);
        }

        // Process the rendered image with OCR
        final ocrResult = await ocrEngine.recognizeText(imagePath);
        final serialNumber = extractor.extractSerialNumber(ocrResult.text);
        final allSerialNumbers = extractor.extractAllSerialNumbers(ocrResult.text);
        
        // Clean up temporary image file
        try {
          await File(imagePath).delete();
        } catch (_) {
          // Ignore cleanup errors
        }

        // Combine results
        combinedRawText = '$combinedRawText${ocrResult.text}\n\n';
        combinedTextBlocks.addAll(ocrResult.textBlocks);
        
        // Collect all serial numbers from this page
        allSerialNumbersSet.addAll(allSerialNumbers);
        
        // Use first found serial number
        if (foundSerialNumber == null && serialNumber != null) {
          foundSerialNumber = serialNumber;
        }
      } catch (e) {
        debugPrint('Error processing PDF page ${pageNum + 1}: $e');
        // Continue with next page
      }
    }

    await document.close();

    // Extract all serial numbers from combined text to ensure we catch any cross-page patterns
    final allSerialNumbersFromCombined = extractor.extractAllSerialNumbers(combinedRawText);
    allSerialNumbersSet.addAll(allSerialNumbersFromCombined);

    // Convert to sorted list for consistent output
    final allSerialNumbers = allSerialNumbersSet.toList()..sort();

    return SerialNumberResult(
      serialNumber: foundSerialNumber ?? (allSerialNumbers.isNotEmpty ? allSerialNumbers.first : null),
      allSerialNumbers: allSerialNumbers,
      allTextBlocks: combinedTextBlocks,
      success: allSerialNumbers.isNotEmpty,
      rawText: combinedRawText.trim(),
    );
  } catch (e, stackTrace) {
    debugPrint('Error during PDF OCR on Windows: $e');
    debugPrint('Stack trace: $stackTrace');
    // Re-throw with a more descriptive error message
    throw Exception(
      'Failed to process PDF on Windows using pdfx package. Error: $e. '
      'Please ensure pdfx package is properly installed (run flutter pub get).',
    );
  }
}

