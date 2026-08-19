import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? selectedVideo;
  Uint8List? videoBytes;
  bool isUploading = false;
  double uploadProgress = 0;
  StreamSubscription<TaskSnapshot>? _uploadSubscription;

  Future<void> pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = kIsWeb ? await picked.readAsBytes() : null;

      setState(() {
        selectedVideo = picked;
        videoBytes = bytes;
        uploadProgress = 0;
      });
    }
  }

  Future<void> uploadVideo() async {
    if (selectedVideo == null) {
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0;
    });

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final extension = _fileExtension(selectedVideo!.name);
      final contentType = _contentTypeForExtension(extension);
      final bytes = videoBytes ?? await selectedVideo!.readAsBytes();

      final ref = FirebaseStorage.instance
          .ref()
          .child('videos')
          .child('$fileName.$extension');

      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {'originalName': selectedVideo!.name},
        ),
      );

      await _uploadSubscription?.cancel();
      _uploadSubscription = uploadTask.snapshotEvents.listen((snapshot) {
        final totalBytes = snapshot.totalBytes;
        if (!mounted || totalBytes == 0) {
          return;
        }

        setState(() {
          uploadProgress = snapshot.bytesTransferred / totalBytes;
        });
      });

      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          uploadTask.cancel();
          throw TimeoutException(
            'The upload took too long. Please try a smaller video or check your internet connection.',
          );
        },
      );

      final downloadUrl = await snapshot.ref.getDownloadURL();

      try {
        await FirebaseFirestore.instance.collection('videos').add({
          'videoUrl': downloadUrl,
          'title': selectedVideo!.name,
          'storagePath': snapshot.ref.fullPath,
          'contentType': contentType,
          'sizeBytes': bytes.length,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (firestoreError) {
        if (!mounted) return;

        setState(() {
          isUploading = false;
          uploadProgress = 0;
          selectedVideo = null;
          videoBytes = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'The file uploaded, but it could not be saved to the video list. '
              'It can still appear from Storage if Storage rules allow reading. '
              'Check Firestore rules for the videos collection. $firestoreError',
            ),
          ),
        );
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isUploading = false;
        uploadProgress = 0;
        selectedVideo = null;
        videoBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload successful')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isUploading = false;
        uploadProgress = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Firebase upload failed. Check Storage and Firestore setup.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isUploading = false;
        uploadProgress = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _fileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) {
      return 'mp4';
    }

    return parts.last.toLowerCase();
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'mov':
        return 'video/quicktime';
      case 'm4v':
        return 'video/x-m4v';
      case 'webm':
        return 'video/webm';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'mp4':
      default:
        return 'video/mp4';
    }
  }

  @override
  void dispose() {
    _uploadSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        AppConstants.primaryColor.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.video_library_rounded,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    selectedVideo != null
                        ? 'Video selected and ready for upload'
                        : 'Select a promo video from your gallery',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedVideo?.name ?? 'No file selected yet',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppConstants.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isUploading ? null : pickVideo,
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Pick Video'),
              ),
            ),
            const SizedBox(height: 12),
            if (isUploading) ...[
              LinearProgressIndicator(
                value: uploadProgress == 0 ? null : uploadProgress,
              ),
              const SizedBox(height: 8),
              Text(
                uploadProgress == 0
                    ? 'Starting upload...'
                    : '${(uploadProgress * 100).clamp(0, 100).toStringAsFixed(0)}% uploaded',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConstants.textSecondaryColor,
                    ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    isUploading || selectedVideo == null ? null : uploadVideo,
                icon: isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(isUploading ? 'Uploading...' : 'Upload Video'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
