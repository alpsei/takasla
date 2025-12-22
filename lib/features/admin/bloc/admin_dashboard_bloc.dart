import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitaptakas/data/repositories/admin_repositories.dart';
import 'package:equatable/equatable.dart';

// --- EVENTS ---
abstract class AdminDashboardEvent extends Equatable {
  const AdminDashboardEvent();
  @override
  List<Object> get props => [];
}

class LoadDashboardStats extends AdminDashboardEvent {}

// --- STATES ---
abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();
  @override
  List<Object> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final int userCount;
  final int bookCount;
  final int reportCount;

  const AdminDashboardLoaded({
    required this.userCount,
    required this.bookCount,
    required this.reportCount,
  });

  @override
  List<Object> get props => [userCount, bookCount, reportCount];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  const AdminDashboardError({required this.message});
  @override
  List<Object> get props => [message];
}

// --- BLOC ---
class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final AdminRepository _adminRepository;

  AdminDashboardBloc(this._adminRepository) : super(AdminDashboardInitial()) {
    on<LoadDashboardStats>(_onLoadDashboardStats);
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(AdminDashboardLoading());
    try {
      final stats = await _adminRepository.getDashboardStats();

      emit(
        AdminDashboardLoaded(
          userCount: stats['userCount'] ?? 0,
          bookCount: stats['bookCount'] ?? 0,
          reportCount: stats['reportCount'] ?? 0,
        ),
      );
    } catch (e) {
      try {
        final results = await Future.wait([
          _adminRepository.getUserCount(), // 0
          _adminRepository.getBookCount(), // 1
          _adminRepository.getPendingReports(), // 2
        ]);

        final reportsSnapshot = results[2] as dynamic;
        final reportCount = reportsSnapshot.docs.length;

        emit(
          AdminDashboardLoaded(
            userCount: results[0] as int,
            bookCount: results[1] as int,
            reportCount: reportCount,
          ),
        );
      } catch (innerError) {
        emit(AdminDashboardError(message: e.toString()));
      }
    }
  }
}
