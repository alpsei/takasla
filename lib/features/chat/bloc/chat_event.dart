import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object> get props => [];
}

// Mesaj Gönderildiğinde
class ChatSendMessage extends ChatEvent {
  final String requestId;
  final String senderId;
  final String content;

  const ChatSendMessage({
    required this.requestId,
    required this.senderId,
    required this.content,
  });
}
