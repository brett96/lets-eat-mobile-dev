import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message in a group chat.
///
/// Replaces the legacy approach of storing `"name:    text"` strings in a
/// `Messages` array on the group document, which couldn't scale, sort, or
/// attribute messages reliably.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.text,
    this.sentAt,
  });

  final String id;
  final String senderUid;
  final String senderName;
  final String text;
  final DateTime? sentAt;

  factory ChatMessage.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return ChatMessage(
      id: doc.id,
      senderUid: data['senderUid'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Unknown',
      text: data['text'] as String? ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderUid': senderUid,
        'senderName': senderName,
        'text': text,
        'sentAt': FieldValue.serverTimestamp(),
      };
}
