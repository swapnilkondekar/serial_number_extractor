# Serial Number OCR

A Flutter package for performing OCR (Optical Character Recognition) operations and extracting serial numbers from images and PDFs with cross-platform support.

## Features

- 📸 **Image Processing**: Extract text from images using platform-optimized OCR engines
- 📄 **PDF Support**: Extract serial numbers from PDF files (all pages or specific pages)
- 🔍 **Serial Number Detection**: Automatically detect and extract serial numbers using configurable regex patterns
- 🎯 **Flexible Patterns**: Use default patterns or provide custom regex patterns for specific serial number formats
- 🌐 **Cross-platform**: Works on iOS, Android, Windows, macOS, and Linux
  - **Mobile (iOS/Android)**: Uses Google ML Kit for OCR
  - **Desktop (Windows/macOS/Linux)**: Uses Tesseract OCR (requires setup)
- 🚀 **Easy to Use**: Simple API for quick integration
- 📦 **Multiple Serial Numbers**: Extract all serial numbers from documents, not just the first one

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  serial_number_ocr:
    git:
      url: https://github.com/swapnilkondekar/serial_number_ocr.git
```

Or if published to pub.dev:

```yaml
dependencies:
  serial_number_ocr: ^0.1.0
```

### Platform Setup

#### Mobile Platforms (iOS/Android)

**Android:**

Add the following to your `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

**iOS:**

Add the following to your `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

Also, add camera permission to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to take photos for OCR</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to select images for OCR</string>
```

#### Desktop Platforms (Windows/macOS/Linux)

**Note:** Desktop OCR requires Tesseract to be installed on your system. The package will automatically detect and use Tesseract once installed.

##### Windows Installation

**Option 1: Using Chocolatey (Recommended)**
```powershell
choco install tesseract
```

**Option 2: Manual Installation**
1. Download the installer from: https://github.com/UB-Mannheim/tesseract/wiki
2. Run the installer (e.g., `tesseract-ocr-w64-setup-5.x.x.exe`)
3. **Important**: During installation, check the option to "Add to PATH" or manually add Tesseract to your system PATH:
   - Default installation path: `C:\Program Files\Tesseract-OCR`
   - Add `C:\Program Files\Tesseract-OCR` to your system PATH environment variable
4. Restart your terminal/IDE after installation

**Verify Installation:**
```powershell
tesseract --version
```

##### macOS Installation

```bash
brew install tesseract
```

**Verify Installation:**
```bash
tesseract --version
```

##### Linux Installation

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install tesseract-ocr
```

**Fedora/RHEL:**
```bash
sudo dnf install tesseract
```

**Arch Linux:**
```bash
sudo pacman -S tesseract
```

**Verify Installation:**
```bash
tesseract --version
```

The package will automatically detect Tesseract in common installation locations. If Tesseract is not found, check the console logs for debug messages indicating which paths were checked.

## Usage

### Basic Usage

```dart
import 'package:serial_number_ocr/serial_number_ocr.dart';
import 'package:image_picker/image_picker.dart';

// Create OCR service instance
final ocrService = OCRService();

// Pick an image
final picker = ImagePicker();
final image = await picker.pickImage(source: ImageSource.camera);

if (image != null) {
  // Extract serial number
  final result = await ocrService.extractSerialNumberFromXFile(image);
  
  if (result.success) {
    print('Serial number: ${result.serialNumber}');
  } else {
    print('No serial number found');
  }
}

// Don't forget to dispose
await ocrService.dispose();
```

### Using Custom Patterns

If your serial numbers follow a specific format, you can provide custom regex patterns:

```dart
// Custom pattern example: SN-XXXX-YYYY format
final customPatterns = [
  r'S[N|NUMBER]\s*[-]\s*([A-Z0-9]{4})\s*[-]\s*([A-Z0-9]{4})',
  r'Serial:\s*([A-Z0-9]{8,12})',
];

final ocrService = OCRService(customPatterns: customPatterns);
```

### Extract All Serial Numbers

To find all potential serial numbers in an image:

```dart
final allSerialNumbers = await ocrService.extractAllSerialNumbersFromImage(imagePath);
print('Found ${allSerialNumbers.length} serial numbers');
for (final serial in allSerialNumbers) {
  print('Serial: $serial');
}
```

### Using File Objects

```dart
import 'dart:io';

final imageFile = File('/path/to/image.jpg');
final result = await ocrService.extractSerialNumberFromFile(imageFile);
```

### PDF Processing

Extract serial numbers from PDF files:

```dart
import 'dart:io';

final pdfFile = File('/path/to/document.pdf');

// Extract from entire PDF (all pages)
final result = await ocrService.extractSerialNumberFromPdfFile(pdfFile);

if (result.success) {
  print('Found ${result.allSerialNumbers.length} serial numbers:');
  for (final serial in result.allSerialNumbers) {
    print('  - $serial');
  }
}

// Extract from specific page (0-based index)
final pageResult = await ocrService.extractSerialNumberFromPdfFile(
  pdfFile,
  pageIndex: 0, // First page only
);
```

## Default Serial Number Patterns

The package includes default patterns that match common serial number formats:

- `SN-ABC123XYZ` or `SN123456` - Serial number prefixes
- `ABC123XYZ` - Alphanumeric codes
- `1234-5678-9012` - Numeric with separators
- `ABC123DEF456` - Hexadecimal codes
- Generic alphanumeric patterns (8-20 characters)

## API Reference

### `OCRService`

Main service class for OCR operations.

#### Methods

- `extractSerialNumberFromImage(String imagePath)` - Extract serial number from image file path
- `extractSerialNumberFromXFile(XFile imageFile)` - Extract serial number from XFile (image_picker)
- `extractSerialNumberFromFile(File imageFile)` - Extract serial number from File object
- `extractAllSerialNumbersFromImage(String imagePath)` - Extract all serial numbers from image
- `dispose()` - Clean up resources (always call when done)

### `SerialNumberResult`

Result object containing OCR results.

#### Properties

- `serialNumber` (String?) - The extracted serial number
- `success` (bool) - Whether a serial number was found
- `allTextBlocks` (List<String>) - All text blocks detected by OCR
- `rawText` (String) - Complete raw OCR text
- `confidence` (double?) - Confidence score if available

### `SerialNumberExtractor`

Low-level class for extracting serial numbers from text.

#### Methods

- `extractSerialNumber(String ocrText)` - Extract first matching serial number
- `extractAllSerialNumbers(String ocrText)` - Extract all matching serial numbers

## Example App

See the `example/` directory for a complete example application demonstrating:
- Image selection from gallery
- Camera capture
- OCR processing
- Result display

Run the example:

```bash
cd example
flutter run
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Google ML Kit for text recognition capabilities
- Flutter team for the amazing framework


