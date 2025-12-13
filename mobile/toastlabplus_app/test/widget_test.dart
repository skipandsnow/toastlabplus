import 'package:flutter_test/flutter_test.dart';

import 'package:toastlabplus_app/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ToastLabPlusApp());

    // Verify the navigation bar is present
    expect(find.byType(ToastLabPlusApp), findsOneWidget);
  });
}
