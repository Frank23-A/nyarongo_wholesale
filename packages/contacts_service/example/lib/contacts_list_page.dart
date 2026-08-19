import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

// ── Contact List Page ──────────────────────────────────────────────────────────
class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});

  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  List<Contact> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refreshContacts();
  }

  Future<void> refreshContacts() async {
    setState(() => _loading = true);

    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission is required')),
        );
      }
      return;
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
    );

    setState(() {
      _contacts = contacts;
      _loading = false;
    });
  }

  Future<void> _openAddContactForm() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddContactPage()),
    );
    if (result == true) refreshContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create),
            onPressed: _openAddContactForm,
            tooltip: 'Add contact',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshContacts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddContactForm,
        tooltip: 'Add contact',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _contacts.isEmpty
                ? const Center(child: Text('No contacts found.'))
                : ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final c = _contacts[index];
                      return ListTile(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ContactDetailsPage(
                                c,
                                onContactUpdated: (updated) {
                                  setState(() {
                                    final i = _contacts.indexWhere(
                                        (x) => x.id == updated.id);
                                    if (i != -1) _contacts[i] = updated;
                                  });
                                },
                              ),
                            ),
                          );
                          refreshContacts();
                        },
                        leading: (c.photo != null && c.photo!.isNotEmpty)
                            ? CircleAvatar(
                                backgroundImage: MemoryImage(c.photo!))
                            : CircleAvatar(
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
                      );
                    },
                  ),
      ),
    );
  }
}

// ── Contact Details Page ───────────────────────────────────────────────────────
class ContactDetailsPage extends StatelessWidget {
  const ContactDetailsPage(
    this._contact, {
    super.key,
    required this.onContactUpdated,
  });

  final Contact _contact;
  final void Function(Contact) onContactUpdated;

  Future<void> _deleteContact(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete contact'),
        content: Text('Delete ${_contact.displayName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await FlutterContacts.deleteContact(_contact);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _contact;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: () => _deleteContact(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              final updated = await Navigator.of(context).push<Contact>(
                MaterialPageRoute(
                  builder: (_) => UpdateContactPage(contact: c),
                ),
              );
              if (updated != null) {
                onContactUpdated(updated);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // Avatar
            if (c.photo != null && c.photo!.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: MemoryImage(c.photo!),
                  ),
                ),
              ),

            // Name fields
            _tile('First name', c.name.first),
            _tile('Middle name', c.name.middle),
            _tile('Last name', c.name.last),
            _tile('Prefix', c.name.prefix),
            _tile('Suffix', c.name.suffix),

            // Birthday
            if (c.events.isNotEmpty)
              _tile(
                'Birthday',
                c.events
                    .where((e) => e.label == EventLabel.birthday)
                    .map((e) {
                      final d =
                          DateTime(e.year ?? 0, e.month, e.day);
                      return DateFormat('dd-MM-yyyy').format(d);
                    })
                    .firstOrNull ?? '',
              ),

            // Organization
            if (c.organizations.isNotEmpty) ...[
              _tile('Company', c.organizations.first.company),
              _tile('Job', c.organizations.first.title),
            ],

            // Phones
            if (c.phones.isNotEmpty) ...[
              const ListTile(title: Text('Phones', style: TextStyle(fontWeight: FontWeight.bold))),
              for (final p in c.phones)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    title: Text(p.label.name),
                    trailing: Text(p.number),
                  ),
                ),
            ],

            // Emails
            if (c.emails.isNotEmpty) ...[
              const ListTile(title: Text('Emails', style: TextStyle(fontWeight: FontWeight.bold))),
              for (final e in c.emails)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    title: Text(e.label.name),
                    trailing: Text(e.address),
                  ),
                ),
            ],

            // Addresses
            if (c.addresses.isNotEmpty) ...[
              const ListTile(title: Text('Addresses', style: TextStyle(fontWeight: FontWeight.bold))),
              for (final a in c.addresses)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _tile('Street', a.street),
                      _tile('City', a.city),
                      _tile('Region', a.state),
                      _tile('Postcode', a.postalCode),
                      _tile('Country', a.country),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return ListTile(
      title: Text(label),
      trailing: Text(value),
    );
  }
}

// ── Add Contact Page ───────────────────────────────────────────────────────────
class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _prefix = TextEditingController();
  final _suffix = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _job = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _postcode = TextEditingController();
  final _country = TextEditingController();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final contact = Contact()
      ..name = Name(
        first: _firstName.text.trim(),
        middle: _middleName.text.trim(),
        last: _lastName.text.trim(),
        prefix: _prefix.text.trim(),
        suffix: _suffix.text.trim(),
      )
      ..phones = _phone.text.trim().isEmpty
          ? []
          : [Phone(_phone.text.trim(), label: PhoneLabel.mobile)]
      ..emails = _email.text.trim().isEmpty
          ? []
          : [Email(_email.text.trim(), label: EmailLabel.work)]
      ..organizations = (_company.text.trim().isEmpty && _job.text.trim().isEmpty)
          ? []
          : [
              Organization(
                company: _company.text.trim(),
                title: _job.text.trim(),
              )
            ]
      ..addresses = (_street.text.trim().isEmpty && _city.text.trim().isEmpty)
          ? []
          : [
              Address(
                street: _street.text.trim(),
                city: _city.text.trim(),
                state: _region.text.trim(),
                postalCode: _postcode.text.trim(),
                country: _country.text.trim(),
              )
            ];

    await FlutterContacts.insertContact(contact);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a contact'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field(_firstName, 'First name'),
              _field(_middleName, 'Middle name'),
              _field(_lastName, 'Last name'),
              _field(_prefix, 'Prefix'),
              _field(_suffix, 'Suffix'),
              _field(_phone, 'Phone', type: TextInputType.phone),
              _field(_email, 'E-mail', type: TextInputType.emailAddress),
              _field(_company, 'Company'),
              _field(_job, 'Job'),
              _field(_street, 'Street'),
              _field(_city, 'City'),
              _field(_region, 'Region'),
              _field(_postcode, 'Postal code'),
              _field(_country, 'Country'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

// ── Update Contact Page ────────────────────────────────────────────────────────
class UpdateContactPage extends StatefulWidget {
  const UpdateContactPage({super.key, required this.contact});

  final Contact contact;

  @override
  State<UpdateContactPage> createState() => _UpdateContactPageState();
}

class _UpdateContactPageState extends State<UpdateContactPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final TextEditingController _prefix;
  late final TextEditingController _suffix;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _company;
  late final TextEditingController _job;
  late final TextEditingController _street;
  late final TextEditingController _city;
  late final TextEditingController _region;
  late final TextEditingController _postcode;
  late final TextEditingController _country;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _firstName = TextEditingController(text: c.name.first);
    _middleName = TextEditingController(text: c.name.middle);
    _lastName = TextEditingController(text: c.name.last);
    _prefix = TextEditingController(text: c.name.prefix);
    _suffix = TextEditingController(text: c.name.suffix);
    _phone = TextEditingController(
        text: c.phones.isNotEmpty ? c.phones.first.number : '');
    _email = TextEditingController(
        text: c.emails.isNotEmpty ? c.emails.first.address : '');
    _company = TextEditingController(
        text: c.organizations.isNotEmpty ? c.organizations.first.company : '');
    _job = TextEditingController(
        text: c.organizations.isNotEmpty ? c.organizations.first.title : '');
    _street = TextEditingController(
        text: c.addresses.isNotEmpty ? c.addresses.first.street : '');
    _city = TextEditingController(
        text: c.addresses.isNotEmpty ? c.addresses.first.city : '');
    _region = TextEditingController(
        text: c.addresses.isNotEmpty ? c.addresses.first.state : '');
    _postcode = TextEditingController(
        text: c.addresses.isNotEmpty ? c.addresses.first.postalCode : '');
    _country = TextEditingController(
        text: c.addresses.isNotEmpty ? c.addresses.first.country : '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.contact
      ..name = Name(
        first: _firstName.text.trim(),
        middle: _middleName.text.trim(),
        last: _lastName.text.trim(),
        prefix: _prefix.text.trim(),
        suffix: _suffix.text.trim(),
      )
      ..phones = _phone.text.trim().isEmpty
          ? []
          : [Phone(_phone.text.trim(), label: PhoneLabel.mobile)]
      ..emails = _email.text.trim().isEmpty
          ? []
          : [Email(_email.text.trim(), label: EmailLabel.work)]
      ..organizations = (_company.text.trim().isEmpty && _job.text.trim().isEmpty)
          ? []
          : [
              Organization(
                company: _company.text.trim(),
                title: _job.text.trim(),
              )
            ]
      ..addresses = (_street.text.trim().isEmpty && _city.text.trim().isEmpty)
          ? []
          : [
              Address(
                street: _street.text.trim(),
                city: _city.text.trim(),
                state: _region.text.trim(),
                postalCode: _postcode.text.trim(),
                country: _country.text.trim(),
              )
            ];

    await FlutterContacts.updateContact(updated);
    if (mounted) Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Contact'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field(_firstName, 'First name'),
              _field(_middleName, 'Middle name'),
              _field(_lastName, 'Last name'),
              _field(_prefix, 'Prefix'),
              _field(_suffix, 'Suffix'),
              _field(_phone, 'Phone', type: TextInputType.phone),
              _field(_email, 'E-mail', type: TextInputType.emailAddress),
              _field(_company, 'Company'),
              _field(_job, 'Job'),
              _field(_street, 'Street'),
              _field(_city, 'City'),
              _field(_region, 'Region'),
              _field(_postcode, 'Postal code'),
              _field(_country, 'Country'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Update Contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}