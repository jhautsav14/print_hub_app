import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../models/print_document.dart';

class PdfService {
  static Future<PrintDocument?> pickAndProcessDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        Uint8List? fileBytes = file.bytes;

        if (fileBytes == null) return null;

        // Generate Thumbnail (printing package)
        final raster = await Printing.raster(
          fileBytes,
          pages: [0],
          dpi: 72,
        ).first;
        ui.Image thumbnailImage = await raster.toImage();

        // Count Pages (syncfusion package)
        final sfDoc = sf.PdfDocument(inputBytes: fileBytes);
        int realPageCount = sfDoc.pages.count;
        sfDoc.dispose();

        return PrintDocument(
          name: file.name,
          pageCount: realPageCount,
          thumbnail: thumbnailImage,
          fileBytes: fileBytes,
        );
      }
    } catch (e) {
      debugPrint("Error in PdfService: $e");
    }
    return null;
  }
}
