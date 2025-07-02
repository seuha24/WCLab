part of '../../../framework/controller.dart';

/// state: Bloc의 상태를 표현-> UI는 이 상태를 보고 렌더링을 바꿈

abstract class EntranceRegistrationState {}

class RegistrationInitial extends EntranceRegistrationState {}

class RegistrationLoading extends EntranceRegistrationState {}

class RegistrationLoaded extends EntranceRegistrationState {
  final String address;
  final NLatLng selectedLocation;
  RegistrationLoaded({required this.address, required this.selectedLocation});
}

class EntranceSubmissionSuccess extends EntranceRegistrationState {}

class RegistrationFailure extends EntranceRegistrationState {
  final String message;
  RegistrationFailure(this.message);
}