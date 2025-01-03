// part of '../../../framework/bloc.dart';
//
// class AccelerometerBloc extends Bloc<AccelerometerEvent, AccelerometerState> {
//   late final StreamSubscription<UserAccelerometerEvent> _subscription;
//   final NavigationService navigationService;
//
//   bool isAccRunning = false;
//
//   AccelerometerBloc({required this.navigationService})
//       : super(AccelerometerInitial()) {
//     _subscription = userAccelerometerEventStream().listen((event) {
//       add(AccelerometerDataReceived(x: event.x, y: event.y, z: event.z));
//     });
//
//     on<AccelerometerDataReceived>(_onDataReceived);
//   }
//
//   void _onDataReceived(
//       AccelerometerDataReceived event, Emitter<AccelerometerState> emit) async {
//     final double magnitude =
//     math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
//
//     if (magnitude > 1.0 && magnitude < 10.0 && !isAccRunning) {
//       isAccRunning = true;
//
//       try {
//         // 현재 위치 확인
//         Position position = await Geolocator.getCurrentPosition(
//           locationSettings: const LocationSettings(
//             accuracy: LocationAccuracy.high,
//             distanceFilter: 5,
//           ),
//         );
//
//         if (position.accuracy <= 14) {
//           // GPS 정확도가 기준 이하일 때 NavigationService 호출
//           await navigationService.moveByGps();
//         } else {
//           // GPS 정확도가 낮을 때 NavigationService 호출
//           await navigationService.moveByImu();
//         }
//
//         emit(AccelerometerMoving(
//           x: event.x,
//           y: event.y,
//           z: event.z,
//           isMoving: true,
//         ));
//       } catch (e) {
//         emit(AccelerometerError("Error while processing accelerometer data: $e"));
//       } finally {
//         isAccRunning = false;
//       }
//     } else {
//       emit(AccelerometerStationary(
//         x: event.x,
//         y: event.y,
//         z: event.z,
//         isMoving: false,
//       ));
//     }
//   }
//
//   @override
//   Future<void> close() {
//     _subscription.cancel();
//     return super.close();
//   }
// }