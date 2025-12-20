import 'package:equatable/equatable.dart';
import 'package:kitaptakas/features/book_detail/bloc/request_state.dart';
import '../../../../data/models/request_model.dart';

abstract class RequestsState extends Equatable {
  const RequestsState();
  @override
  List<Object> get props => [];
}

class RequestsInitial extends RequestsState {}

class RequestsLoading extends RequestsState {}

class RequestsSuccess extends RequestsState {
  final List<RequestModel> requests;
  const RequestsSuccess(this.requests);
  @override
  List<Object> get props => [requests];
}

class RequestActionSuccess extends RequestState {}

class RequestsFailure extends RequestsState {
  final String error;
  const RequestsFailure(this.error);
}

class RequestsReviewSuccess extends RequestsState {}

class RequestStatusLoaded extends RequestState {
  final bool hasRequest;

  const RequestStatusLoaded(this.hasRequest);

  @override
  List<Object> get props => [hasRequest];
}
