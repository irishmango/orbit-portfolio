import 'package:orbit/src/features/auth/domain/AppUser.dart';

class Collaboration {
  final String id;
  final String title;
  final String description;

  // For UI convenience
  final List<AppUser> members;

  // For queries (arrayContains)
  final List<String> memberIds;

  final String creatorId;

  Collaboration({
    required this.id,
    required this.title,
    required this.description,
    required this.members,
    required this.memberIds,
    required this.creatorId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'members': members.map((m) => m.toMap()).toList(),
        'memberIds': memberIds,
        'creatorId': creatorId,
      };

  factory Collaboration.fromMap(Map<String, dynamic> map) => Collaboration(
        id: map['id'],
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        members: (map['members'] as List? ?? const [])
            .map((e) => AppUser.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        memberIds: List<String>.from((map['memberIds'] as List?) ?? const []),
        creatorId: map['creatorId'] ?? '',
      );

  AppUser? getCreator() {
    for (final u in members) {
      if (u.id == creatorId) return u;
    }
    return null;
  }
}