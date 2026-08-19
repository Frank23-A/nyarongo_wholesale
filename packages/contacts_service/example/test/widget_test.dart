import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Update this import path to match your project structure
import 'package:nyarongo_wholesale/screens/customer/contact_list_page.dart';

void main() {
  testWidgets('ContactListPage renders correctly', (WidgetTester tester) async {
    // Build the ContactListPage inside a MaterialApp
    await tester.pumpWidget(
      const MaterialApp(
        home: ContactListPage(),
      ),
    );

    // Allow async initState (refreshContacts) to settle
    await tester.pump();

    // Verify the AppBar title is present
    expect(find.text('Contacts'), findsOneWidget);

    // Verify the Add and Refresh buttons are present in the AppBar
    expect(find.byIcon(Icons.create), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('ContactListPage shows loading indicator initially',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ContactListPage(),
      ),
    );

    // Before async completes, a loading indicator should show
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ContactListPage FAB is present', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ContactListPage(),
      ),
    );

    await tester.pump();

    // FAB should be present
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}