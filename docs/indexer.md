# 인덱서 구동

인덱서(`lib/indexer.php`)는 PHP CLI 스크립트입니다. 데이터 파일을 분석하고 검색어를 추출하여 MySQL DB에 입력합니다.
[데이터 파일을 다운로드](download.md)한 후 실행하십시오.

## 1단계: 구동 환경 확인

`createdb`를 실행하면 [checkenv.php](../lib/classes/indexer/checkenv.php)가 아래 항목을 확인합니다.

- 리눅스 또는 유닉스 계열 OS (윈도우 미지원), PHP CLI
- PHP 모듈: `pdo_mysql`, `zip`, `mbstring`, `pcntl`, `shmop` (그 외 `json`, `readline`)
- MySQL 5.0 이상 또는 MariaDB, InnoDB 엔진 사용 가능
- `innodb_buffer_pool_size` 128MB 이상 (가능하면 1GB 이상)

인덱서는 속도를 위해 `pcntl_fork`로 여러 프로세스를 띄우고 `shmop`으로 공유 메모리를 씁니다.
배포판에 따라 `php.ini`의 `disable_functions`로 이 함수들이 막혀 있으니 해제하십시오.

```sh
sed -i -r 's/^disable_functions/;disable_functions/' /etc/php/*/cli/php.ini
```

가장 쉬운 방법은 저장소의 개발 컨테이너([.devcontainer/](../.devcontainer/))를 쓰는 것입니다.
PHP 8.5와 MariaDB, 필요한 모듈이 모두 준비되어 있고, 시작할 때 `postcodify` DB와 사용자를 만듭니다.

Debian/Ubuntu에서 직접 준비하려면 예를 들어:

```sh
apt-get install mariadb-server php-cli php-mysql php-mbstring php-zip
```

(`pcntl`, `shmop`은 배포판 PHP에 보통 포함되어 있습니다. `php -m`으로 확인하십시오.)

## 2단계: 설정

`lib/config.example.php`를 `lib/config.php`로 복사하여 DB 접속 정보를 입력합니다.
인덱서는 MySQL만 지원하므로 `POSTCODIFY_DB_DRIVER`는 `mysql`이어야 합니다.

```php
define('POSTCODIFY_DB_DRIVER', 'mysql');
define('POSTCODIFY_DB_DBNAME', 'DB이름');
define('POSTCODIFY_DB_HOST', 'localhost');
define('POSTCODIFY_DB_PORT', 3306);
define('POSTCODIFY_DB_USER', '아이디');
define('POSTCODIFY_DB_PASS', '암호');
```

## 3단계: DB 생성

```sh
cd lib
php indexer.php createdb
```

서버 사양에 따라 20분에서 3시간 정도 걸립니다. 구 우편번호(6자리)도 넣으려면 `--add-old-postcodes`를 붙입니다.
이 설정은 DB(`postcodify_settings.oldpostcodes`)에 저장되어 이후 `update`에도 적용됩니다.

```sh
php indexer.php createdb --add-old-postcodes
```

## 4단계: 테스트

완료되면 아래 11개 테이블이 생깁니다. (정의: [lib/resources/schema.php](../lib/resources/schema.php))

```
postcodify_addresses      postcodify_pobox
postcodify_buildings      postcodify_ranges_jibeon
postcodify_english        postcodify_ranges_oldcode
postcodify_keywords       postcodify_ranges_roads
postcodify_numbers        postcodify_roads
                          postcodify_settings
```

2.0부터는 저장 프로시저를 쓰지 않으므로 테이블만 확인하면 됩니다.
구조가 다르거나 용량이 지나치게 작으면(정상 범위 4~5GB) 데이터나 인덱스가 누락되었을 가능성이 높습니다.

`verifydb`는 테이블, 인덱스, 레코드 수, 우편번호 누락을 확인합니다.
`createdb`에 `--add-old-postcodes`를 썼다면 여기에도 붙이십시오.

```sh
php indexer.php verifydb
```

검색은 CLI에서 바로 시험할 수 있습니다. 결과가 JSON으로 출력됩니다.

```sh
php search.php "세종대로 110"
```

### 우편번호 누락시 대처

원본 데이터에 우편번호가 빠진 경우가 있습니다. 인덱서는 범위 데이터로 자동 보완을 시도하지만,
실패하면 `verifydb`가 아래와 같은 오류를 냅니다.

```
[ERROR] 우편번호(기존번호)가 누락된 레코드가 있습니다.
  #4163856 경상북도 고령군 대가야읍 대가야로 1431
```

`set-postcode`로 직접 입력합니다. 첫 인자는 레코드 번호, 둘째 인자는 우편번호입니다.
6자리는 구 우편번호, 5자리는 새 우편번호(기초구역번호)로 인식합니다.

```sh
php indexer.php set-postcode 4163856 40135
```

### 검색이 느릴 때

DB를 방금 만들었거나 복구했다면 인덱스가 아직 버퍼에 올라오지 않아 느릴 수 있습니다.
도로명, 지번, 건물명 등으로 몇 번 검색하면 빨라집니다. 계속 1초 이상 걸리면 서버 사양,
DB 설정이나 디스크 손상, 인덱스 누락(`verifydb`)을 점검하십시오.

## 명령 요약

| 명령 | 설명 |
|---|---|
| `download` | 데이터 파일 다운로드 |
| `createdb [--add-old-postcodes]` | DB 생성 |
| `verifydb [--add-old-postcodes]` | DB 점검 |
| `set-postcode <id> <postcode>` | 누락된 우편번호 입력 |
| `download-updates` | 일변동자료 다운로드 |
| `update` | 일변동자료 적용 |
| `sqlite-convert <file>` | SQLite로 변환 |
