import 'package:file_selector/file_selector.dart';

/// Thin wrapper over the OS-native document picker, restricted to PDF files.
/// Used for script uploads. Backed by `file_selector` (UIDocumentPicker on iOS,
/// Storage Access Framework on Android) — no third-party picker UI.
class DocumentPicker {
  const DocumentPicker();

  static const _pdfTypeGroup = XTypeGroup(
    label: 'PDF',
    extensions: ['pdf'],
    mimeTypes: ['application/pdf'],
    uniformTypeIdentifiers: ['com.adobe.pdf'],
  );

  /// Opens the native picker filtered to PDFs. Returns the selected file, or
  /// `null` if the user cancels.
  Future<XFile?> pickPdf() => openFile(acceptedTypeGroups: [_pdfTypeGroup]);
}
