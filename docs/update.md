# 업데이트 적용

## 유의사항

일변동자료에는 기초구역번호 등 일부 정보가 빠져 있습니다. Postcodify는 가장 가까운 기초구역번호를 찾아 넣지만 100% 정확하지는 않습니다.
행정구역이 크게 바뀌는 경우도 처리하지 못합니다. 업데이트에만 의존하지 말고 1년에 2~3번은 DB를 [새로 생성](indexer.md)하십시오.

업데이트는 MySQL DB에만 적용할 수 있습니다.

## 다운로드

```sh
cd lib
php indexer.php download-updates
```

DB에 기록된 마지막 기준일(`postcodify_settings.updated`) 다음 날부터 어제까지의
`YYYYMMDD_dailynoticedata.zip`을 business.juso.go.kr에서 받아 `data/`에 저장합니다.
이미 있는 파일은 건너뜁니다. 마지막 업데이트 후 365일이 지나면 받지 않으니 DB를 새로 만드십시오.

자동 다운로드가 실패하면 도로명주소 안내시스템에서 일변동자료를 직접 받아
같은 이름으로 `data/`에 넣으십시오.

## 적용

```sh
php indexer.php update
```

`data/`의 `????????_dailynoticedata.zip` 중 DB 기준일 이후 파일을 날짜순으로 적용하고 기준일을 갱신합니다.
`createdb --add-old-postcodes`로 만든 DB는 자동으로 구 우편번호도 처리합니다.

매일 자동으로 적용하려면 cron에 등록할 수 있습니다.

```cron
30 4 * * * cd /path/to/postcodify/lib && php indexer.php download-updates && php indexer.php update
```

## 구버전

2.5 이하 버전은 데이터 포맷 변경으로 더 이상 업데이트할 수 없습니다.
최신 버전으로 업그레이드한 후 DB를 새로 생성하십시오.
