import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

import '../models/pdf_extraction_result.dart';

class PdfExtractionService {
  bool looksLikePdfBytes(Uint8List bytes) {
    if (bytes.length < 5) {
      return false;
    }

    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46 &&
        bytes[4] == 0x2D;
  }

  Future<PdfExtractionResult> extractText(Uint8List bytes) async {
    final document = sf_pdf.PdfDocument(inputBytes: bytes);

    try {
      final extractor = sf_pdf.PdfTextExtractor(document);
      return PdfExtractionResult(
        text: extractor.extractText(),
        strategy: PdfExtractionStrategy.digitalText,
        pageCount: document.pages.count,
      );
    } finally {
      document.dispose();
    }
  }
}
