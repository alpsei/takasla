import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object> get props => [];
}

class ProfileLoadUserBooks extends ProfileEvent {
  final String userId;
  const ProfileLoadUserBooks(this.userId);
}
