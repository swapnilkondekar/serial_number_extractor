import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ocr_platform_interface.dart';
import '../models/ocr_text_result.dart';

/// Mobile OCR implementation using Google ML Kit (iOS/Android)
class MobileOCR implements OCRPlatformInterface {
  final TextRecognizer _textRecognizer;

  MobileOCR() : _textRecognizer = TextRecognizer();

  @override
  Future<OCRTextResult> recognizeText(String imagePath) async {
    try {
      if (!Platform.isIOS && !Platform.isAndroid) {
        throw UnsupportedError(
          'Mobile OCR is only supported on iOS and Android platforms',
        );
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final String rawText = recognizedText.text;
      final List<String> textBlocks = recognizedText.blocks
          .map((block) => block.text)
          .toList();

      return OCRTextResult(
        text: rawText,
        textBlocks: textBlocks,
      );
    } catch (e) {
      debugPrint('Error during mobile OCR: $e');
      return OCRTextResult(
        text: '',
        textBlocks: [],
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}

OCRPlatformInterface createMobileOCRImpl() => MobileOCR();







