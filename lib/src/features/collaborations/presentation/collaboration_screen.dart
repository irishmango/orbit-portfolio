import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:orbit/src/features/collaborations/domain/collaboration.dart';
import 'package:orbit/src/features/collaborations/presentation/chat_screen.dart';
import 'package:orbit/src/features/collaborations/presentation/create_collab_project_screen.dart';
import 'package:orbit/src/features/collaborations/presentation/edit_collab_sheet.dart';
import 'package:orbit/src/features/home/shared/member_avatar_circle.dart';
import 'package:orbit/src/features/projects/domain/project.dart';
import 'package:orbit/src/models/firestore_repository.dart';
import 'package:orbit/theme.dart';

class CollaborationScreen extends StatefulWidget {
  final Collaboration collaboration;

  const CollaborationScreen({
    super.key,
    required this.collaboration,
  });

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {
  final _repo = FirestoreRepository();
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  // keep a local copy we can update after edits
  late Collaboration _collab;

  // members (display names/emails) for initials
  List<String> _memberNames = [];

  // (kept for future use if you want admin/member mapping on this screen)
  Map<String, String> _memberDisplayById = {};

  // projects (one-time load)
  bool _loading = true;
  String? _error;
  late List<Project> projectList;

  @override
  void initState() {
    super.initState();
    _collab = widget.collaboration;
    projectList = <Project>[];
    _loadMembers();
    _loadProjects();
  }

  // ===== members =====

  String _initials(String input) {
    final s = input.trim();
    if (s.isEmpty) return '?';

    if (s.contains('@')) {
      // email → local + domain initials
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
    // Use members embedded on the collab doc instead of querying /users
    try {
      // If your Collaboration model already parses `members` into objects,
      // use that. Otherwise, read from the raw map list on the instance.
      final memberObjs = _collab.members; // e.g., List<AppUser> or List<dynamic>

      // Build display map (id -> displayName/email/'Member')
      final Map<String, String> displayById = {};

      if (memberObjs is List) {
        for (final m in memberObjs) {
          if (m == null) continue;

          // Support either a typed object (AppUser) or a raw Map
          String id;
          String? name;
          String? email;

          if (m is dynamic && m is! Map) {
            // Likely your AppUser class
            // Adjust property names to your AppUser
            id = (m.id as String);
            name = (m.name as String?);
            email = (m.email as String?);
          } else {
            final map = Map<String, dynamic>.from(m as Map);
            id = (map['id'] as String?) ?? '';
            name = (map['name'] as String?);
            email = (map['email'] as String?);
          }

          final display = (name != null && name.trim().isNotEmpty)
              ? name.trim()
              : (email != null && email.trim().isNotEmpty)
                  ? email.trim()
                  : 'Member';

          if (id.isNotEmpty) {
            displayById[id] = display;
          }
        }
      }

      // Preserve original order from memberIds (for avatar row)
      final ids = List<String>.from(_collab.memberIds);
      final ordered = ids.map((id) => displayById[id] ?? 'Member').toList();

      setState(() {
        _memberDisplayById = displayById;
        _memberNames = ordered;
      });
    } catch (e) {
      // Fallback: show generic labels, never UIDs
      setState(() {
        _memberDisplayById = { for (final id in _collab.memberIds) id: 'Member' };
        _memberNames = List<String>.filled(_collab.memberIds.length, 'Member');
      });
    }
  }

  // ===== projects =====

  Future<void> _loadProjects() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('collaborations')
          .doc(_collab.id)
          .collection('collabProjects')
          .orderBy('createdAt', descending: true)
          .get();

      final projects = snap.docs
          .map((d) => Project.fromMap({'id': d.id, ...d.data()}))
          .toList();

      setState(() {
        projectList = projects;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load projects';
        _loading = false;
      });
    }
  }

  // ===== edit collab sheet =====

  Future<void> _openEditCollab() async {
    final result = await showModalBottomSheet<EditCollab>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EditCollabSheet(collaboration: _collab),
    );

    if (result == null) return;

    // Delete flow
    if (result.delete) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text('Delete collaboration', style: AppTextStyles.body),
          content: const Text(
            'This will delete the collaboration and all its projects/tasks.',
            style: AppTextStyles.hint,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: AppTextStyles.hint),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.red)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await _repo.deleteCollaboration(uid, _collab.id); // cleans nested data
        } else {
          await FirebaseFirestore.instance.collection('collaborations').doc(_collab.id).delete();
        }
        if (mounted) Navigator.pop(context);
      }
      return;
    }

    // Update title/description
    final newTitle = result.title.trim();
    final newDesc = result.description.trim();

    await FirebaseFirestore.instance
        .collection('collaborations')
        .doc(_collab.id)
        .update({
      'title': newTitle,
      'description': newDesc,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() {
      _collab = Collaboration(
        id: _collab.id,
        title: newTitle,
        description: newDesc,
        members: _collab.members,
        memberIds: _collab.memberIds,
        creatorId: _collab.creatorId,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Collaboration updated')),
    );
  }

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: null,
        actions: [
          if (_uid != null)
            StreamBuilder<bool>(
              stream: _repo.hasUnreadCollabMessages(_collab.id, _uid!),
              builder: (context, snap) {
                final hasUnread = snap.data == true;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: hasUnread
                            ? const Color.fromRGBO(28, 125, 28, 1)
                            : AppColors.white,
                      ),
                      onPressed: () async {
                        await _repo.markCollabRead(_collab.id, _uid!);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              title: _collab.title,
                              collaborationId: _collab.id,
                            ),
                          ),
                        );
                        await _repo.markCollabRead(_collab.id, _uid!);
                      },
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(28, 125, 28, 1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row + edit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _collab.title,
                        style: AppTextStyles.header,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.white),
                      onPressed: _openEditCollab,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Members (avatar initials from displayName/email/'Member')
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final name in _memberNames)
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: AvatarCircle(initials: _initials(name)),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Description
                const Text(
                  "Description:",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 60,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _collab.description,
                          style: AppTextStyles.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Projects
                const Text(
                  "Projects:",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),

                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Center(
                    child: Column(
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadProjects,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (projectList.isEmpty)
                  const Center(
                    child: Text(
                      'No projects yet',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: projectList.length,
                    itemBuilder: (context, index) {
                      final project = projectList[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.white54, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // title + menu
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    project.title,
                                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: PopupMenuButton<String>(
                                      color: AppColors.card,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 18,
                                      icon: const Icon(Icons.more_vert, color: AppColors.white, size: 18),
                                      onSelected: (value) async {
                                        if (value == 'delete') {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: AppColors.background,
                                              title: const Text('Delete Project', style: AppTextStyles.body),
                                              content: const Text(
                                                'Are you sure you want to delete this project?',
                                                style: AppTextStyles.hint,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text('Cancel', style: AppTextStyles.hint),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  child: const Text('Delete', style: TextStyle(color: AppColors.red)),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            final removed = projectList.removeAt(index);
                                            setState(() {}); // reflect immediately
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('collaborations')
                                                  .doc(_collab.id)
                                                  .collection('collabProjects')
                                                  .doc(removed.id)
                                                  .delete();
                                            } catch (e) {
                                              // rollback
                                              projectList.insert(index, removed);
                                              setState(() {});
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Delete failed')),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: AppColors.white),
                                              SizedBox(width: 8),
                                              Text('Delete', style: AppTextStyles.body),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // description
                            Expanded(
                              child: Text(
                                project.description ?? '',
                                style: AppTextStyles.body.copyWith(color: AppColors.white54, fontSize: 14),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromRGBO(28, 125, 28, 1),
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateCollabProjectScreen(collaborationId: _collab.id),
            ),
          );
          if (result != null && result is Project) {
            setState(() {
              projectList.insert(0, result);
            });
          } else {
            // ensure list is fresh if user backed out after creating
            await _loadProjects();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}