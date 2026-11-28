import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/db_exception.dart';
import '../core/firestore_paths.dart';
import '../models/message.dart';

/// conversations/{conversationId}
///   messages/{messageId}      <- sub-collection
/// conversationId is deterministic, so two people always share ONE chat.
class MessageRepository {
  MessageRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.conversations);

  /// conversationId('b','a') == conversationId('a','b') == 'a_b'
  static String conversationId(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return ids.join('_');
  }

  /// Opens the chat with another user (e.g. the "Message host" button).
  Future<String> getOrCreateConversation(String myUid, String otherUid,
      {String? dormId}) async {
    if (myUid == otherUid) throw DbException('You cannot message yourself');
    final id = conversationId(myUid, otherUid);
    final ref = _col.doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participantIds': [myUid, otherUid],
        'dormId': dormId,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return id;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) throw DbException('Message cannot be empty');
    if (clean.length > 1000) throw DbException('Message is too long (max 1000)');

    final convRef = _col.doc(conversationId);
    final msgRef = convRef.collection(FirestorePaths.messages).doc();
    final batch = _db.batch();
    batch.set(msgRef, {
      'senderId': senderId,
      'text': clean,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(convRef, {
      'lastMessage': clean.length > 120 ? clean.substring(0, 120) : clean,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId,
          {int limit = 100}) =>
      _col
          .doc(conversationId)
          .collection(FirestorePaths.messages)
          .orderBy('createdAt')
          .limitToLast(limit)
          .snapshots()
          .map((s) => s.docs.map(ChatMessage.fromDoc).toList());

  /// Inbox: newest conversation first.
  Stream<List<Conversation>> watchConversations(String uid) => _col
      .where('participantIds', arrayContains: uid)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Conversation.fromDoc).toList());
}
