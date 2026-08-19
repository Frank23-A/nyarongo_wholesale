import 'dart:async';

import 'package:flutter/material.dart';

enum CallType { audio, video }

class CallScreen extends StatefulWidget {
  final String contactName;
  final String contactId;
  final CallType callType;
  final String currentUser;

  const CallScreen({
    super.key,
    required this.contactName,
    required this.contactId,
    required this.callType,
    required this.currentUser,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late Timer _timer;
  int _callSeconds = 0;
  bool _connected = false;
  String _status = 'Calling...';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _connected = true;
        _status = 'Connected';
      });
    });
  }

  void _onTick(Timer timer) {
    if (!_connected) return;
    setState(() {
      _callSeconds += 1;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.callType == CallType.video;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              isVideo ? 'Video Call' : 'Voice Call',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.contactName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _status,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: isVideo
                    ? _buildVideoPreview(context)
                    : _buildAudioPreview(context),
              ),
            ),
            if (_connected)
              Text(
                _formatDuration(Duration(seconds: _callSeconds)),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isVideo)
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.videocam_off_rounded),
                      label: const Text('Mute Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (isVideo) const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.call_end_rounded),
                    label: const Text('End Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 51),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Center(
          child: Icon(
            Icons.videocam_rounded,
            size: 96,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPreview(BuildContext context) {
    return CircleAvatar(
      radius: 86,
      backgroundColor: Colors.white24,
      child: Icon(
        Icons.headset_mic_rounded,
        size: 92,
        color: Colors.white,
      ),
    );
  }
}
