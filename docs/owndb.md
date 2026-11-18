# DB 구축 방법 선택

## 프로그램 다운로드

```sh
git clone https://github.com/kijin/postcodify.git
```

## DB 구축 방법

서버용 프로그램을 받은 후에는 검색에 사용할 DB를 구축해야 합니다. 방법은 두 가지입니다.

1. 이미 만들어진 DB 덤프(MySQL 또는 SQLite)를 복구하여 사용
2. 행정안전부(도로명주소 안내시스템), 우체국 등에서 제공하는 데이터를 [인덱서](indexer.md)로 직접 변환하여 사용

### DB 덤프 사용하기

- 장점: 인덱서 구동 환경이 필요 없고, 저사양 서버에서도 빠르게 구축할 수 있습니다. SQLite는 압축만 풀면 바로 사용할 수 있습니다.
- 단점: 덤프 배포가 지연되거나 중단될 수 있습니다. 이 경우 직접 변환할 준비가 되어 있어야 합니다.

> 원본 매뉴얼은 포에시스 파일서버에서 부정기적으로 배포하는 덤프를 안내했으나, 현재도 배포되는지는 확인되지 않았습니다.
> 덤프 버전과 `lib/` 버전이 크게 다르면 호환되지 않을 수 있습니다.

하루 100만 건 이상 검색하거나 주소 변경 내역을 수시로 반영하려면 MySQL을 쓰고 [업데이트](update.md)를 적용하십시오.
그 외에는 SQLite로도 충분합니다. 검색은 SELECT만 사용하므로 성능 차이가 거의 없습니다.

#### MySQL 덤프 복구

서버 사양에 따라 10분에서 3시간 이상 걸릴 수 있습니다.

```sh
gzip -d postcodify.YYYYMMDD.v3.mysqldump.gz
mysql -u아이디 -p DB이름 < postcodify.YYYYMMDD.v3.mysqldump
```

복구 후 `php indexer.php verifydb`로 확인하고([인덱서 구동 - 테스트](indexer.md#4단계-테스트)),
`lib/config.example.php`를 `lib/config.php`로 복사하여 접속 정보를 입력합니다.

```php
define('POSTCODIFY_DB_DRIVER', 'mysql');
define('POSTCODIFY_DB_DBNAME', 'DB이름');
define('POSTCODIFY_DB_HOST', 'localhost');
define('POSTCODIFY_DB_PORT', 3306);
define('POSTCODIFY_DB_USER', '아이디');
define('POSTCODIFY_DB_PASS', '암호');
```

#### SQLite 파일 사용

```sh
gzip -d postcodify.YYYYMMDD.v3.sqlite.gz
```

```php
define('POSTCODIFY_DB_DRIVER', 'sqlite');
define('POSTCODIFY_DB_DBNAME', '/path/to/postcodify.sqlite');
define('POSTCODIFY_DB_HOST', '');
define('POSTCODIFY_DB_PORT', '');
define('POSTCODIFY_DB_USER', '');
define('POSTCODIFY_DB_PASS', '');
```

SQLite DB는 업데이트할 수 없습니다. 최신 데이터가 필요하면 MySQL DB를 업데이트한 후 [다시 변환](sqlite.md)하십시오.

### 직접 변환하기

- 장점: 덤프 배포와 관계없이 공공 데이터로 DB를 계속 갱신할 수 있습니다.
- 단점: 인덱서 구동 환경이 필요하고 CPU·메모리·디스크 I/O를 많이 씁니다. 다른 서비스가 돌아가는 서버에서는 구동하지 않는 것이 좋습니다.
  잘못 동작하면 데이터가 누락될 수 있고, 데이터 양이 많아 누락을 찾기 어렵습니다.

[데이터 파일을 다운로드](download.md)한 후 [인덱서를 구동](indexer.md)하십시오.
