# 서버측 클래스 매뉴얼

검색 API(`lib/search.php`)의 구조와, 자체 PHP 프로그램에서 Postcodify 검색 기능을 직접 호출하는 방법입니다.
원래 poesis.dev의 "서버측 클래스 매뉴얼" 페이지에 있던 내용이지만 원본을 구할 수 없어,
현재 `lib/` 코드(버전 3.5.1)를 분석하여 새로 작성했습니다.

## 구성

| 클래스 | 파일 | 역할 |
|---|---|---|
| `Postcodify_Server` | [classes/server.php](../lib/classes/server.php) | 검색 진입점. 검색어 분석, 캐시 확인, DB 검색, 결과 포맷 |
| `Postcodify_Server_Query` | [classes/server/query.php](../lib/classes/server/query.php) | 검색어를 시도·시군구·도로명·동리·번호·건물명 등으로 분석 |
| `Postcodify_Server_Database` | [classes/server/database.php](../lib/classes/server/database.php) | DB 연결 및 쿼리 실행 (PDO MySQL/SQLite, mysqli, mysql) |
| `Postcodify_Server_Cache` | [classes/server/cache.php](../lib/classes/server/cache.php) | Memcached/Redis 결과 캐시 |
| `Postcodify_Server_Areas` | [classes/server/areas.php](../lib/classes/server/areas.php) | 시도·시군구·일반구 목록 (검색어 분석용) |
| `Postcodify_Server_Result` | [classes/server/result.php](../lib/classes/server/result.php) | 검색 결과 객체 |
| `Postcodify_Server_Record_v3` 외 | [classes/server/result.php](../lib/classes/server/result.php) | 주소 한 건. 클라이언트 버전별로 형식이 다름 |
| `Postcodify_Client` | [classes/client.php](../lib/classes/client.php) | 원격 Postcodify API를 호출하는 PHP 클라이언트 |

클래스는 [autoload.php](../lib/autoload.php)가 자동으로 불러옵니다. `Postcodify_Server_Query`는 `classes/server/query.php`처럼
클래스 이름이 파일 경로에 대응합니다. 단, `Postcodify_Server_Record*` 클래스들은 `result.php`에 함께 들어 있으므로
`Postcodify_Server_Result`가 먼저 로딩된 뒤에 쓸 수 있습니다. (`search()`를 거치면 자동으로 해결됩니다.)

## 검색 API (search.php)

웹서버에서 `lib/search.php`를 호출하면 JSON 또는 JSONP로 결과를 반환합니다. 설정은 `lib/config.php`에서 읽습니다.

| 파라미터 | 설명 |
|---|---|
| `q` | 검색어 (UTF-8) |
| `callback` | JSONP 콜백 함수명. 영문·숫자·`_`·`.` 외의 문자가 있으면 무시하고 JSON으로 반환 |
| `v` | 클라이언트 버전. 결과 레코드 형식을 정함 (생략시 서버 버전, 아래 참조) |
| `exact` | `Y`이면 번호까지 정확히 일치하는 결과가 하나뿐일 때 그 하나만 반환 (`JUSO+NUMS`, `JIBEON+NUMS` 검색에만 적용) |

```
GET /lib/search.php?q=세종대로+110&callback=cb
```

터미널에서도 실행할 수 있으며, 이 경우 보기 좋게 정렬된 JSON을 출력합니다.

```sh
php lib/search.php "세종대로 110"
```

## 직접 호출하기

```php
require '/path/to/postcodify/lib/autoload.php';   // lib/config.php도 함께 로딩됨

$server = new Postcodify_Server;
$server->db_driver = 'mysql';          // 'mysql' 또는 'sqlite'
$server->db_host = 'localhost';
$server->db_port = 3306;
$server->db_user = '아이디';
$server->db_pass = '암호';
$server->db_dbname = 'DB이름';         // sqlite인 경우 파일 경로

$result = $server->search('서울 세종대로 110');

if ($result->error === '')
{
    foreach ($result->results as $record)
    {
        echo $record->postcode5 . ' ' . $record->ko_common . ' ' . $record->ko_doro . PHP_EOL;
    }
}
```

`autoload.php`는 `lib/config.php`를 반드시 불러오므로, 설정 파일이 있어야 합니다.
`search.php`처럼 `POSTCODIFY_DB_*` 상수를 그대로 속성에 넣어 써도 됩니다.

### Postcodify_Server

#### 속성

| 속성 | 기본값 | 설명 |
|---|---|---|
| `db_driver` | `'mysql'` | `'mysql'` 또는 `'sqlite'` |
| `db_host` | `'localhost'` | MySQL 호스트 |
| `db_port` | `3306` | MySQL 포트 |
| `db_user` | `''` | MySQL 사용자 |
| `db_pass` | `''` | MySQL 암호 |
| `db_dbname` | `''` | MySQL DB 이름, 또는 SQLite 파일 경로 |
| `cache_driver` | `''` | `''`(사용 안 함), `'memcached'`, `'redis'` |
| `cache_host` | `'localhost'` | 캐시 서버 호스트 |
| `cache_port` | `11211` | 캐시 서버 포트 (Redis는 보통 6379) |
| `cache_ttl` | `86400` | 캐시 유효 시간(초) |

DB와 캐시 연결은 첫 검색 때 만들어지고, 같은 객체로 다시 검색하면 재사용합니다.

#### search($keywords, $encoding = 'UTF-8', $version = null)

검색을 수행하고 `Postcodify_Server_Result` 객체를 반환합니다. 예외를 던지지 않고, 오류는 `error` 속성으로 알려 줍니다.

- `$keywords`: 검색어. 앞뒤 공백을 빼고 3~80자여야 합니다.
- `$encoding`: 검색어와 결과의 인코딩. EUC-KR을 쓰려면 `'CP949'`를 지정하십시오.
  일부 도로명·건물명에는 EUC-KR에 없는 글자가 있기 때문입니다.
- `$version`: 결과 레코드 형식. `null`이면 서버 버전(`POSTCODIFY_VERSION`)을 따릅니다.

| 버전 | 레코드 클래스 |
|---|---|
| 3 이상 | `Postcodify_Server_Record_v3` |
| 1.8 이상 3 미만 | `Postcodify_Server_Record_v18` |
| 1.8 미만 | `Postcodify_Server_Record_v17` |

> `search.php`와 마찬가지로, `search()`는 `$_GET['exact']`를 직접 읽습니다.

#### crc32_x64($str) (정적)

음수가 나오지 않는 CRC32 값을 반환합니다. 검색 키워드는 DB에 이 값으로 저장되어 있습니다(`postcodify_keywords.keyword_crc32`).

## 검색 결과

### Postcodify_Server_Result

| 속성 | 설명 |
|---|---|
| `version` | 서버 버전 |
| `error` | 오류 메시지. 정상이면 `''` |
| `msg` | 예약됨 (현재 항상 `''`) |
| `count` | 결과 수 (최대 100) |
| `time` | 소요 시간(초), 문자열 (예: `"0.012"`) |
| `lang` | 검색어 언어. `KO` 또는 `EN` |
| `sort` | 결과 정렬 기준. `JUSO`(도로명), `JIBEON`(지번), `POBOX`(사서함) |
| `type` | 검색 유형 (아래 표) |
| `nums` | 검색어에 포함된 번호 (예: `110`, `12-3`) |
| `cache` | `HIT` 또는 `MISS` |
| `results` | 레코드 배열 |

오류 메시지:

| `error` | 원인 |
|---|---|
| `Keyword Not Supplied` | 검색어가 비어 있음 |
| `Keyword is Not Valid <인코딩>` | 검색어가 지정한 인코딩이 아님 |
| `Keyword is Too Long or Too Short` | 3자 미만 또는 80자 초과 |
| `Database Error` | DB 연결 또는 쿼리 실패. 원인은 PHP `error_log`에 기록됨 |

검색 유형(`type`):

| 값 | 의미 |
|---|---|
| `JUSO`, `JUSO+NUMS` | 도로명 (+ 건물번호) |
| `JIBEON`, `JIBEON+NUMS` | 동·리 (+ 지번) |
| `BUILDING` | 건물명 |
| `BUILDING+JUSO` | 도로명 + 건물명 |
| `BUILDING+DONG` | 동·리 + 건물명 |
| `POBOX` | 사서함 |
| `EUPMYEON` | 읍·면만 입력 |
| `NONE` | 검색어를 해석하지 못함 (결과 없음) |
| `ERROR` | DB 오류 |

### Postcodify_Server_Record_v3

| 속성 | 설명 |
|---|---|
| `postcode5` | 새 우편번호(기초구역번호) |
| `postcode6` | 구 우편번호. `--add-old-postcodes` 없이 만든 DB에서는 비어 있을 수 있음 |
| `ko_common` | 시도~읍면 |
| `ko_doro` | 도로명 + 건물번호 |
| `ko_jibeon` | 동리 + 지번 |
| `en_common` | 영문 읍면~시도 |
| `en_doro` | 영문 건물번호 + 도로명 |
| `en_jibeon` | 영문 지번 + 동리 |
| `building_id` | 건물관리번호 |
| `building_name` | 건물명 |
| `building_nums` | 아파트 동 번호 등 |
| `other_addresses` | 관련 지번, 다른 건물명 등 |
| `road_id` | 도로명코드 12자리 (사서함은 `''`) |
| `internal_id` | DB 레코드 번호 (`postcodify_addresses.id`). `set-postcode` 명령에 쓰는 번호 |
| `address_id` | 법정동코드 10자리 + 산 여부(1/2) + 본번 4자리 + 부번 4자리 |

"지하"와 "산"은 번호 앞에 붙고, 영문은 `Jiha`, `San`으로 표기합니다.
사서함 결과는 `ko_doro`와 `ko_jibeon`이 모두 사서함 주소입니다.
`$encoding`이 UTF-8이 아니면 모든 속성이 그 인코딩으로 변환됩니다.

### 구버전 레코드

1.x 클라이언트 호환용입니다. 새로 개발할 때는 쓰지 마십시오.

- `Record_v18`: `code6`(`110-760` 형식), `code5`, `dbid`, `address`·`english`(배열: `base`, `new`, `old`, `building`), `other`(배열: `long`, `short`, `others`, `addrid`, `roadid`, `bldnum`)
- `Record_v17`: `code6`, `code5`, `dbid`, `address`, `canonical`, `extra_info_long`, `extra_info_short`, `english_address`, `jibeon_address`, `other`

## 검색어 분석 (Postcodify_Server_Query)

`Postcodify_Server_Query::parse_keywords($keywords)`는 검색어를 아래 속성으로 분해합니다.
`strval($q)`는 분석 결과를 공백으로 이은 문자열이며 캐시 키로 쓰입니다.

| 속성 | 설명 |
|---|---|
| `sido`, `sigungu`, `ilbangu`, `eupmyeon` | 지역 조건. 하나라도 있으면 `use_area`가 `true` |
| `road` | 도로명 (`~로`, `~길`) |
| `dongri` | 동·리 (`~동`, `~리`, `~가`) |
| `pobox` | 사서함 |
| `numbers` | `[주번, 부번]`. 없으면 `null` |
| `buildings` | 건물명 배열 |
| `lang` | `KO` 또는 `EN` |
| `sort` | `JUSO`, `JIBEON`, `POBOX` |

분석 규칙:

- `12번지 3호` 형태는 `12-3`으로 바꿉니다. `세종대로 110`, `세종대로110` 모두 인식합니다.
- 첫 단어가 시도(`서울`, `부산시`, `경기도` 등 축약형 포함)이면 `sido`로 정식 명칭을 넣습니다.
- 시·군·구·읍·면은 `Postcodify_Server_Areas` 목록에 있는 경우에만 지역 조건으로 씁니다.
- 번호가 나오면 분석을 마칩니다. 번호 뒤의 단어는 무시됩니다.
- 그 밖의 단어는 건물명으로 보되, `101동`, `12층`, `1203호` 같은 동·층·호수는 빼고, 끝의 `아파트`, `apt`, `@`는 떼어냅니다.
- 영문 주소(`110 Sejong-daero`, `Jiha 12 ...-gil`, `... -dong 12`)와 `PO Box 1234`도 인식합니다.

| 검색어 | 분석 결과 |
|---|---|
| `서울 세종대로 110` | sido=서울특별시, road=세종대로, numbers=[110] |
| `부산 해운대구 우동 1408` | sido=부산광역시, sigungu=해운대구, dongri=우동, numbers=[1408] |
| `강남구 삼성동 코엑스` | sigungu=강남구, dongri=삼성동, buildings=[코엑스] |
| `역삼동 래미안 101동 1203호` | dongri=역삼동, buildings=[래미안] |
| `테헤란로 래미안` | road=테헤란로, buildings=[래미안] |
| `광화문우체국사서함 50` | pobox=광화문우체국사서함, numbers=[50] |
| `110 Sejong-daero` | road=sejongdaero, numbers=[110], lang=EN |
| `고령군 대가야읍` | sigungu=고령군, eupmyeon=대가야읍 |

동·리로 검색했는데 결과가 없거나 읍·면만으로 결과가 없으면, 그 단어를 건물명으로 보고 다시 검색합니다.

## 검색 쿼리

`Postcodify_Server::get_addresses()`는 분석 결과에 따라 아래 테이블을 조인합니다.
도로명·동리는 정확한 일치(CRC32), 건물명·사서함은 부분 일치(`LIKE '%...%'`)로 찾습니다.

| 조건 | 테이블 |
|---|---|
| 기본 | `postcodify_addresses` + `postcodify_roads` |
| 도로명·동리 | `postcodify_keywords` (영문은 `postcodify_english` 추가) |
| 번호 | `postcodify_numbers` |
| 건물명 | `postcodify_buildings` |
| 사서함 | `postcodify_pobox` |

### Postcodify_Server_Database

`new Postcodify_Server_Database($driver, $host, $port, $user, $pass, $dbname)`

- SQLite: PDO만 지원하며 읽기 전용(`PRAGMA query_only`)으로 엽니다.
- MySQL: PDO → mysqli → mysql 확장 순으로 사용 가능한 것을 씁니다. 연결 문자셋은 `utf8`입니다.
- 쓸 수 있는 확장이 없으면 예외를 던집니다.

`query($querystring, $joins, $conds, $args, $lang = 'KO', $sort = 'JUSO', $limit = 100, $offset = 0)`는
`SELECT ... JOIN ... WHERE ... AND ...` 쿼리를 조합하여 실행하고 행 객체 배열을 반환합니다.
`$lang`과 `$sort`에 따라 시도 → 시군구 → 일반구 → 읍면 → 도로명(또는 동리) → 번호 순으로 정렬합니다.

## 캐시 (Postcodify_Server_Cache)

`config.php`에서 `POSTCODIFY_CACHE_DRIVER`를 지정하면 켜집니다.

```php
define('POSTCODIFY_CACHE_DRIVER', 'redis');   // 'memcached' 또는 'redis'
define('POSTCODIFY_CACHE_HOST', 'localhost');
define('POSTCODIFY_CACHE_PORT', 6379);
define('POSTCODIFY_CACHE_TTL', 86400);
```

- `memcached`는 PHP의 `Memcached` 확장을, 없으면 `Memcache` 확장을 씁니다. `redis`는 `Redis`(phpredis) 확장이 필요합니다.
- 번호가 없는 검색어(예: `세종대로`, `래미안`)만 캐시합니다. 번호가 있는 검색은 결과가 적고 종류가 많기 때문입니다.
- 키는 `Postcodify:<버전>:CACHE:<분석 결과의 sha1>`이므로 Postcodify를 업그레이드하면 이전 캐시는 쓰이지 않습니다.
- DB를 업데이트한 후 바로 반영하려면 캐시를 비우십시오.

## 지역 목록 (Postcodify_Server_Areas)

세 개의 정적 배열입니다. 행정구역이 바뀌면 이 파일을 고쳐야 검색어 분석이 맞게 됩니다.

- `$sido`: 축약형 → 정식 명칭 (예: `'서울' => '서울특별시'`)
- `$sigungu`: 자치구·시·군 이름 목록
- `$ilbangu`: 일반구 이름 목록 (예: 수원시 장안구)

## 원격 API 클라이언트 (Postcodify_Client)

DB 없이 다른 Postcodify 검색서버(기본값: 무료 API `api.poesis.kr`)에 서버측에서 질의할 때 씁니다. cURL 확장이 필요합니다.

```php
$client = new Postcodify_Client;
$client->set_domain('www.example.com');   // 필수: 호출하는 사이트 도메인
$client->set_api_url('https://my-server/lib/search.php');   // 생략시 무료 API
$client->use_ssl();
$result = $client->search('세종대로 110');   // 실패시 false

if ($result && $result->error === '')
{
    echo $result->results[0]->postcode5;
}
```

| 메소드 | 설명 |
|---|---|
| `set_domain($domain)` | 요청에 `ref`로 보낼 도메인. 지정하지 않거나 형식이 틀리면 `search()`가 예외를 던짐 |
| `set_api_url($url)` | 검색서버 주소 |
| `set_backup_api_url($url)` | 메인 서버 실패시 재시도할 주소 |
| `set_timeout($ms)`, `set_backup_timeout($ms)` | 접속 제한시간 |
| `set_user_agent($ua)` | User-Agent (기본값 `Postcodify Client <버전>`) |
| `set_charset($charset)` | 검색어 인코딩이 UTF-8이 아닌 경우 지정 (결과는 UTF-8) |
| `use_ssl()` | 기본 API 주소에 https 사용 |
| `search($keywords)` | 결과 객체(JSON을 디코딩한 `stdClass`) 또는 `false` |

`set_api_url()`을 지정하지 않으면 무료 API 실패시 같은 주소로 한 번 더 시도합니다.

## 에뮬레이터

다른 우편번호 검색 API를 쓰던 프로그램을 수정하지 않고 Postcodify로 바꿀 수 있도록,
같은 입출력 형식을 흉내내는 엔드포인트입니다. 둘 다 `Postcodify_Server`를 써서 검색합니다.

| 파일 | 대상 | 입력 |
|---|---|---|
| [emulators/xe.php](../lib/emulators/xe.php) | XE의 KRZIP 모듈 | `request=addr1`(시도 목록), `request=addr2`, `search_addr1`, `search_word` |
| [emulators/sir.php](../lib/emulators/sir.php) | 그누보드(SIR) 우편번호 검색 | `q`, `sido`, `gugun`, `charset`(euc-kr 지원) |
