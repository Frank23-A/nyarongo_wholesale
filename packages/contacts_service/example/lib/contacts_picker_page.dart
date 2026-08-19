import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactPickerPage extends StatefulWidget {
  const ContactPickerPage({super.key});

  @override
  State<ContactPickerPage> createState() => _ContactPickerPageState();
}

class _ContactPickerPageState extends State<ContactPickerPage> {
  Contact? _contact;
  bool _loading = false;

  Future<void> _pickContact() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission is required')),
        );
      }
      return;
    }

    setState(() => _loading = true);

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      if (!mounted) return;

      final Contact? selected = await showDialog<Contact>(
        context: context,
        builder: (context) => _ContactPickerDialog(contacts: contacts),
      );

      if (selected != null) {
        setState(() => _contact = selected);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking contact: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts Picker Example')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: _loading ? null : _pickContact,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.contacts),
                label: const Text('Pick a contact'),
              ),
              const SizedBox(height: 24),
              if (_contact != null) ...[
                const Text(
                  'Selected Contact',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              child: Text(
                                _contact!.displayName.isNotEmpty
                                    ? _contact!.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _contact!.displayName,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        if (_contact!.phones.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text('Phone numbers:',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          for (final p in _contact!.phones)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone, size: 16),
                                  const SizedBox(width: 8),
                                  Text(p.number),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${p.label.name})',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        if (_contact!.emails.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text('Emails:',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          for (final e in _contact!.emails)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.email, size: 16),
                                  const SizedBox(width: 8),
                                  Text(e.address),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ] else
                Text(
                  'No contact selected yet.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Contact Picker Dialog ──────────────────────────────────────────────────────
class _ContactPickerDialog extends StatefulWidget {
  final List<Contact> contacts;
  const _ContactPickerDialog({required this.contacts});

  @override
  State<_ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends State<_ContactPickerDialog> {
  String _query = '';

  List<Contact> get _filtered {
    if (_query.isEmpty) return widget.contacts;
    final lower = _query.toLowerCase();
    return widget.contacts
        .where((c) => c.displayName.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search contacts',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('No contacts found'))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final c = _filtered[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              c.displayName.isNotEmpty
                                  ? c.displayName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(c.displayName),
                          subtitle: c.phones.isNotEmpty
                              ? Text(c.phones.first.number)
                              : null,
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}