import 'package:flutter_test/flutter_test.dart';
import 'package:panganku_mobile/main.dart';

void main() {
  testWidgets('renders PanganKu auth flow', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('PanganKu'), findsOneWidget);
    expect(
      find.text('Sistem Informasi Ketahanan Pangan\nKabupaten Lamongan'),
      findsOneWidget,
    );

    await tester.tap(find.text('Lupa kata sandi?'));
    await tester.pumpAndSettle();

    expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
    expect(find.text('Email Akun'), findsOneWidget);
  });
}
