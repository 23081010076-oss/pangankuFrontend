import 'package:flutter_test/flutter_test.dart';
import 'package:panganku_mobile/main.dart';

void main() {
  testWidgets('renders PanganKu app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('SIPKAP Lamongan'), findsOneWidget);
  });
}
