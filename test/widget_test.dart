import 'package:flutter_test/flutter_test.dart';

import 'package:fh_sdui_v2/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();
  });
}
