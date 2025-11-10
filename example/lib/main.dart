import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:serial_number_ocr/serial_number_ocr.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serial Number OCR Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const OCRScreen(),
    );
  }
}

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  final OCRService _ocrService = OCRService();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  File? _selectedPdf;
  SerialNumberResult? _result;
  bool _isProcessing = false;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (image != null) {
        final imageFile = File(image.path);
        if (await imageFile.exists()) {
          setState(() {
            _selectedImage = imageFile;
            _selectedPdf = null;
            _result = null;
          });
          await _processImage(_selectedImage!);
        } else {
          _showError('Selected image file does not exist');
        }
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      
      if (image != null) {
        final imageFile = File(image.path);
        if (await imageFile.exists()) {
          setState(() {
            _selectedImage = imageFile;
            _selectedPdf = null;
            _result = null;
          });
          await _processImage(_selectedImage!);
        } else {
          _showError('Captured image file does not exist');
        }
      }
    } catch (e) {
      _showError('Error taking photo: $e');
    }
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false, // We'll use file path on macOS
        withReadStream: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        
        // Handle different platforms - some return path, others return bytes
        File? pdfFile;
        if (pickedFile.path != null && pickedFile.path!.isNotEmpty) {
          pdfFile = File(pickedFile.path!);
        } else if (pickedFile.bytes != null) {
          // For web or platforms without direct file access, save bytes to temp file
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}');
          await tempFile.writeAsBytes(pickedFile.bytes!);
          pdfFile = tempFile;
        }
        
        if (pdfFile != null && await pdfFile.exists()) {
          setState(() {
            _selectedPdf = pdfFile;
            _selectedImage = null;
            _result = null;
          });
          await _processPdf(_selectedPdf!);
        } else {
          _showError('Could not access the selected PDF file. Path: ${pickedFile.path}');
        }
      } else {
        // User cancelled or no file selected - this is normal, don't show error
      }
    } catch (e, stackTrace) {
      debugPrint('File picker error: $e');
      debugPrint('Stack trace: $stackTrace');
      _showError('Error picking PDF: $e');
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _ocrService.extractSerialNumberFromFile(imageFile);
      
      setState(() {
        _result = result;
        _isProcessing = false;
      });

      if (result.success) {
        final count = result.allSerialNumbers.length;
        if (count > 1) {
          _showSuccess('Found $count serial numbers');
        } else {
          _showSuccess('Serial number found: ${result.serialNumber}');
        }
      } else {
        _showWarning('No serial number detected in the image');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Error processing image: $e');
    }
  }

  Future<void> _processPdf(File pdfFile) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _ocrService.extractSerialNumberFromPdfFile(pdfFile);
      
      setState(() {
        _result = result;
        _isProcessing = false;
      });

      if (result.success) {
        final count = result.allSerialNumbers.length;
        if (count > 1) {
          _showSuccess('Found $count serial numbers in PDF');
        } else {
          _showSuccess('Serial number found: ${result.serialNumber}');
        }
      } else {
        _showWarning('No serial number detected in the PDF');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Error processing PDF: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Serial Number OCR'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File picker buttons
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Pick Image'),
                ),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                ),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _pickPdfFile,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Pick PDF'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Selected image
            if (_selectedImage != null)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            
            // Selected PDF
            if (_selectedPdf != null)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected PDF',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedPdf!.path.split('/').last,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Processing indicator
            if (_isProcessing)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    Text(_selectedPdf != null ? 'Processing PDF...' : 'Processing image...'),
                  ],
                ),
              ),
            
            // Results
            if (_result != null && !_isProcessing) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Results',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      _buildResultRow(
                        'Status',
                        _result!.success ? 'Success' : 'No match found',
                        _result!.success ? Colors.green : Colors.orange,
                      ),
                      if (_result!.serialNumber != null)
                        _buildResultRow(
                          'Serial Number',
                          _result!.serialNumber!,
                          Colors.blue,
                        ),
                      if (_result!.allSerialNumbers.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ExpansionTile(
                          title: Text(
                            'All Serial Numbers (${_result!.allSerialNumbers.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          initiallyExpanded: _result!.allSerialNumbers.length > 1,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _result!.allSerialNumbers
                                    .map((sn) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: SelectableText(
                                            '• $sn',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      ExpansionTile(
                        title: const Text('All Text Blocks'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _result!.allTextBlocks.join('\n'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ExpansionTile(
                        title: const Text('Raw OCR Text'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SelectableText(
                              _result!.rawText,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}


