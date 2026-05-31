import 'package:flutter_test/flutter_test.dart';
import 'package:campus_health_app/main.dart';

void main() {
  testWidgets('App should display Campus Health title',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CampusHealthApp());
    expect(find.text('Campus Health'), findsWidgets);
  });
}
