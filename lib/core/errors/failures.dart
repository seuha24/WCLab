part of core;

abstract class Failure extends Equatable {
  @override
  List<Object?> get props => [];
}

class ServerFailure extends Failure {}

class CacheFailure extends Failure {}

class BlueFailure extends Failure {}

class PermissionFailure extends Failure {}

class FlashFailure extends Failure {}

class ValidateFailure extends Failure {}
