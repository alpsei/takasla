import 'package:equatable/equatable.dart';
import 'package:kitaptakas/data/models/request_model.dart';
import 'package:kitaptakas/features/requests/bloc/request_state.dart';

abstract class RequestState extends Equatable {
  const RequestState();
  @override
  List<Object> get props => [];
}

class RequestInitial extends RequestState {}

class RequestLoading extends RequestState {}

class RequestActionSuccess extends RequestState {}

class RequestFailure extends RequestState {
  final String error;
  const RequestFailure(this.error);
}

class RequestStatusLoaded extends RequestState {
  final bool hasRequest; // Daha önce talep atılmış mı?

  const RequestStatusLoaded(this.hasRequest);

  @override
  List<Object> get props => [hasRequest];
}
