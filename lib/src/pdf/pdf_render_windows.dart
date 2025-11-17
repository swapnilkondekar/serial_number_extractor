import 'dart:io';
import 'dart:ui' as ui;
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
    document = await PdfDocument.openFile(pdfPath);
    final pageCount = document.pagesCount;
    
    if (pageCount == 0) {
      await document.dispose();
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

      PdfController? pageController;
      try {
        // Create a controller for this specific page
        pageController = PdfController(
          document: document,
          initialPage: pageNum + 1,
        );
        
        // Render page to image
        final tempDir = await getTemporaryDirectory();
        final imagePath = '${tempDir.path}/pdf_page_${pageNum}_${DateTime.now().millisecondsSinceEpoch}.png';
        
        // Render the page to an image with pdfx
        // pdfx's PdfController.render() returns a ui.Image directly
        final pageImage = await pageController.render(
          width: 2048,
          height: 2048,
        );
        
        if (pageImage != null) {
          // Convert Image to PNG bytes
          final ByteData? byteData = await pageImage.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final bytes = byteData.buffer.asUint8List();
            await File(imagePath).writeAsBytes(bytes);
          }
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
        
        // Dispose page controller
        await pageController.dispose();

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
        // Dispose controller if it was created
        try {
          await pageController?.dispose();
        } catch (_) {
          // Ignore disposal errors
        }
        // Continue with next page
      }
    }

    await document.dispose();

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
  } catch (e) {
    debugPrint('Error during PDF OCR: $e');
    return SerialNumberResult(
      serialNumber: null,
      allSerialNumbers: [],
      allTextBlocks: [],
      success: false,
      rawText: '',
    );
  }
}

