/// 한국어 조사 처리 유틸리티
///
/// 받침 유무에 따라 적절한 조사를 반환합니다.
///
/// **사용 예시:**
/// ```dart
/// final name = '스타벅스';
/// final particle = KoreanParticle.subjectParticle(name); // '가'
/// print('$name$particle 있습니다'); // '스타벅스가 있습니다'
/// ```
abstract class KoreanParticle {
  /// 받침 유무에 따라 "이/가" 반환
  ///
  /// - 받침 있음: "이" (예: 횡단보도**이**)
  /// - 받침 없음: "가" (예: 스타벅스**가**)
  static String subjectParticle(String word) {
    return _hasFinalConsonant(word) ? '이' : '가';
  }

  /// 받침 유무에 따라 "을/를" 반환
  ///
  /// - 받침 있음: "을" (예: 횡단보도**을**)
  /// - 받침 없음: "를" (예: 스타벅스**를**)
  static String objectParticle(String word) {
    return _hasFinalConsonant(word) ? '을' : '를';
  }

  /// 받침 유무에 따라 "은/는" 반환
  ///
  /// - 받침 있음: "은" (예: 횡단보도**은**)
  /// - 받침 없음: "는" (예: 스타벅스**는**)
  static String topicParticle(String word) {
    return _hasFinalConsonant(word) ? '은' : '는';
  }

  /// 받침 유무에 따라 "과/와" 반환
  ///
  /// - 받침 있음: "과" (예: 횡단보도**과**)
  /// - 받침 없음: "와" (예: 스타벅스**와**)
  static String andParticle(String word) {
    return _hasFinalConsonant(word) ? '과' : '와';
  }

  /// 마지막 글자에 받침이 있는지 확인
  ///
  /// 한글 유니코드 범위: 0xAC00 ~ 0xD7A3 (가 ~ 힣)
  /// 각 글자는 (초성 * 21 + 중성) * 28 + 종성 으로 구성
  /// 종성이 0이면 받침 없음
  static bool _hasFinalConsonant(String word) {
    if (word.isEmpty) return false;

    final lastChar = word.codeUnitAt(word.length - 1);

    // 한글 유니코드 범위 확인
    if (lastChar < 0xAC00 || lastChar > 0xD7A3) {
      // 한글이 아니면 받침 없음으로 처리 (영어, 숫자 등)
      return false;
    }

    // 받침 확인: (charCode - 0xAC00) % 28 != 0 이면 받침 있음
    return (lastChar - 0xAC00) % 28 != 0;
  }
}
