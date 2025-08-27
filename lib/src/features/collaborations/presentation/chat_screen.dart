import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:orbit/src/features/collaborations/domain/messaging.dart';
import 'package:orbit/src/models/firestore_repository.dart';
import 'package:orbit/theme.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String collaborationId;
  final String? title;
  const ChatScreen({super.key, required this.collaborationId, this.title});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final _repo = FirestoreRepository();
  final _auth = FirebaseAuth.instance;

  final bool _useStream = true;

  List<Message> _messagesOnce = [];
  bool _loading = true;
  bool _sending = false;
  bool _loadingMore = false;
  static const _pageSize = 50;

  @override
  void initState() {
    super.initState();
    if (!_useStream) _loadInitial();

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      // Mark read on open
      FirestoreRepository().markCollabRead(widget.collaborationId, uid);
    }
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    final msgs = await _repo.getCollabMessagesOnce(widget.collaborationId, limit: _pageSize);
    setState(() {
      _messagesOnce = msgs;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _messagesOnce.isEmpty) return;
    setState(() => _loadingMore = true);
    final last = _messagesOnce.last.createdAt; 
    final more = await _repo.getMoreCollabMessages(
      widget.collaborationId,
      limit: _pageSize,
      startBefore: last,
    );
    setState(() {
      _messagesOnce.addAll(more);
      _loadingMore = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _sending = true);

    try {
      final msg = Message(
        id: '',
        text: text,
        senderId: user.uid,
        senderName: user.displayName ?? 'You',
        senderPhotoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
      await _repo.sendCollabMessage(widget.collaborationId, msg);
      _controller.clear();

      // optimistic add for one-time mode
      if (!_useStream) {
        setState(() => _messagesOnce.insert(0, msg));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_useStream) {
      body = StreamBuilder<List<Message>>(
        stream: _repo.collabMessagesStream(widget.collaborationId, limit: _pageSize),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final messages = snap.data ?? const [];
          return _MessageList(
            messages: messages,
            currentUserId: _auth.currentUser?.uid,
            loadMore: null, 
          );
        },
      );
    } else {
      body = _loading
          ? const Center(child: CircularProgressIndicator())
          : _MessageList(
              messages: _messagesOnce,
              currentUserId: _auth.currentUser?.uid,
              loadMore: _loadMore,
              loadingMore: _loadingMore,
            );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(widget.title ?? 'Chat', style: AppTextStyles.header),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: body),
            Padding(
              padding: AppPaddings.input,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: AppDecorations.input,
                      child: TextField(
                        controller: _controller,
                        style: AppTextStyles.body,
                        cursorColor: AppColors.accent,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Type a message...',
                          hintStyle: AppTextStyles.hint,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.zero,
                      ),
                      child: _sending
                          ? const SizedBox(
                              height: 18, width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                            )
                          : const Icon(Icons.send, color: AppColors.white),
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
}

class _MessageList extends StatelessWidget {
  final List<Message> messages; 
  final String? currentUserId;
  final Future<void> Function()? loadMore;
  final bool loadingMore;

  const _MessageList({
    required this.messages,
    required this.currentUserId,
    this.loadMore,
    this.loadingMore = false,
  });


  String _formatTimestamp(DateTime utc) {
  final now = DateTime.now();
  final dt = utc.toLocal();

  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isYesterday(DateTime d, DateTime now) =>
      sameDay(d, now.subtract(const Duration(days: 1)));

  final diff = now.difference(dt);

  if (sameDay(dt, now)) {
    return DateFormat('HH:mm').format(dt);          //today
  } else if (isYesterday(dt, now)) {
    return 'Yesterday';                              //yesterday
  } else if (diff.inDays < 7) {
    return DateFormat('EEEE').format(dt);            //weekday
  } else {
    return DateFormat('d MMM yyyy').format(dt);      // date
  }
}

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (loadMore == null) return false;
        if (n is ScrollEndNotification) {
          final pos = n.metrics;
          if (pos.pixels >= pos.maxScrollExtent - 32) {
            loadMore?.call();
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        reverse: true,
        itemCount: messages.length + (loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (loadingMore && index == messages.length) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final msg = messages[index];
          final isMe = (msg.senderId == currentUserId);

          return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75, // cap at ~75%
            ),
            child: IntrinsicWidth( // 👈 let width follow content up to the cap
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.accent : AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,                 // 👈 don't expand vertically
                  crossAxisAlignment: CrossAxisAlignment.start,   // left-align content
                  children: [
                    if (!isMe && (msg.senderName?.isNotEmpty ?? false)) ...[
                      Text(msg.senderName!, style: AppTextStyles.hint),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      msg.text,
                      style: AppTextStyles.body.copyWith(color: AppColors.white),
                      softWrap: true,
                      maxLines: null, // allow multi-line
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        _formatTimestamp(msg.createdAt),
                        style: AppTextStyles.hint.copyWith(fontSize: 11, color: AppColors.grey800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        },
      ),
    );
  }
}