import '../config/api_config.dart';

class ResourceModel {
  final int id;
  final String title;
  final String? description;
  final String type; // 'video', 'pdf', 'image'
  final int sortOrder;
  final String? subject;
  final String rawFileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileSizeHuman;
  final String? mimeType;
  final String? rawThumbnailUrl;
  final String? createdAt;

  ResourceModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.sortOrder,
    this.subject,
    required this.rawFileUrl,
    this.fileName,
    this.fileSize,
    this.fileSizeHuman,
    this.mimeType,
    this.rawThumbnailUrl,
    this.createdAt,
  });

  String get fileUrl => ApiConfig.formatUrl(rawFileUrl);
  String? get thumbnailUrl => ApiConfig.formatUrl(rawThumbnailUrl);

  bool get isVideo => type.toLowerCase() == 'video';
  bool get isPdf => type.toLowerCase() == 'pdf';
  bool get isImage => type.toLowerCase() == 'image';

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled Material',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'video',
      sortOrder: json['sort_order'] as int? ?? 0,
      subject: json['subject'] as String?,
      rawFileUrl: json['file_url'] as String? ?? '',
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      fileSizeHuman: json['file_size_human'] as String?,
      mimeType: json['mime_type'] as String?,
      rawThumbnailUrl: json['thumbnail_url'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
