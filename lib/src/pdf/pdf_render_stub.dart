import '../models/serial_number_result.dart';

/// Stub implementation for PDF rendering
/// This is used when pdf_render is not available or has compatibility issues
Future<SerialNumberResult> extractSerialNumberFromPdfStub(
  String pdfPath, {
  int? pageIndex,
}) async {
  throw UnsupportedError(
    'PDF support is not available on this platform. '
    'This may be due to compatibility issues with the pdf_render package.',
  );
}

