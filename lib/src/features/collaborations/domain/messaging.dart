import 'package:orbit/src/features/auth/domain/AppUser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.text,
    required this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'senderId': senderId,
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: (map['id'] ?? '') as String,
        text: (map['text'] ?? '') as String,
        senderId: (map['senderId'] ?? '') as String,
        senderName: map['senderName'] as String?,
        senderPhotoUrl: map['senderPhotoUrl'] as String?,
        createdAt: (map['createdAt'] is Timestamp)
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.fromMillisecondsSinceEpoch(
                (map['createdAt'] ?? 0) as int,
                isUtc: true,
              ),
      );
}