import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // MESAJ GÖNDER
  Future<void> sendMessage({
    required String requestId,
    required String senderId,
    required String content,
  }) async {
    try {
      final messageId = const Uuid().v4();
      final message = MessageModel(
        id: messageId,
        senderId: senderId,
        content: content,
        timestamp: DateTime.now(),
      );

      // 'requests' -> 'requestId' -> 'messages'
      await _firestore
          .collection('requests')
          .doc(requestId)
          .collection('messages')
          .doc(messageId)
          .set(message.toJson());
    } catch (e) {
      throw Exception("Mesaj gönderilemedi: $e");
    }
  }

  // MESAJLARI CANLI DİNLE (Stream)
  Stream<List<MessageModel>> getMessages(String requestId) {
    return _firestore
        .collection('requests')
        .doc(requestId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Eskiden yeniye
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromJson(doc.data()))
              .toList();
        });
  }
}
