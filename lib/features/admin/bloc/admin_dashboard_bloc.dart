import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitaptakas/data/repositories/admin_repositories.dart';

// --- Events ---
abstract class AdminDashboardEvent {}

class LoadDashboardStats extends AdminDashboardEvent {}

// --- States ---
abstract class AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final int userCount;
  final int bookCount;
  final int reportCount;

  AdminDashboardLoaded({
    required this.userCount,
    required this.bookCount,
    required this.reportCount,
  });
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  AdminDashboardError(this.message);
}

// --- Bloc ---
class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final AdminRepository _adminRepository;

  AdminDashboardBloc(this._adminRepository) : super(AdminDashboardLoading()) {
    on<LoadDashboardStats>((event, emit) async {
      emit(AdminDashboardLoading());
      try {
        final results = await Future.wait([
          _adminRepository.getUserCount(),
          _adminRepository.getBookCount(),
        ]);

        emit(
          AdminDashboardLoaded(
            userCount: results[0],
            bookCount: results[1],
            reportCount: results[2],
          ),
        );
      } catch (e) {
        emit(AdminDashboardError("İstatistikler alınamadı: $e"));
      }
    });
  }
}
