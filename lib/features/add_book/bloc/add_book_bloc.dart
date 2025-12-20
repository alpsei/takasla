import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/book_repository.dart';
import 'add_book_event.dart';
import 'add_book_state.dart';

class AddBookBloc extends Bloc<AddBookEvent, AddBookState> {
  final BookRepository _bookRepository;

  AddBookBloc({required BookRepository bookRepository})
    : _bookRepository = bookRepository,
      super(AddBookInitial()) {
    // Olay geldiğinde ne yapacağını tanımla:
    on<AddBookSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    AddBookSubmitted event,
    Emitter<AddBookState> emit,
  ) async {
    emit(AddBookLoading());

    try {
      final currentUserId =
          FirebaseAuth.instance.currentUser?.uid ?? "anonim_kullanici";
      await _bookRepository.addBook(
        title: event.title,
        author: event.author,
        category: event.category,
        condition: event.condition,
        ownerId: currentUserId,
        location: event.location,
        imageFile: event.imageFile,
        isDonation: event.isDonation,
        isSwap: event.isSwap,
        isLoan: event.isLoan,
        pdfFile: event.pdfFile,
      );

      // 3. Başarılı durumuna geç
      emit(AddBookSuccess());
    } catch (e) {
      // 4. Hata durumuna geç
      emit(AddBookFailure(e.toString()));
    }
  }
}
