import 'dart:typed_data';
import 'dart:ui' as ui;

class PrintDocument {
  String name;
  int pageCount;
  ui.Image? thumbnail;
  Uint8List? fileBytes;

  // Settings per document
  int copies;
  bool isDoubleSided;
  String orientation;
  String colorType;

  PrintDocument({
    required this.name,
    required this.pageCount,
    this.thumbnail,
    this.fileBytes,
    this.copies = 1,
    this.isDoubleSided = false,
    this.orientation = 'Portrait',
    this.colorType = 'B&W',
  });
}
