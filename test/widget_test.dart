import 'package:flutter_test/flutter_test.dart';
import 'package:kumpaskonek_12/main.dart';

void main() {
  testWidgets('App loads splash screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KumpasKonekApp());

    // Verify that KumpasKonekApp renders without crashing
    expect(find.byType(KumpasKonekApp), findsOneWidget);
  });
}