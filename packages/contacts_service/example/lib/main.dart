import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'contacts_list_page.dart';
import 'contacts_picker_page.dart';

void main() => runApp(const ContactsExampleApp());

class ContactsExampleApp extends StatelessWidget {
  const ContactsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contacts Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomePage(),
      routes: <String, WidgetBuilder>{
        '/add': (context) => const AddContactPage(),
        '/contactsList': (context) => const ContactListPage(),
        '/nativeContactPicker': (context) => const ContactPickerPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Request permission on launch without navigating anywhere
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.contacts.status;
    if (status.isDenied) {
      await Permission.contacts.request();
    }
  }

  Future<void> _askPermissions(String routeName) async {
    final status = await Permission.contacts.request();

    if (!mounted) return;

    if (status.isGranted) {
      Navigator.of(context).pushNamed(routeName);
    } else {
      _handleInvalidPermissions(status);
    }
  }

  void _handleInvalidPermissions(PermissionStatus status) {
    String message;

    if (status.isPermanentlyDenied) {
      message = 'Contacts permission permanently denied. Enable it in Settings.';
      // Offer to open app settings
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
              'Contacts access is permanently denied. Please enable it in your device settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return;
    } else if (status.isDenied) {
      message = 'Access to contact data denied.';
    } else {
      message = 'Contact data not available on device.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts Plugin Example')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.contacts, size: 72, color: Colors.teal),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.list),
                label: const Text('Contacts List'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => _askPermissions('/contactsList'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_search),
                label: const Text('Contact Picker'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => _askPermissions('/nativeContactPicker'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Add New Contact'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => _askPermissions('/add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
