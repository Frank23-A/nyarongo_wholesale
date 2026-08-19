import 'dart:io';

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nyarongo_wholesale/screens/customer/call_screen.dart';

class CustomerMessagesScreen extends StatefulWidget {
  const CustomerMessagesScreen({super.key});

  @override
  State<CustomerMessagesScreen> createState() => _CustomerMessagesScreenState();
}

class _CustomerMessagesScreenState extends State<CustomerMessagesScreen> {
  String _searchQuery = '';

  final List<ChatThread> _threads = [
    ChatThread(
      id: 'amina',
      name: 'Amina',
      status: 'Online',
      avatarColor: Colors.green,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      latestMessage: 'I just sent the order details.',
      messages: [
        const ChatMessage(sender: 'them', text: 'Hi! Are you available?', time: '09:04'),
        const ChatMessage(sender: 'me', text: 'Yes, I can help now.', time: '09:06'),
        const ChatMessage(sender: 'them', text: 'I just sent the order details.', time: '09:12'),
      ],
    ),
    ChatThread(
      id: 'brenda',
      name: 'Brenda',
      status: 'Typing...',
      avatarColor: Colors.blue,
      updatedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 23)),
      latestMessage: 'Take a photo and send it when ready.',
      messages: [
        const ChatMessage(sender: 'them', text: 'Can you send a photo of the product?', time: '08:20'),
        const ChatMessage(sender: 'me', text: 'Sure, I will take one now.', time: '08:24'),
      ],
    ),
    ChatThread(
      id: 'sara',
      name: 'Sara',
      status: 'Offline',
      avatarColor: Colors.deepPurple,
      updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      latestMessage: 'Thanks! Chat soon.',
      messages: [
        const ChatMessage(sender: 'them', text: 'Thanks for the update.', time: 'Yesterday'),
        const ChatMessage(sender: 'me', text: 'You are welcome!', time: 'Yesterday'),
      ],
    ),
  ];

  List<ChatThread> get _filteredThreads {
    final lower = _searchQuery.toLowerCase();
    return _threads.where((thread) {
      if (thread.isArchived) return false;
      if (_searchQuery.isEmpty) return true;
      return thread.name.toLowerCase().contains(lower) || thread.latestMessage.toLowerCase().contains(lower);
    }).toList();
  }

  void _showProfileOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Change display name'),
                onTap: () {
                  Navigator.of(context).pop();
                  _editDisplayName();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editDisplayName() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update display name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter a display name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _openChat(ChatThread thread) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerChatScreen(thread: thread, currentUser: 'You'),
      ),
    );
  }

  Future<void> _openContactPicker() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final status = await Permission.contacts.request();
      if (!status.isGranted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Contacts permission is required to add a chat')),
        );
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      if (!mounted) return;

      final contactsWithPhone = contacts.where((c) => c.phones.isNotEmpty).toList();
      if (contactsWithPhone.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No contacts with phone numbers found')),
        );
        return;
      }

      final Contact? selected = await showDialog<Contact>(
        context: context,
        builder: (context) => _ContactPickerDialog(contacts: contactsWithPhone),
      );

      if (!mounted || selected == null) return;

      final phoneValues = selected.phones
          .map((p) => p.number.trim())
          .where((v) => v.isNotEmpty)
          .toList();

      if (phoneValues.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Selected contact has no phone number')),
        );
        return;
      }

      final normalizedPhone = _normalizePhone(phoneValues.first);
      if (normalizedPhone.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Selected phone number is not valid')),
        );
        return;
      }

      final existingIndex = _threads.indexWhere((t) => t.id == normalizedPhone);
      if (existingIndex != -1) {
        _openChat(_threads[existingIndex]);
        return;
      }

      final displayName = selected.displayName.trim().isEmpty
          ? normalizedPhone
          : selected.displayName.trim();

      final thread = ChatThread(
        id: normalizedPhone,
        name: displayName,
        status: 'Online',
        avatarColor: Colors.teal,
        messages: [],
        latestMessage: '',
        updatedAt: DateTime.now(),
      );

      setState(() {
        _threads.insert(0, thread);
      });
      _openChat(thread);
    } catch (error) {
      // Handle or ignore cancellation by user.
    }
  }

  Future<void> _showProfileDialog(ChatThread thread) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(thread.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: thread.avatarColor.withValues(alpha: 46),
                child: Text(
                  thread.name[0],
                  style: TextStyle(
                    color: thread.avatarColor,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Status: ${thread.status}'),
              const SizedBox(height: 8),
              Text(thread.isFavorite ? 'Favorite' : 'Not favorite'),
              const SizedBox(height: 8),
              Text(thread.isBlocked ? 'Blocked' : 'Active'),
              const SizedBox(height: 8),
              Text(thread.isLocked ? 'Locked' : 'Unlocked'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChatActions(ChatThread thread) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Chat actions',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Padding(
          padding: const EdgeInsets.only(top: 90, bottom: 110, right: 16),
          child: Align(
            alignment: Alignment.topRight,
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.94),
              elevation: 16,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 140,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${thread.name} actions',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(vertical: -1),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: const Icon(Icons.clear_all, size: 20),
                            title: Text(
                              'Clear chat',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _clearChat(thread);
                            },
                          ),
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(vertical: -1),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: const Icon(Icons.block, size: 20),
                            title: Text(
                              thread.isBlocked ? 'Unblock chat' : 'Block chat',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _toggleBlockChat(thread);
                            },
                          ),
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(vertical: -1),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: const Icon(Icons.list, size: 20),
                            title: Text(
                              thread.isAddedToList ? 'Remove from list' : 'Add to list',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _toggleAddToList(thread);
                            },
                          ),
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(vertical: -1),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: const Icon(Icons.star, size: 20),
                            title: Text(
                              thread.isFavorite ? 'Remove from favorite' : 'Add to favorite',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _toggleFavorite(thread);
                            },
                          ),
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(vertical: -1),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: const Icon(Icons.lock, size: 20),
                            title: Text(
                              thread.isLocked ? 'Unlock chat' : 'Lock chat',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _toggleLockChat(thread);
                            },
                          ),
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(vertical: -1),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: const Icon(Icons.mark_chat_read, size: 20),
                            title: Text(
                              'Mark as read',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _markAsRead(thread);
                            },
                          ),
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(vertical: -1),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: const Icon(Icons.contact_page, size: 20),
                            title: Text(
                              'View contact',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _showProfileDialog(thread);
                            },
                          ),
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(vertical: -1),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: const Icon(Icons.archive, size: 20),
                            title: Text(
                              'Add to archive',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _archiveChat(thread);
                            },
                          ),
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(vertical: -1),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: const Icon(Icons.delete, size: 20),
                            title: Text(
                              'Delete chat',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _deleteChat(thread);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
          child: child,
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearChat(ChatThread thread) {
    setState(() {
      thread.messages.clear();
      thread.latestMessage = '';
    });
    _showSnack('Chat cleared');
  }

  void _toggleBlockChat(ChatThread thread) {
    setState(() {
      thread.isBlocked = !thread.isBlocked;
      thread.status = thread.isBlocked ? 'Blocked' : 'Online';
    });
    _showSnack(thread.isBlocked ? 'Chat blocked' : 'Chat unblocked');
  }

  void _toggleAddToList(ChatThread thread) {
    setState(() => thread.isAddedToList = !thread.isAddedToList);
    _showSnack(thread.isAddedToList ? 'Added to list' : 'Removed from list');
  }

  void _toggleFavorite(ChatThread thread) {
    setState(() => thread.isFavorite = !thread.isFavorite);
    _showSnack(thread.isFavorite ? 'Added to favorite' : 'Removed from favorite');
  }

  void _toggleLockChat(ChatThread thread) {
    setState(() => thread.isLocked = !thread.isLocked);
    _showSnack(thread.isLocked ? 'Chat locked' : 'Chat unlocked');
  }

  void _markAsRead(ChatThread thread) {
    setState(() => thread.isUnread = false);
    _showSnack('Marked as read');
  }

  void _archiveChat(ChatThread thread) {
    setState(() => thread.isArchived = true);
    _showSnack('Chat archived');
  }

  void _deleteChat(ChatThread thread) {
    setState(() => _threads.remove(thread));
    _showSnack('Chat deleted');
  }

  String _normalizePhone(String raw) {
    if (raw.isEmpty) return '';
    final hasPlus = raw.trim().startsWith('+');
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 6) return '';
    return hasPlus ? '+$digits' : digits;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 51),
              child: Text(
                'Y',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Messages'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add chat',
            onPressed: _openContactPicker,
          ),
          IconButton(
            tooltip: 'Update profile',
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: _showProfileOptions,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search chats or contacts',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: _filteredThreads.isEmpty
                  ? Center(
                      child: Text(
                        'No chats found. Start a new conversation.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _filteredThreads.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final thread = _filteredThreads[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: InkWell(
                              borderRadius: BorderRadius.circular(26),
                              onTap: () => _showProfileDialog(thread),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: thread.avatarColor.withValues(alpha: 46),
                                child: Text(
                                  thread.name[0],
                                  style: TextStyle(
                                    color: thread.avatarColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(child: Text(thread.name)),
                                if (thread.isFavorite)
                                  const Icon(Icons.star, size: 18, color: Colors.amber),
                                if (thread.isBlocked)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: Icon(Icons.block, size: 18, color: Colors.redAccent),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              thread.isBlocked ? 'Blocked' : thread.latestMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTimestamp(thread.updatedAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  thread.status,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                            onTap: () => _openChat(thread),
                            onLongPress: () => _showChatActions(thread),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_threads.isNotEmpty) {
            _openChat(_threads.first);
          }
        },
        tooltip: 'Open a chat',
        child: const Icon(Icons.chat_bubble_rounded),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays >= 1) {
      return '${time.day}/${time.month}';
    }
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final contact = _filtered[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        contact.displayName.isNotEmpty
                            ? contact.displayName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(contact.displayName),
                    subtitle: Text(
                      contact.phones.isNotEmpty ? contact.phones.first.number : '',
                    ),
                    onTap: () => Navigator.of(context).pop(contact),
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

// ── Chat Screens ───────────────────────────────────────────────────────────────
class CustomerChatScreen extends StatefulWidget {
  final ChatThread thread;
  final String currentUser;

  const CustomerChatScreen({super.key, required this.thread, required this.currentUser});

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage({String? text, File? image}) {
    if ((text ?? '').trim().isEmpty && image == null) return;

    final message = ChatMessage(
      sender: 'me',
      text: text ?? '',
      imageFile: image,
      time: _currentTimeLabel(),
    );

    setState(() {
      widget.thread.messages.add(message);
      widget.thread.latestMessage = image != null ? 'Photo' : message.text;
      widget.thread.updatedAt = DateTime.now();
    });

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _sendMedia(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return;
    _sendMessage(image: File(picked.path));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _currentTimeLabel() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: thread.avatarColor.withValues(alpha: 51),
              child: Text(
                thread.name[0],
                style: TextStyle(
                  color: thread.avatarColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(thread.name),
                Text(
                  thread.status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 217),
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    contactName: thread.name,
                    contactId: thread.id,
                    callType: CallType.audio,
                    currentUser: widget.currentUser,
                  ),
                ),
              );
            },
            tooltip: 'Call',
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    contactName: thread.name,
                    contactId: thread.id,
                    callType: CallType.video,
                    currentUser: widget.currentUser,
                  ),
                ),
              );
            },
            tooltip: 'Video call',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: thread.messages.length,
                itemBuilder: (context, index) {
                  final message = thread.messages[index];
                  final isMe = message.sender == 'me';
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isMe ? 18 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.imageFile != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                message.imageFile!,
                                width: MediaQuery.of(context).size.width * 0.68,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (message.text.isNotEmpty) ...[
                            Text(
                              message.text,
                              style: TextStyle(
                                color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            message.time,
                            style: TextStyle(
                              color: isMe ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_camera_rounded),
                    onPressed: () => _sendMedia(ImageSource.camera),
                    tooltip: 'Take photo',
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library_rounded),
                    onPressed: () => _sendMedia(ImageSource.gallery),
                    tooltip: 'Choose image',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(text: _messageController.text.trim()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () => _sendMessage(text: _messageController.text.trim()),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data Models ────────────────────────────────────────────────────────────────
class ChatThread {
  final String id;
  final String name;
  String status;
  final Color avatarColor;
  final List<ChatMessage> messages;
  String latestMessage;
  DateTime updatedAt;
  bool isFavorite;
  bool isBlocked;
  bool isLocked;
  bool isArchived;
  bool isAddedToList;
  bool isUnread;

  ChatThread({
    required this.id,
    required this.name,
    required this.status,
    required this.avatarColor,
    required this.messages,
    required this.latestMessage,
    required this.updatedAt,
    this.isFavorite = false,
    this.isBlocked = false,
    this.isLocked = false,
    this.isArchived = false,
    this.isAddedToList = false,
    this.isUnread = false,
  });
}

class ChatMessage {
  final String sender;
  final String text;
  final File? imageFile;
  final String time;

  const ChatMessage({
    required this.sender,
    required this.text,
    this.imageFile,
    required this.time,
  });
}