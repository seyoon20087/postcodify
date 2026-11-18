# SQLite 변환

인덱서로 MySQL DB를 만든 후 SQLite 파일로 변환할 수 있습니다.
SQLite는 파일 하나만 복사하면 어디서나 검색할 수 있고 저사양 서버에서도 빠르지만, 업데이트를 적용할 수 없습니다.
최신 데이터가 필요하면 MySQL DB를 [업데이트](update.md)한 후 다시 변환하십시오.

`config.php`는 MySQL 접속 정보 그대로 둔 상태에서, 결과를 저장할 파일 이름을 지정합니다.
PHP에 `pdo_sqlite` 모듈이 필요합니다.

```sh
cd lib
php indexer.php sqlite-convert /path/to/postcodify.sqlite
```

11개 테이블의 데이터를 복사하고 인덱스를 만든 뒤 최적화합니다. 기존 파일은 덮어씁니다.

변환한 파일을 쓰려면 검색서버의 `config.php`를 아래처럼 바꿉니다.

```php
define('POSTCODIFY_DB_DRIVER', 'sqlite');
define('POSTCODIFY_DB_DBNAME', '/path/to/postcodify.sqlite');
```
