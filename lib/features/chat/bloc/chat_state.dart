import 'package:equatable/equatable.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatSending extends ChatState {} // Mesaj gidiyor...

class ChatSentSuccess extends ChatState {} // Gitti!

class ChatFailure extends ChatState {
  final String error;
  const ChatFailure(this.error);
}
