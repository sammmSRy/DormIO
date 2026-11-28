import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/converters.dart';

class Conversation {
  final String id;
  final List<String> participantIds;
  final String? dormId;
  final String lastMessage;
  final DateTime? lastMessageAt;

  const Conversation({
    required this.id,
    required this.participantIds,
    this.dormId,
    this.lastMessage = '',
    this.lastMessageAt,
  });

  factory Conversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Conversation(
      id: doc.id,
      participantIds: stringList(d['participantIds']),
      dormId: d['dormId'],
      lastMessage: d['lastMessage'] ?? '',
      lastMessageAt: toDate(d['lastMessageAt']),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      text: d['text'] ?? '',
      createdAt: toDate(d['createdAt']),
    );
  }
}
