# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-12-XX

### Added
- **Cross-platform support**: Added support for Windows, macOS, and Linux desktop platforms
- **Platform abstraction layer**: Created platform-specific OCR implementations
  - Mobile (iOS/Android): Uses Google ML Kit (existing)
  - Desktop (Windows/macOS/Linux): Uses Tesseract OCR (placeholder implementation)
- **Platform factory**: Automatic platform detection and OCR engine selection
- **Desktop OCR interface**: Foundation for desktop OCR support (Tesseract integration planned)
- **Windows PDF support**: Added Windows PDF processing using `pdfx` package
  - Windows now uses `pdfx` for PDF rendering (supports Windows via PDFium)
  - macOS, Linux, and iOS continue to use `pdf_render` package
  - Automatic platform detection and appropriate PDF library selection

### Changed
- Refactored OCR service to use platform abstraction layer
- Updated documentation to reflect cross-platform support
- Improved code organization with platform-specific modules
- PDF rendering now uses platform-specific implementations:
  - Windows: `pdfx` package
  - macOS/Linux/iOS: `pdf_render` package
  - Android: PDF support disabled (compatibility issues)

### Known Limitations
- Desktop OCR currently returns placeholder/empty results (Tesseract FFI integration pending)
- PDF rendering on Android has compatibility issues with `pdf_render` package (see TROUBLESHOOTING.md)

## [0.1.0] - 2024-12-XX

### Added
- Initial release of serial_number_ocr package
- OCR functionality using Google ML Kit Text Recognition
- Serial number extraction from images using configurable regex patterns
- PDF support for extracting serial numbers from PDF documents
- Support for extracting all serial numbers from multi-page PDFs
- Multiple input methods: File, XFile, and file paths
- `SerialNumberResult` model with comprehensive metadata:
  - Single serial number (first found)
  - List of all serial numbers found
  - All text blocks from OCR
  - Raw OCR text
- Example Flutter app demonstrating usage
- Default regex patterns for common serial number formats
- Custom pattern support for specialized serial number formats

### Features
- Extract serial numbers from images (JPG, PNG, etc.)
- Extract serial numbers from PDF files (all pages or specific pages)
- Automatic deduplication and sorting of serial numbers
- Cross-platform support (iOS and Android)
- Easy-to-use API with comprehensive error handling

