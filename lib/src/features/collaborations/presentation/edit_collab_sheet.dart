import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:orbit/src/features/collaborations/domain/collaboration.dart';
import 'package:orbit/src/features/home/shared/member_avatar_circle.dart';
import 'package:orbit/theme.dart';

class EditCollab {
  final String title;
  final String description;
  final bool delete;

  EditCollab({
    required this.title,
    required this.description,
    this.delete = false,
  });
}

class EditCollabSheet extends StatefulWidget {
  final Collaboration collaboration;

  const EditCollabSheet({super.key, required this.collaboration});

  @override
  State<EditCollabSheet> createState() => _EditCollabSheetState();
}

class _EditCollabSheetState extends State<EditCollabSheet> {
  late final TextEditingController titleCtrl;
  late final TextEditingController descCtrl;

  Map<String, String> _displayById = {};
  List<String> _membersExcludingAdmin = [];

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.collaboration.title);
    descCtrl = TextEditingController(text: widget.collaboration.description);
    _membersExcludingAdmin = widget.collaboration.memberIds
        .where((id) => id != widget.collaboration.creatorId)
        .toList();
    _loadMembers();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

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
    // No Firestore read; use the embedded members array from this collaboration
    final ids = List<String>.from(widget.collaboration.memberIds);
    final Map<String, String> display = {};

    try {
      final memberObjs = widget.collaboration.members; // e.g., List<AppUser> or raw List<Map>

      if (memberObjs is List) {
        for (final m in memberObjs) {
          if (m == null) continue;

          String id;
          String? name;
          String? email;

          if (m is dynamic && m is! Map) {
            // Likely your AppUser
            id = (m.id as String);
            name = (m.name as String?);
            email = (m.email as String?);
          } else {
            final map = Map<String, dynamic>.from(m as Map);
            id = (map['id'] as String?) ?? '';
            name = (map['name'] as String?);
            email = (map['email'] as String?);
          }

          if (id.isEmpty) continue;

          display[id] = (name != null && name.trim().isNotEmpty)
              ? name.trim()
              : (email != null && email.trim().isNotEmpty)
                  ? email.trim()
                  : 'Member';
        }
      }

      // Ensure every id has some label (never show UID)
      for (final id in ids) {
        display[id] ??= 'Member';
      }

      setState(() => _displayById = display);
    } catch (e) {
      setState(() {
        _displayById = { for (final id in ids) id: 'Member' };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final height = MediaQuery.of(context).size.height * 2 / 3;

    final adminId = widget.collaboration.creatorId;
    final adminDisplay = _displayById[adminId] ?? 'Member';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: AppDecorations.card.copyWith(
            color: AppColors.background,
            border: Border.all(color: AppColors.card, width: 1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white54,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Edit collaboration', style: AppTextStyles.title),
              const SizedBox(height: 12),

              Container(
                decoration: AppDecorations.input,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: titleCtrl,
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    hintStyle: AppTextStyles.hint,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                height: 120,
                decoration: AppDecorations.input,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: TextField(
                  controller: descCtrl,
                  maxLines: null,
                  expands: true,
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    hintText: 'Description',
                    hintStyle: AppTextStyles.hint,
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text("Admin:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    AvatarCircle(initials: _initials(adminDisplay)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(adminDisplay, style: AppTextStyles.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const Text("Members:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),

              Expanded(
                child: _membersExcludingAdmin.isEmpty
                    ? const Text('No other members', style: TextStyle(color: Colors.white70))
                    : ListView.separated(
                        itemCount: _membersExcludingAdmin.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final uid = _membersExcludingAdmin[index];
                          final display = _displayById[uid] ?? 'Member';

                          return Dismissible(
                            key: Key('member_$uid'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.remove_circle_outline, color: AppColors.white),
                            ),
                            onDismissed: (_) {
                              setState(() {
                                _membersExcludingAdmin.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.white54, width: 1),
                              ),
                              child: Row(
                                children: [
                                  AvatarCircle(initials: _initials(display)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(display, style: AppTextStyles.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title can’t be empty')),
                    );
                    return;
                  }
                  Navigator.pop(context, EditCollab(title: titleCtrl.text, description: descCtrl.text));
                },
                child: const Text('Save changes'),
              ),
              const SizedBox(height: 12),

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context, EditCollab(title: titleCtrl.text, description: descCtrl.text, delete: true));
                },
                child: const Text('Delete collaboration'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}