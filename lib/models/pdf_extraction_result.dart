enum PdfExtractionStrategy { digitalText, ocrFallback }

extension PdfExtractionStrategyX on PdfExtractionStrategy {
  String get label {
    switch (this) {
      case PdfExtractionStrategy.digitalText:
        return 'Embedded PDF Text';
      case PdfExtractionStrategy.ocrFallback:
        return 'OCR Fallback';
    }
  }
}

class PdfExtractionResult {
  const PdfExtractionResult({
    required this.text,
    required this.strategy,
    required this.pageCount,
  });

  final String text;
  final PdfExtractionStrategy strategy;
  final int pageCount;
}
