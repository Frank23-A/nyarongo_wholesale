import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

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

    final contacts = await ContactsService.getContacts();

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
                                        (x) => x.identifier == updated.identifier);
                                    if (i != -1) _contacts[i] = updated;
                                  });
                                },
                              ),
                            ),
                          );
                          refreshContacts();
                        },
                        leading: (c.avatar != null && c.avatar!.isNotEmpty)
                            ? CircleAvatar(
                                backgroundImage: MemoryImage(c.avatar!))
                            : CircleAvatar(
                                child: Text(
                                  _displayName(c).isNotEmpty
                                      ? _displayName(c)[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                        title: Text(_displayName(c)),
                        subtitle: c.phones?.isNotEmpty == true
                            ? Text(c.phones!.first.value ?? '')
                            : null,
                      );
                    },
                  ),
      ),
    );
  }

  String _displayName(Contact contact) {
    return contact.displayName ??
        [contact.givenName, contact.familyName]
            .where((part) => part?.isNotEmpty == true)
            .join(' ');
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
      await ContactsService.deleteContact(_contact);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _contact;
    final displayName = _displayName(c);
    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
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
            if (c.avatar != null && c.avatar!.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: MemoryImage(c.avatar!),
                  ),
                ),
              ),

            // Name fields
            _tile('First name', c.givenName),
            _tile('Middle name', c.middleName),
            _tile('Last name', c.familyName),
            _tile('Prefix', c.prefix),
            _tile('Suffix', c.suffix),

            // Birthday
            if (c.birthday != null)
              _tile(
                'Birthday',
                DateFormat('dd-MM-yyyy').format(c.birthday!),
              ),

            // Organization
            _tile('Company', c.company),
            _tile('Job', c.jobTitle),

            // Phones
            if (c.phones?.isNotEmpty == true) ...[
              const ListTile(title: Text('Phones', style: TextStyle(fontWeight: FontWeight.bold))),
              for (final p in c.phones!)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    title: Text(p.label ?? ''),
                    trailing: Text(p.value ?? ''),
                  ),
                ),
            ],

            // Emails
            if (c.emails?.isNotEmpty == true) ...[
              const ListTile(title: Text('Emails', style: TextStyle(fontWeight: FontWeight.bold))),
              for (final e in c.emails!)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    title: Text(e.label ?? ''),
                    trailing: Text(e.value ?? ''),
                  ),
                ),
            ],

            // Addresses
            if (c.postalAddresses?.isNotEmpty == true) ...[
              const ListTile(title: Text('Addresses', style: TextStyle(fontWeight: FontWeight.bold))),
              for (final a in c.postalAddresses!)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _tile('Street', a.street),
                      _tile('City', a.city),
                      _tile('Region', a.region),
                      _tile('Postcode', a.postcode),
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

  String _displayName(Contact contact) {
    return contact.displayName ??
        [contact.givenName, contact.familyName]
            .where((part) => part?.isNotEmpty == true)
            .join(' ');
  }

  Widget _tile(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
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

    final contact = Contact(
      givenName: _firstName.text.trim(),
      middleName: _middleName.text.trim(),
      familyName: _lastName.text.trim(),
      prefix: _prefix.text.trim(),
      suffix: _suffix.text.trim(),
      phones: _phone.text.trim().isEmpty
          ? []
          : [Item(label: 'mobile', value: _phone.text.trim())],
      emails: _email.text.trim().isEmpty
          ? []
          : [Item(label: 'work', value: _email.text.trim())],
      company: _company.text.trim(),
      jobTitle: _job.text.trim(),
      postalAddresses: (_street.text.trim().isEmpty && _city.text.trim().isEmpty)
          ? []
          : [
              PostalAddress(
                street: _street.text.trim(),
                city: _city.text.trim(),
                region: _region.text.trim(),
                postcode: _postcode.text.trim(),
                country: _country.text.trim(),
              )
            ],
    );

    await ContactsService.addContact(contact);
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
    _firstName = TextEditingController(text: c.givenName);
    _middleName = TextEditingController(text: c.middleName);
    _lastName = TextEditingController(text: c.familyName);
    _prefix = TextEditingController(text: c.prefix);
    _suffix = TextEditingController(text: c.suffix);
    _phone = TextEditingController(
        text: c.phones?.isNotEmpty == true ? c.phones!.first.value : '');
    _email = TextEditingController(
        text: c.emails?.isNotEmpty == true ? c.emails!.first.value : '');
    _company = TextEditingController(text: c.company);
    _job = TextEditingController(text: c.jobTitle);
    _street = TextEditingController(
        text: c.postalAddresses?.isNotEmpty == true ? c.postalAddresses!.first.street : '');
    _city = TextEditingController(
        text: c.postalAddresses?.isNotEmpty == true ? c.postalAddresses!.first.city : '');
    _region = TextEditingController(
        text: c.postalAddresses?.isNotEmpty == true ? c.postalAddresses!.first.region : '');
    _postcode = TextEditingController(
        text: c.postalAddresses?.isNotEmpty == true ? c.postalAddresses!.first.postcode : '');
    _country = TextEditingController(
        text: c.postalAddresses?.isNotEmpty == true ? c.postalAddresses!.first.country : '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.contact
      ..givenName = _firstName.text.trim()
      ..middleName = _middleName.text.trim()
      ..familyName = _lastName.text.trim()
      ..prefix = _prefix.text.trim()
      ..suffix = _suffix.text.trim()
      ..phones = _phone.text.trim().isEmpty
          ? []
          : [Item(label: 'mobile', value: _phone.text.trim())]
      ..emails = _email.text.trim().isEmpty
          ? []
          : [Item(label: 'work', value: _email.text.trim())]
      ..company = _company.text.trim()
      ..jobTitle = _job.text.trim()
      ..postalAddresses = (_street.text.trim().isEmpty && _city.text.trim().isEmpty)
          ? []
          : [
              PostalAddress(
                street: _street.text.trim(),
                city: _city.text.trim(),
                region: _region.text.trim(),
                postcode: _postcode.text.trim(),
                country: _country.text.trim(),
              )
            ];

    await ContactsService.updateContact(updated);
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
