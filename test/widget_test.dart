import 'package:flutter_test/flutter_test.dart';

import 'package:imageapp/main.dart';

void main() {
  testWidgets('shows the image grid home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('your images'), findsOneWidget);
    expect(find.text('Set as background'), findsWidgets);
  });
}
