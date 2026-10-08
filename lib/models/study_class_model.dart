import 'resource_model.dart';
import 'question_paper_model.dart'; // contains QuestionModel

class PlaylistItemModel {
  final int id;
  final String itemType; // 'resource' or 'question'
  final int sortOrder;
  final String? subject;

  final ResourceModel? resource;
  final QuestionModel? question;

  PlaylistItemModel({
    required this.id,
    required this.itemType,
    required this.sortOrder,
    this.subject,
    this.resource,
    this.question,
  });

  bool get isResource => itemType == 'resource';
  bool get isQuestion => itemType == 'question';

  factory PlaylistItemModel.fromJson(Map<String, dynamic> json) {
    final type = json['item_type'] as String? ?? 'resource';
    return PlaylistItemModel(
      id: json['id'] as int? ?? 0,
      itemType: type,
      sortOrder: json['sort_order'] as int? ?? 0,
      subject: json['subject'] as String?,
      resource: type == 'resource' ? ResourceModel.fromJson(json) : null,
      question: type == 'question' ? QuestionModel.fromJson(json) : null,
    );
  }
}

class StudyClassModel {
  final int id;
  final String name;
  final String? description;
  final int sortOrder;
  final int resourcesCount;
  final String? createdAt;
  final List<ResourceModel> materials;
  final List<PlaylistItemModel> playlist;
  final String? subject;

  StudyClassModel({
    required this.id,
    required this.name,
    this.description,
    required this.sortOrder,
    required this.resourcesCount,
    this.createdAt,
    this.materials = const [],
    this.playlist = const [],
    this.subject,
  });

  factory StudyClassModel.fromJson(Map<String, dynamic> json) {
    List<ResourceModel> parsedMaterials = [];
    if (json['materials'] != null && json['materials'] is List) {
      parsedMaterials = (json['materials'] as List)
          .map((m) => ResourceModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    List<PlaylistItemModel> parsedPlaylist = [];
    if (json['playlist'] != null && json['playlist'] is List) {
      parsedPlaylist = (json['playlist'] as List)
          .map((item) => PlaylistItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return StudyClassModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Untitled Class',
      description: json['description'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      resourcesCount: json['resources_count'] as int? ?? parsedMaterials.length,
      createdAt: json['created_at'] as String?,
      materials: parsedMaterials,
      playlist: parsedPlaylist,
      subject: json['subject'] as String?,
    );
  }
}
