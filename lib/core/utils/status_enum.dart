enum Status { initial, inProgress, success, failure }

extension StatusX on Status {
  bool get isInitial => this == Status.initial;
  bool get isInProgress => this == Status.inProgress;
  bool get isSuccess => this == Status.success;
  bool get isFailure => this == Status.failure;
}