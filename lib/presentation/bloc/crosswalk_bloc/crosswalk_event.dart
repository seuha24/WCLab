part of '../../../framework/controller.dart';

abstract class CrosswalkEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchFiniteCrosswalkEvent extends CrosswalkEvent {}

class SearchInfiniteCrosswalkEvent extends CrosswalkEvent {}

/// 스캔 중단 이벤트 - 초기 화면으로 돌아감
class StopScanEvent extends CrosswalkEvent {}

class SendAcousticSignalEvent extends CrosswalkEvent {
  final Crosswalk crosswalk;

  SendAcousticSignalEvent({required this.crosswalk});
}

class SendVoiceInductorEvent extends CrosswalkEvent {
  final Crosswalk crosswalk;

  SendVoiceInductorEvent({required this.crosswalk});
}

class SendVoiceGuideEvent extends CrosswalkEvent {
  final Crosswalk crosswalk;

  SendVoiceGuideEvent({required this.crosswalk});
}
