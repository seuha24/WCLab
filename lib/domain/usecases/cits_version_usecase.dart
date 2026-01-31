part of '../../framework/usecase.dart';

/// C-ITS 버전 관리 UseCase
///
/// API 2-3 버전 동기화 비즈니스 로직
abstract class CitsVersionUseCase {}

/// 서버에서 C-ITS 데이터 버전 조회 UseCase
///
/// 교차로와 음향신호기 버전을 한번에 조회하여 동기화 판단에 사용
///
/// 사용 예시:
/// ```dart
/// final usecase = DI.get<GetCitsVersions>();
/// final result = await usecase(NoParams());
/// result.fold(
///   (failure) => print('버전 조회 실패: ${failure.message}'),
///   (versions) => print('교차로: ${versions.junctionsVersion}, 음향신호기: ${versions.crosswalkVersion}'),
/// );
/// ```
class GetCitsVersions extends CitsVersionUseCase
    implements UseCase<CitsVersion, NoParams> {
  final CitsVersionRepository repository;

  GetCitsVersions({required this.repository});

  @override
  Future<Either<Failure, CitsVersion>> call(NoParams params) async {
    return await repository.getServerVersions();
  }
}
