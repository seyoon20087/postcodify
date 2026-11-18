# 백업 및 복구

2.0부터는 저장 프로시저를 쓰지 않으므로 일반 `mysqldump`로 백업하면 됩니다.
[lib/resources/mysqldump.sh](../lib/resources/mysqldump.sh)에 접속 정보를 채워 실행하면 `dump.sql.gz`가 만들어집니다.

```sh
mysqldump --opt --order-by-primary \
    --single-transaction --no-autocommit --skip-tz-utc --no-tablespaces \
    -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASS \
    $MYSQL_DBNAME | gzip > dump.sql.gz
```

복구:

```sh
gunzip < dump.sql.gz | mysql -u아이디 -p DB이름
```

복구 후 `php indexer.php verifydb`로 확인하십시오. 복구 직후에는 버퍼가 비어 있어 검색이 느릴 수 있습니다.

## 1.8 이하

1.8 이하는 저장 프로시저를 쓰므로 `--routines` 옵션이 필요하고, 덤프한 사용자와 복구하는 사용자가 다르면
`DEFINER` 때문에 오류가 날 수 있습니다(`sed 's/DEFINER=`[^`]*`@`[^`]*` //'`로 제거).
이 버전은 더 이상 업데이트할 수 없으니 최신 버전으로 DB를 새로 생성하십시오.
