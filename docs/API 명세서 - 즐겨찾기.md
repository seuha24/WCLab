# API 명세서 - 즐겨찾기 기능

## 사용자별 즐겨찾기 정보 조회 요청 URL
- **Base URL**: `http://cuksl.xyz:3303/fav_*/$login_method/$ID`

## 즐겨찾기 API

### 1. 즐겨찾기 목록 조회 (지점)
**GET** `/favorites`

#### 요청 유형
```
cuksl.xyz:3306/fav_point/google/userID
```

#### Response
```json
{
  "login_method": "Google",
  "ID": "userID",
  "list": [
    {
      "name": "우리집",
      "lon": 126.8015, //출입구 좌표
      "lat": 37.4859
    },
    {
      "name": "짱구네",
      "lon": 126.8015, //출입구 좌표
      "lat": 37.4859
    }
  ]
}
```

### 2. 즐겨찾기 목록 조회 (경로)
**GET** `/favorites`

#### Request Headers
```
cuksl.xyz:3306/fav_route/google/userID
```

#### Response
```json
{
  "login_method": "Google",
  "ID": "userID",
  "list": [
    {
      "name": "짱구네 가는 길",
      "points": [
        { "lon": 126.8015, "lat": 37.4859 },
        { "lon": 126.8015, "lat": 37.4859 },
        { "lon": 126.8015, "lat": 37.4859 },
        null,
        null
      ]
    },
    {
      "name": "역곡역 가는 길",
      "points": [
        { "lon": 126.8015, "lat": 37.4859 },
        { "lon": 126.8015, "lat": 37.4859 },
        { "lon": 126.8015, "lat": 37.4859 },
        null,
        null
      ]
    }
  ]
}
```

## 에러 응답 형식
잘못된 커리(존재하지 않는 사용자)
```json
{
  "error": "잘못된 접근입니다"
}
```


### 3. 즐겨찾기 정보 등록 (지점)
**POST** `/favorites`

## 사용자별 즐겨찾기 정보 등록 (지점) 요청 URL
- **Base URL**: `http://cuksl.xyz:3303/save/fav/poit`

#### Request Body
```json
{
  "login_method": "Google",
  "ID": "userID",
  "new_fav_point":
    {
      "name": "우리집",
      "lon": 126.8015, //건물 중심점 좌표
      "lat": 37.4859
    }
}
```

#### Response
[성공]
```json
HTTP/1.1 200 OK
Content-Type: application/json
{
  "success": true
  "entrance_point":
    {
      "lon": 126.8015, //출입구 좌표 반환
      "lat": 37.4859
    }
}
```

[파라미터 누락]
```json
HTTP/1.1 400 Bad Request
Content-Type: application/json
{
  "success": false,
  "잘못된 요청입니다"
}
```

[서버 다운 등 서버측 문제 발생]
HTTP/1.1 500 Internal Server Error
Content-Type: application/json




### 4. 즐겨찾기 정보 등록 (경로)
**POST** `/favorites`

## 사용자별 즐겨찾기 정보 등록 (지점) 요청 URL
- **Base URL**: `http://cuksl.xyz:3303/save/fav/route`

#### Request Body
```json
{
  "login_method": "Google",
  "ID": "userID",
  "list":
    {
      "name": "짱구네 가는 길",
      "points": [
        { "lon": 126.8015, "lat": 37.4859 },
        { "lon": 126.8015, "lat": 37.4859 },
        { "lon": 126.8015, "lat": 37.4859 },
        null,
        null
      ]
    }
}
```

[성공]
HTTP/1.1 200 OK
Content-Type: application/
```json
{
  "success": true
}
```

[파라미터누락]
HTTP/1.1 400 Bad Request
Content-Type: application/
```json
{
  "success": false,
  "잘못된 요청입니다."
}
```

[서버 다운 등 서버측 문제 발생]
HTTP/1.1 500 Internal Server Error
Content-Type: application/json


## 에러 코드
- `AUTH_REQUIRED`: 인증이 필요합니다
- `INVALID_TOKEN`: 유효하지 않은 토큰입니다
- `FAVORITE_NOT_FOUND`: 즐겨찾기를 찾을 수 없습니다
- `DUPLICATE_FAVORITE`: 이미 등록된 즐겨찾기입니다
- `MAX_FAVORITES_EXCEEDED`: 최대 즐겨찾기 개수를 초과했습니다

## 참고사항
- 위도/경도는 소수점 6자리까지 저장됩니다
- 최대 즐겨찾기 개수: 10개
- 최대 경유지 개수: 5개