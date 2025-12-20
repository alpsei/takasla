import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;

  ChatBloc({required ChatRepository chatRepository})
    : _chatRepository = chatRepository,
      super(ChatInitial()) {
    on<ChatSendMessage>((event, emit) async {
      // Mesaj boşsa gönderme
      if (event.content.trim().isEmpty) return;

      emit(ChatSending());
      try {
        await _chatRepository.sendMessage(
          requestId: event.requestId,
          senderId: event.senderId,
          content: event.content,
        );
        emit(ChatSentSuccess());
        emit(ChatInitial()); // Tekrar başa dön ki yeni mesaj yazılabilsin
      } catch (e) {
        emit(ChatFailure(e.toString()));
      }
    });
  }
}
