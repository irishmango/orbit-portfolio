import 'package:flutter/material.dart';
import 'package:orbit/src/features/auth/domain/AppUser.dart';
import 'package:orbit/src/features/collaborations/domain/collaboration.dart';
import 'package:orbit/src/features/home/shared/member_avatar_circle.dart';
import 'package:orbit/theme.dart';


class CollabCard extends StatefulWidget {
  final Collaboration collaboration;

  const CollabCard({
    super.key,
    required this.collaboration,
  });

  @override
  State<CollabCard> createState() => _CollabCardState();
}

class _CollabCardState extends State<CollabCard> {
  bool _loadingMembers = true;
  List<String> _memberNames = [];               // avatar labels in memberIds order
  Map<String, String> _memberDisplayById = {};  // id -> display (not used visibly here but kept consistent)
  Map<String, String?> _memberPhotoById = {};
  
  // Same initials logic as the collab screen
  String _initials(String input) {
    final s = input.trim();
    if (s.isEmpty) return '?';

    if (s.contains('@')) {
      final parts = s.split('@');
      final local = parts.first.trim();
      final domain = parts.length > 1 ? parts[1].trim() : '';
      final a = local.isNotEmpty ? local[0] : '';
      final b = domain.isNotEmpty ? domain[0] : '';
      final res = (a + b).toUpperCase();
      return res.isEmpty ? '?' : res;
    }

    final words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final w = words.first;
      return (w.length >= 2 ? w.substring(0, 2) : w[0]).toUpperCase();
    }
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  Future<void> _loadMembers() async {
    try {
      final ids = List<String>.from(widget.collaboration.memberIds);
      final List<dynamic> memberObjs =
          List<dynamic>.from(widget.collaboration.members ?? const []);

      final Map<String, String> displayById = {};
      final Map<String, String?> photoById = {};

      for (final m in memberObjs) {
        if (m == null) continue;

        String id = '';
        String? name;
        String? email;
        String? photoUrl;

        if (m is Map) {
          final map = Map<String, dynamic>.from(m);
          id = (map['id'] as String?) ?? '';
          name = map['name'] as String?;
          email = map['email'] as String?;
          photoUrl = map['photoUrl'] as String?;
        } else if (m is AppUser) {
          id = m.id;
          name = m.name;
          email = m.email;
          photoUrl = m.photoUrl;
        } else {
          continue;
        }

        if (id.isEmpty) continue;

        final display = (name != null && name.trim().isNotEmpty)
            ? name.trim()
            : (email != null && email.trim().isNotEmpty)
                ? email.trim()
                : 'Member';

        displayById[id] = display;
        photoById[id] = (photoUrl != null && photoUrl.trim().isNotEmpty)
            ? photoUrl.trim()
            : null;
      }

      for (final id in ids) {
        displayById[id] ??= 'Member';
        photoById[id] ??= null;
      }

      final orderedNames = ids.map((id) => displayById[id]!).toList();

      setState(() {
        _memberDisplayById = displayById;
        _memberPhotoById = photoById;
        _memberNames = orderedNames;
        _loadingMembers = false;
      });
    } catch (_) {
      setState(() {
        _memberDisplayById = {
          for (final id in widget.collaboration.memberIds) id: 'Member'
        };
        _memberPhotoById = {
          for (final id in widget.collaboration.memberIds) id: null
        };
        _memberNames =
            List<String>.filled(widget.collaboration.memberIds.length, 'Member');
        _loadingMembers = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      height: 160,
      decoration: AppDecorations.card.copyWith(
        border: Border.all(
          color: const Color.fromARGB(255, 86, 77, 77),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.collaboration.title,
            style: AppTextStyles.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Member avatars (overlapped) — initials computed exactly like screen
          SizedBox(
            height: 28,
            child: _loadingMembers
                ? const SizedBox.shrink()
                : Stack(
                    clipBehavior: Clip.none,
                    children: List.generate(_memberNames.length, (i) {
                      final id = widget.collaboration.memberIds[i];
                      return Positioned(
                        left: i * 20.0, // was 18.0; 28px avatar - 4px overlap
                        child: AvatarCircle(
                          initials: _initials(_memberNames[i]),
                          image: _memberPhotoById[id],
                        ),
                      );
                    }),
                  ),
          ),

          const SizedBox(height: 12),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              widget.collaboration.description,
              style: TextStyle(color: Colors.grey[300]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}