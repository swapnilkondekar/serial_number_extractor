import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:path_provider/path_provider.dart';
import '../models/serial_number_result.dart';
import '../platform/ocr_platform_interface.dart';
import '../serial_number_extractor.dart';

/// PDF rendering implementation using pdf_render
/// 
/// Note: This has compatibility issues on Android with newer Flutter versions
Future<SerialNumberResult> extractSerialNumberFromPdfImpl(
  String pdfPath,
  OCRPlatformInterface ocrEngine,
  SerialNumberExtractor extractor, {
  int? pageIndex,
}) async {
  try {
    final doc = await PdfDocument.openFile(pdfPath);
    final pageCount = doc.pageCount;
    
    if (pageCount == 0) {
      await doc.dispose();
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
    final List<String> allSerialNumbersList = <String>[];

    // Process each page
    for (final pageNum in pagesToProcess) {
      if (pageNum >= pageCount) continue;

      try {
        final page = await doc.getPage(pageNum + 1);
        
        // Render page to image
        final tempDir = await getTemporaryDirectory();
        final imagePath = '${tempDir.path}/pdf_page_${pageNum}_${DateTime.now().millisecondsSinceEpoch}.png';
        
        final pageImage = await page.render(
          width: 2048,
          height: 2048,
        );
        
        // Create dart:ui.Image from PdfPageImage
        await pageImage.createImageIfNotAvailable();
        final uiImage = pageImage.imageIfAvailable;
        
        if (uiImage != null) {
          // Convert Image to PNG bytes
          final ByteData? byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
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

        // Combine results
        combinedRawText = '$combinedRawText${ocrResult.text}\n\n';
        combinedTextBlocks.addAll(ocrResult.textBlocks);
        
        // Collect all serial numbers from this page (including duplicates)
        allSerialNumbersList.addAll(allSerialNumbers);
        
        // Use first found serial number
        if (foundSerialNumber == null && serialNumber != null) {
          foundSerialNumber = serialNumber;
        }
      } catch (e) {
        debugPrint('Error processing PDF page ${pageNum + 1}: $e');
        // Continue with next page
      }
    }

    await doc.dispose();

    // Extract all serial numbers from combined text to ensure we catch any cross-page patterns
    final allSerialNumbersFromCombined = extractor.extractAllSerialNumbers(combinedRawText);
    allSerialNumbersList.addAll(allSerialNumbersFromCombined);

    // Sort for consistent output (duplicates preserved)
    final allSerialNumbers = allSerialNumbersList..sort();

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

