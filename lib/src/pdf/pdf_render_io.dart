import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/serial_number_result.dart';
import '../platform/ocr_platform_interface.dart';
import '../serial_number_extractor.dart';
import 'pdf_render_impl.dart'
    if (dart.library.html) 'pdf_render_stub.dart';
import 'pdf_render_windows.dart';

/// Platform-specific PDF rendering
/// 
/// On Android, pdf_render has compatibility issues, so we use a stub
/// On Windows, we use pdfx which supports Windows
/// On other platforms (macOS, Linux, iOS), we use pdf_render
Future<SerialNumberResult> extractSerialNumberFromPdfPlatform(
  String pdfPath,
  OCRPlatformInterface ocrEngine,
  SerialNumberExtractor extractor, {
  int? pageIndex,
}) async {
  // On Android, pdf_render has build issues, so we disable PDF support
  if (Platform.isAndroid) {
    debugPrint(
      'PDF support is currently unavailable on Android due to compatibility issues with pdf_render package. '
      'Please use image files instead, or see TROUBLESHOOTING.md for workarounds.',
    );
    return SerialNumberResult(
      serialNumber: null,
      allSerialNumbers: [],
      allTextBlocks: [],
      success: false,
      rawText: '',
    );
  }

  // On Windows, use pdfx which supports Windows
  if (Platform.isWindows) {
    return extractSerialNumberFromPdfWindows(
      pdfPath,
      ocrEngine,
      extractor,
      pageIndex: pageIndex,
    );
  }

  // Use pdf_render on other platforms (macOS, Linux, iOS)
  return extractSerialNumberFromPdfImpl(
    pdfPath,
    ocrEngine,
    extractor,
    pageIndex: pageIndex,
  );
}

