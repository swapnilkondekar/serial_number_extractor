import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ocr_platform_interface.dart';
import '../models/ocr_text_result.dart';

/// Desktop OCR implementation using Tesseract OCR via CLI
/// 
/// This implementation requires Tesseract to be installed on the system.
/// Installation:
/// - macOS: brew install tesseract
/// - Linux: sudo apt-get install tesseract-ocr
/// - Windows: Download from https://github.com/UB-Mannheim/tesseract/wiki
class DesktopOCR implements OCRPlatformInterface {
  static bool _isInitialized = false;
  static bool? _tesseractAvailable;

  DesktopOCR() {
    if (!_isInitialized) {
      _isInitialized = true;
      // Check tesseract installation asynchronously
      _checkTesseractInstallation();
    }
  }

  String? _tesseractPath;

  /// Resolves symlinks to find the actual tesseract binary
  Future<String?> _resolveTesseractPath(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return null;
      }
      
      // Check if it's a symlink
      final stat = await file.stat();
      if (stat.type == FileSystemEntityType.link) {
        // Try to resolve the symlink
        final linkTarget = await file.resolveSymbolicLinks();
        debugPrint('Desktop OCR: Resolved symlink $path -> $linkTarget');
        return linkTarget;
      }
      
      return path;
    } catch (e) {
      debugPrint('Desktop OCR: Error resolving path $path: $e');
      return null;
    }
  }

  Future<bool> _checkTesseractInstallation() async {
    if (_tesseractAvailable != null) {
      return _tesseractAvailable!;
    }

    // Try to find tesseract in common locations
    // Note: For sandboxed apps, we try both symlinks and actual paths
    List<String> possiblePaths = [
      'tesseract', // Try PATH first
    ];

    if (Platform.isWindows) {
      // Windows common installation paths
      final programFiles = Platform.environment['ProgramFiles'] ?? 'C:\\Program Files';
      final programFilesX86 = Platform.environment['ProgramFiles(x86)'] ?? 'C:\\Program Files (x86)';
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? 'C:\\Users\\${Platform.environment['USERNAME']}\\AppData\\Local';
      
      possiblePaths.addAll([
        '$programFiles\\Tesseract-OCR\\tesseract.exe',
        '$programFilesX86\\Tesseract-OCR\\tesseract.exe',
        '$localAppData\\Programs\\Tesseract-OCR\\tesseract.exe',
        'C:\\Program Files\\Tesseract-OCR\\tesseract.exe',
        'C:\\Program Files (x86)\\Tesseract-OCR\\tesseract.exe',
      ]);
    } else if (Platform.isMacOS) {
      // macOS paths
      possiblePaths.addAll([
        '/usr/local/bin/tesseract', // Homebrew default on macOS (symlink)
        '/usr/local/Cellar/tesseract/5.5.1/bin/tesseract', // Actual Homebrew path
        '/opt/homebrew/bin/tesseract', // Homebrew on Apple Silicon
        '/usr/bin/tesseract', // System default
      ]);
    } else if (Platform.isLinux) {
      // Linux paths
      possiblePaths.addAll([
        '/usr/bin/tesseract',
        '/usr/local/bin/tesseract',
        '/opt/tesseract/bin/tesseract',
      ]);
    }

    for (final path in possiblePaths) {
      try {
        String? actualPath = path;
        
        // For absolute paths, resolve symlinks and check existence
        if ((path.startsWith('/') || path.contains(':\\')) && !path.contains('*')) {
          // On Windows, skip symlink resolution (not commonly used)
          if (Platform.isWindows) {
            final file = File(path);
            if (!await file.exists()) {
              debugPrint('Desktop OCR: Path does not exist: $path');
              continue;
            }
            actualPath = path;
            debugPrint('Desktop OCR: Checking $actualPath');
          } else {
            // On Unix-like systems, resolve symlinks
            actualPath = await _resolveTesseractPath(path);
            if (actualPath == null) {
              debugPrint('Desktop OCR: Path does not exist or cannot be resolved: $path');
              continue;
            }
            
            final file = File(actualPath);
            if (!await file.exists()) {
              debugPrint('Desktop OCR: Resolved path does not exist: $actualPath');
              continue;
            }
            
            debugPrint('Desktop OCR: Checking $actualPath');
          }
        }

        // Try to execute tesseract
        final result = await Process.run(
          actualPath!,
          ['--version'],
          runInShell: false, // Don't use shell to avoid PATH issues
          environment: {
            'PATH': '/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:${Platform.environment['PATH'] ?? ''}',
          },
        );
        
        debugPrint('Desktop OCR: Tried $actualPath, exit code: ${result.exitCode}');
        if (result.exitCode == 0) {
          _tesseractPath = actualPath;
          _tesseractAvailable = true;
          debugPrint('Desktop OCR initialized. Tesseract found at: $actualPath');
          final versionLine = result.stdout.toString().split('\n').first;
          debugPrint('Tesseract version: $versionLine');
          return true;
        } else {
          debugPrint('Desktop OCR: Tesseract at $actualPath returned error: ${result.stderr}');
        }
      } catch (e, stackTrace) {
        debugPrint('Desktop OCR: Error trying $path: $e');
        if (e.toString().contains('Permission denied') || 
            e.toString().contains('Operation not permitted')) {
          debugPrint('Desktop OCR: Permission denied - macOS sandbox may be blocking execution.');
          debugPrint('Desktop OCR: Try running the app without sandbox or add entitlements.');
        }
        debugPrint('Stack trace: $stackTrace');
        // Try next path
        continue;
      }
    }

    // If we get here, tesseract wasn't found
    _tesseractAvailable = false;
    debugPrint('Desktop OCR: Tesseract not found in any common location.');
    debugPrint('Please install tesseract:');
    debugPrint('  macOS: brew install tesseract');
    debugPrint('  Linux: sudo apt-get install tesseract-ocr');
    debugPrint('  Windows: Download from https://github.com/UB-Mannheim/tesseract/wiki');
    return false;
  }

  @override
  Future<OCRTextResult> recognizeText(String imagePath) async {
    try {
      if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
        throw UnsupportedError(
          'Desktop OCR is only supported on Windows, macOS, and Linux platforms',
        );
      }

      // Check if tesseract is available
      final isAvailable = await _checkTesseractInstallation();
      if (!isAvailable) {
        debugPrint('Desktop OCR: Tesseract not available. Returning empty result.');
        return OCRTextResult(
          text: '',
          textBlocks: [],
        );
      }

      // Check if image file exists
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('Desktop OCR: Image file not found: $imagePath');
        return OCRTextResult(
          text: '',
          textBlocks: [],
        );
      }

      debugPrint('Desktop OCR: Processing $imagePath');

      // Create a temporary file for output
      final tempDir = Directory.systemTemp;
      final outputFile = File('${tempDir.path}/tesseract_output_${DateTime.now().millisecondsSinceEpoch}');
      final outputPath = outputFile.path;

      // Run tesseract OCR
      // tesseract input.png output -l eng
      final tesseractCmd = _tesseractPath ?? 'tesseract';
      final result = await Process.run(
        tesseractCmd,
        [
          imagePath,
          outputPath,
          '-l', 'eng', // English language
          '--psm', '6', // Assume a single uniform block of text
        ],
        runInShell: true,
        environment: {
          'PATH': '/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:${Platform.environment['PATH'] ?? ''}',
        },
      );

      if (result.exitCode != 0) {
        debugPrint('Desktop OCR: Tesseract error: ${result.stderr}');
        return OCRTextResult(
          text: '',
          textBlocks: [],
        );
      }

      // Read the output file (tesseract adds .txt extension)
      final outputTextFile = File('$outputPath.txt');
      String ocrText = '';
      List<String> textBlocks = [];

      if (await outputTextFile.exists()) {
        ocrText = await outputTextFile.readAsString();
        // Clean up the output file
        try {
          await outputTextFile.delete();
        } catch (e) {
          debugPrint('Desktop OCR: Could not delete temp file: $e');
        }

        // Split text into blocks (by lines, filtering empty ones)
        textBlocks = ocrText
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
      } else {
        debugPrint('Desktop OCR: Output file not found: ${outputTextFile.path}');
      }

      debugPrint('Desktop OCR: Extracted ${textBlocks.length} text blocks, ${ocrText.length} characters');

      return OCRTextResult(
        text: ocrText.trim(),
        textBlocks: textBlocks,
      );
    } catch (e, stackTrace) {
      debugPrint('Error during desktop OCR: $e');
      debugPrint('Stack trace: $stackTrace');
      return OCRTextResult(
        text: '',
        textBlocks: [],
      );
    }
  }

  @override
  Future<void> dispose() async {
    // Cleanup if needed
    _isInitialized = false;
  }
}

OCRPlatformInterface createDesktopOCRImpl() => DesktopOCR();

