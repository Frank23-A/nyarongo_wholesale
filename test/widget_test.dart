import 'package:flutter_test/flutter_test.dart';
import 'package:nyarongo_wholesale/app.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';

void main() {
  testWidgets('shows the app shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const NyarongoWholesaleApp(firebaseReady: false),
    );

    expect(find.text(AppConstants.appName), findsWidgets);
  });
}
