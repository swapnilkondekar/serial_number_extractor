import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'serial_number_extractor.dart';
import 'models/serial_number_result.dart';
import 'platform/ocr_factory.dart';
import 'platform/ocr_platform_interface.dart';
import 'pdf/pdf_render_io.dart';

/// Service for performing OCR and extracting serial numbers
class OCRService {
  final OCRPlatformInterface _ocrEngine;
  final SerialNumberExtractor _extractor;

  /// Creates an OCRService instance
  /// 
  /// [customPatterns] - Optional list of regex patterns for serial number extraction.
  /// If null, default patterns will be used.
  /// 
  /// The OCR engine is automatically selected based on the platform:
  /// - Mobile (iOS/Android): Google ML Kit
  /// - Desktop (Windows/macOS/Linux): Tesseract OCR (requires setup)
  OCRService({List<String>? customPatterns})
      : _ocrEngine = OCRFactory.create(),
        _extractor = SerialNumberExtractor(customPatterns: customPatterns);

  /// Performs OCR on an image file and extracts serial number
  /// 
  /// [imagePath] - Path to the image file
  /// Returns [SerialNumberResult] with extracted serial number and metadata
  Future<SerialNumberResult> extractSerialNumberFromImage(String imagePath) async {
    try {
      final ocrResult = await _ocrEngine.recognizeText(imagePath);

      final String rawText = ocrResult.text;
      final List<String> textBlocks = ocrResult.textBlocks;

      final serialNumber = _extractor.extractSerialNumber(rawText);
      final allSerialNumbers = _extractor.extractAllSerialNumbers(rawText);

      return SerialNumberResult(
        serialNumber: serialNumber,
        allSerialNumbers: allSerialNumbers,
        allTextBlocks: textBlocks,
        success: serialNumber != null,
        rawText: rawText,
      );
    } catch (e) {
      debugPrint('Error during OCR: $e');
      return SerialNumberResult(
        serialNumber: null,
        allSerialNumbers: [],
        allTextBlocks: [],
        success: false,
        rawText: '',
      );
    }
  }

  /// Performs OCR on an image from XFile (from image_picker)
  /// 
  /// [imageFile] - XFile from image_picker
  /// Returns [SerialNumberResult] with extracted serial number and metadata
  Future<SerialNumberResult> extractSerialNumberFromXFile(XFile imageFile) async {
    return extractSerialNumberFromImage(imageFile.path);
  }

  /// Performs OCR on an image from File
  /// 
  /// [imageFile] - File object
  /// Returns [SerialNumberResult] with extracted serial number and metadata
  Future<SerialNumberResult> extractSerialNumberFromFile(File imageFile) async {
    return extractSerialNumberFromImage(imageFile.path);
  }

  /// Extracts all potential serial numbers from an image
  /// 
  /// [imagePath] - Path to the image file
  /// Returns list of all found serial numbers
  Future<List<String>> extractAllSerialNumbersFromImage(String imagePath) async {
    try {
      final ocrResult = await _ocrEngine.recognizeText(imagePath);
      return _extractor.extractAllSerialNumbers(ocrResult.text);
    } catch (e) {
      debugPrint('Error during OCR: $e');
      return [];
    }
  }

  /// Performs OCR on a PDF file and extracts all serial numbers
  /// 
  /// [pdfPath] - Path to the PDF file
  /// [pageIndex] - Optional page index (0-based). If null, processes all pages.
  /// Returns [SerialNumberResult] with all extracted serial numbers and metadata.
  /// The [allSerialNumbers] field contains all unique serial numbers found across all pages.
  /// 
  /// Note: PDF support is currently unavailable on Android due to compatibility issues
  /// with the pdf_render package. This method will return an empty result on Android.
  Future<SerialNumberResult> extractSerialNumberFromPdf(
    String pdfPath, {
    int? pageIndex,
  }) async {
    return extractSerialNumberFromPdfPlatform(
      pdfPath,
      _ocrEngine,
      _extractor,
      pageIndex: pageIndex,
    );
  }

  /// Performs OCR on a PDF file from File object and extracts serial number
  /// 
  /// [pdfFile] - File object representing the PDF
  /// [pageIndex] - Optional page index (0-based). If null, processes all pages.
  /// Returns [SerialNumberResult] with extracted serial number and metadata
  Future<SerialNumberResult> extractSerialNumberFromPdfFile(
    File pdfFile, {
    int? pageIndex,
  }) async {
    return extractSerialNumberFromPdf(pdfFile.path, pageIndex: pageIndex);
  }

  /// Extracts all potential serial numbers from a PDF file
  /// 
  /// [pdfPath] - Path to the PDF file
  /// [pageIndex] - Optional page index (0-based). If null, processes all pages.
  /// Returns list of all found serial numbers
  Future<List<String>> extractAllSerialNumbersFromPdf(
    String pdfPath, {
    int? pageIndex,
  }) async {
    try {
      final result = await extractSerialNumberFromPdf(pdfPath, pageIndex: pageIndex);
      return _extractor.extractAllSerialNumbers(result.rawText);
    } catch (e) {
      debugPrint('Error during PDF OCR: $e');
      return [];
    }
  }

  /// Disposes the OCR engine (call this when done using the service)
  Future<void> dispose() async {
    await _ocrEngine.dispose();
  }
}


