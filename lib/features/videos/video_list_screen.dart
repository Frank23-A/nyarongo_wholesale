import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nyarongo_wholesale/models/video_model.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';
import 'package:video_player/video_player.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  late Future<_VideoLoadResult> _videosFuture;

  @override
  void initState() {
    super.initState();
    _videosFuture = _loadVideos();
  }

  void _refreshVideos() {
    setState(() {
      _videosFuture = _loadVideos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshVideos,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_VideoLoadResult>(
        future: _videosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = snapshot.data ??
              _VideoLoadResult(
                videos: const [],
                errors: [
                  snapshot.error?.toString() ?? 'Could not load videos.',
                ],
              );

          if (result.videos.isEmpty) {
            final message = result.errors.isEmpty
                ? 'No videos uploaded yet.'
                : 'No videos found. ${result.errors.join(' ')}';

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.screenPadding),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            children: [
              if (result.errors.isNotEmpty) ...[
                _VideoWarningBanner(message: result.errors.join(' ')),
                const SizedBox(height: 16),
              ],
              for (final video in result.videos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: VideoPlayerWidget(video: video),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<_VideoLoadResult> _loadVideos() async {
    final videosByKey = <String, VideoModel>{};
    final errors = <String>[];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('videos')
          .orderBy('createdAt', descending: true)
          .get();

      for (final doc in snapshot.docs) {
        final video = VideoModel.fromMap(doc.data(), doc.id);
        if (video.videoUrl.trim().isEmpty) {
          continue;
        }

        final storagePath = doc.data()['storagePath'] as String?;
        videosByKey[storagePath ?? video.videoUrl] = video;
      }
    } catch (error) {
      errors.add(
        'Firestore videos could not be loaded. Check Firestore rules.',
      );
    }

    try {
      final storageVideos = await _loadStorageVideos();
      for (final video in storageVideos) {
        videosByKey.putIfAbsent(video.id, () => video);
      }
    } catch (error) {
      errors.add(
        'Storage videos could not be loaded. Check Storage read/list rules.',
      );
    }

    final videos = videosByKey.values.toList(growable: false)
      ..sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) {
          return a.title.compareTo(b.title);
        }
        if (aDate == null) {
          return 1;
        }
        if (bDate == null) {
          return -1;
        }
        return bDate.compareTo(aDate);
      });

    return _VideoLoadResult(videos: videos, errors: errors);
  }

  Future<List<VideoModel>> _loadStorageVideos() async {
    final result = await FirebaseStorage.instance.ref('videos').listAll();
    final videos = <VideoModel>[];

    for (final item in result.items) {
      final metadata = await item.getMetadata();
      final url = await item.getDownloadURL();
      final title = metadata.customMetadata?['originalName'] ?? item.name;

      videos.add(
        VideoModel(
          id: item.fullPath,
          videoUrl: url,
          title: title,
          createdAt: metadata.timeCreated,
        ),
      );
    }

    return videos;
  }
}

class _VideoLoadResult {
  final List<VideoModel> videos;
  final List<String> errors;

  const _VideoLoadResult({
    required this.videos,
    required this.errors,
  });
}

class _VideoWarningBanner extends StatelessWidget {
  final String message;

  const _VideoWarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerWidget({super.key, required this.video});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController controller;
  var hasPlaybackError = false;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
    )
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      }).catchError((_) {
        if (mounted) {
          setState(() => hasPlaybackError = true);
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.title.isEmpty ? 'Uploaded video' : widget.video.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          hasPlaybackError
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('This video could not be loaded.'),
                  ),
                )
              : controller.value.isInitialized
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(controller),
                            IconButton.filled(
                              onPressed: () {
                                setState(() {
                                  if (controller.value.isPlaying) {
                                    controller.pause();
                                  } else {
                                    controller.play();
                                  }
                                });
                              },
                              icon: Icon(
                                controller.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
