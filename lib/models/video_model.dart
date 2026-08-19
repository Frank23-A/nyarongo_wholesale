import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String videoUrl;
  final String title;
  final DateTime? createdAt;

  const VideoModel({
    required this.id,
    required this.videoUrl,
    this.title = '',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'videoUrl': videoUrl,
      'title': title,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory VideoModel.fromMap(Map<String, dynamic> map, String docId) {
    final createdAtValue = map['createdAt'];

    return VideoModel(
      id: docId,
      videoUrl: map['videoUrl'] as String? ?? '',
      title: map['title'] as String? ?? '',
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : createdAtValue is DateTime
              ? createdAtValue
              : DateTime.tryParse(createdAtValue?.toString() ?? ''),
    );
  }
}
