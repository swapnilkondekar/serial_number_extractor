# Troubleshooting

## Android Build Error with pdf_render

### Issue
When building for Android, you may encounter the following error:

```
Unresolved reference 'Registrar'
Execution failed for task ':pdf_render:compileDebugKotlin'
```

This is a known compatibility issue with `pdf_render` version 1.4.12 and newer Flutter versions that have removed the v1 embedding.

### Solutions

#### Option 1: Use GitHub Version (if available)
If there's a fix available on GitHub, you can use a dependency override in your `pubspec.yaml`:

```yaml
dependency_overrides:
  pdf_render:
    git:
      url: https://github.com/espresso3389/flutter_pdf_render.git
      ref: main  # or specific commit/branch with the fix
```

#### Option 2: Patch the Plugin (Temporary)
You can manually patch the plugin in your pub cache:
1. Navigate to `~/.pub-cache/hosted/pub.dev/pdf_render-1.4.12/android/src/main/kotlin/jp/espresso3389/pdf_render/`
2. Open `PdfRenderPlugin.kt`
3. Remove or comment out lines that reference `Registrar` (around line 21)

#### Option 3: Disable PDF Support on Android (Temporary)
If you only need image OCR support, you can conditionally disable PDF features on Android:

```dart
import 'dart:io' show Platform;

Future<SerialNumberResult> extractFromFile(File file) async {
  if (Platform.isAndroid && file.path.endsWith('.pdf')) {
    throw UnsupportedError('PDF support on Android is temporarily unavailable due to a compatibility issue. Please use images instead.');
  }
  // ... rest of your code
}
```

### Reporting the Issue
Please report this issue to the `pdf_render` package maintainer:
- GitHub: https://github.com/espresso3389/flutter_pdf_render/issues
- Pub.dev: https://pub.dev/packages/pdf_render

### Alternative Packages
If the issue persists, consider using alternative PDF rendering packages:
- `pdfx` - Alternative PDF viewer package
- `syncfusion_flutter_pdfviewer` - Commercial PDF viewer (with free community license)

Note: Using alternative packages may require code changes in the OCR service implementation.

## Windows PDF Support

### Issue
On Windows, you may encounter the following error when trying to process PDF files:

```
MissingPluginException(No implementation found for method file on channel pdf_render)
```

This occurs because the `pdf_render` package does not support Windows.

### Solution
As of version 0.2.0, Windows PDF support has been implemented using the `pdfx` package, which provides native Windows support through PDFium. The package automatically detects Windows and uses `pdfx` instead of `pdf_render` for PDF processing.

**No action required** - Windows PDF support is now enabled by default. Simply ensure you have the latest version of the package installed.

### Technical Details
- Windows uses `pdfx` package (supports Windows, macOS, Linux, web)
- macOS, Linux, and iOS continue to use `pdf_render` package
- Android PDF support remains unavailable due to compatibility issues

