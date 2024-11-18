part of controller;

class BluetoothPermissionCubit extends Cubit<bool> {
  final GetPermission getPermission;
  final SetPermission setPermission;

  BluetoothPermissionCubit({
    required this.getPermission,
    required this.setPermission,
  }) : super(false);

  Future<void> getPermissionStatus() async {
    try {
      final results = await getPermission(NoParams());
      results.fold(
        (failure) {
          emit(false);
        },
        (granted) {
          if (granted) {
            emit(true);
          } else {
            emit(false);
          }
        },
      );
    } catch (e) {
      emit(false);
    }
  }

  Future<void> setPermissionStatus() async {
    await setPermission(NoParams());
  }
}
