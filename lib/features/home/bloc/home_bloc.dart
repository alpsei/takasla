import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitaptakas/data/repositories/auth_repository.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/repositories/book_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final BookRepository _bookRepository;
  final AuthRepository _authRepository;

  HomeBloc({
    required BookRepository bookRepository,
    required AuthRepository authRepository,
  }) : _bookRepository = bookRepository,
       _authRepository = authRepository,
       super(HomeInitial()) {
    // Kitapları Getir
    on<HomeBooksRequested>((event, emit) async {
      emit(HomeLoading());
      try {
        final books = await _bookRepository.getBooks();
        // İlk açılışta filtreler boş
        emit(HomeSuccess(books: books, allBooks: books));
      } catch (e) {
        emit(HomeFailure(e.toString()));
      }
    });

    // Arama Yap
    on<HomeSearchQueryChanged>((event, emit) async {
      if (state is HomeSuccess) {
        final currentState = state as HomeSuccess;

        // A. Eğer Kullanıcı Arıyorsak (Async)
        if (currentState.isUserSearchMode) {
          // Önce state'i güncelle (yazıyı kaydet)
          emit(currentState.copyWith(activeSearchQuery: event.query));

          if (event.query.trim().isNotEmpty) {
            try {
              // Repo'dan kullanıcı ara
              final users = await _authRepository.searchUsers(event.query);
              // Sonuçları bas
              emit((state as HomeSuccess).copyWith(userResults: users));
            } catch (e) {
              // Hata olursa boş liste dön (veya hata göster)
              print("Kullanıcı arama hatası: $e");
            }
          } else {
            // Yazı boşsa listeyi temizle
            emit((state as HomeSuccess).copyWith(userResults: []));
          }
        }
        // Eğer Kitap Arıyorsak (Sync - Filtreleme)
        else {
          final newState = currentState.copyWith(
            activeSearchQuery: event.query,
          );
          _applyFilters(emit, newState);
        }
      }
    });
    on<HomeSearchModeChanged>((event, emit) {
      if (state is HomeSuccess) {
        final currentState = state as HomeSuccess;

        // Önce geçmek istediğimiz YENİ durumu bir değişkene hazırlayalım
        final targetState = currentState.copyWith(
          isUserSearchMode: event.isUserSearch,
          userResults: [],
          activeSearchQuery: '',
        );

        if (event.isUserSearch) {
          // A. Kullanıcı Moduna geçiyorsak direkt yayınla
          emit(targetState);
        } else {
          // B. Kitap Moduna dönüyorsak
          _applyFilters(emit, targetState);
        }
      }
    });

    // Filtreleme Yap
    on<HomeFilterChanged>((event, emit) {
      final currentState = state;
      if (currentState is HomeSuccess) {
        HomeSuccess newState = currentState;

        if (event.takasTuru != null) {
          newState = newState.copyWith(activeTakasTuru: event.takasTuru);
        }
        if (event.kitapTuru != null) {
          newState = newState.copyWith(activeKitapTuru: event.kitapTuru);
        }
        if (event.konum != null) {
          newState = newState.copyWith(activeKonum: event.konum);
        }

        // Eğer event boş geldiyse (Temizle butonu), her şeyi sıfırla
        if (event.takasTuru == null &&
            event.kitapTuru == null &&
            event.konum == null) {
          newState = HomeSuccess(
            books: currentState.allBooks,
            allBooks: currentState.allBooks,
            activeTakasTuru: null,
            activeKitapTuru: null,
            activeKonum: null,
            activeSearchQuery: null,
          );
        }

        _applyFilters(emit, newState);
      }
    });
  }

  // --- MERKEZİ FİLTRELEME FONKSİYONU ---
  // Tüm filtreleri ve aramayı aynı anda uygular
  void _applyFilters(Emitter<HomeState> emit, HomeSuccess currentState) {
    var filteredList = currentState.allBooks;

    // Arama Filtresi
    if (currentState.activeSearchQuery != null &&
        currentState.activeSearchQuery!.isNotEmpty) {
      final query = currentState.activeSearchQuery!.toLowerCase();
      filteredList = filteredList.where((book) {
        return book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query);
      }).toList();
    }

    // Takas Türü
    if (currentState.activeTakasTuru != null) {
      final type = currentState.activeTakasTuru;
      if (type == 'Bağış')
        filteredList = filteredList.where((b) => b.isDonation).toList();
      if (type == 'Takas')
        filteredList = filteredList.where((b) => b.isSwap).toList();
      if (type == 'Ödünç')
        filteredList = filteredList.where((b) => b.isLoan).toList();
    }

    // Kitap Türü (Kategori)
    if (currentState.activeKitapTuru != null) {
      final cat = currentState.activeKitapTuru!;
      final subCategories = AppConstants.getSubCategories(cat);

      if (subCategories.isNotEmpty) {
        filteredList = filteredList
            .where((b) => subCategories.contains(b.category))
            .toList();
      } else {
        filteredList = filteredList.where((b) => b.category == cat).toList();
      }
    }

    // Konum
    if (currentState.activeKonum != null) {
      filteredList = filteredList
          .where((b) => b.location.contains(currentState.activeKonum!))
          .toList();
    }

    // Yeni listeyi yayınla
    emit(currentState.copyWith(books: filteredList));
  }
}
