import 'package:collage_result/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the student result analyzer shell', (tester) async {
    await tester.pumpWidget(const CollegeResultAnalyzerApp());

    expect(find.text('College Result Analyzer'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Student Result Analyzer'), findsOneWidget);
    expect(find.text('Upload PDF'), findsOneWidget);
    expect(find.text('Analysis Snapshot'), findsOneWidget);
    expect(find.text('Subject Analysis'), findsOneWidget);
    expect(find.text('View PDF As'), findsOneWidget);
    expect(find.text('Current Exam (0)'), findsOneWidget);
    expect(find.text('Arrear Exam (0)'), findsOneWidget);
    expect(find.text('Split By Year'), findsOneWidget);
    expect(find.text('First Year'), findsWidgets);
    expect(find.text('Second Year'), findsWidgets);
  });
}
