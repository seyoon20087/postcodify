# 데이터 파일 다운로드

## 자동 다운로드

`lib` 폴더에서 아래 명령을 실행하면 인덱서에 필요한 파일을 모두 받아 저장소 최상위의 `data/` 폴더에 저장합니다.
폴더가 없으면 자동으로 만듭니다. (`data/`는 `.gitignore`에 포함되어 있습니다.)

```sh
cd lib
php indexer.php download
```

주소 데이터는 전월분을 먼저 시도하고, 없으면 전전월분을 받습니다.

| 파일 | 내용 | 출처 |
|---|---|---|
| `YYYYMMALLRDNM.zip` | 건물DB 전체분 (도로명주소 전체) | business.juso.go.kr |
| `areacd_pobox_DB.zip` | 사서함 DB | epost.go.kr |
| `areacd_rangeaddr_DB.zip` | 새 우편번호 범위 DB | epost.go.kr |
| `oldaddr_zipcode_DB.zip` | 구 우편번호 범위 DB | cdn.poesis.kr |
| `oldaddr_special_DB.zip` | 구 우편번호 범위 DB (특수) | cdn.poesis.kr |

압축 파일은 인덱서가 그대로 읽으므로 풀 필요가 없습니다.

> 원본 매뉴얼(3.4 기준)의 `RDNMADR.zip`, `RDNMCODE.zip`, `english_aliases_DB.zip`은 현재 코드에서 쓰지 않습니다.
> 주소 데이터는 `ALLRDNM.zip` 하나로 바뀌었습니다.

## 수동 다운로드

기관 웹사이트가 바뀌어 자동 다운로드가 실패하면, 위 표의 파일을 직접 받아 `data/` 폴더에 넣으십시오.
다운로드 URL은 [lib/classes/indexer/download.php](../lib/classes/indexer/download.php)에 있습니다.

- 구 우편번호 파일 두 개는 `createdb --add-old-postcodes`를 쓸 때만 필요합니다.
- 주소 파일 이름은 `YYYYMMALLRDNM.zip` 형식이어야 인덱서가 찾습니다.
