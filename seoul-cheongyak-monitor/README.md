# 서울·수도권 청약 모니터

청약홈(한국부동산원) 오픈API 기반. 수도권(서울·경기·인천) APT 청약 목록, 단지별 실제 공고 정보(규제·특공 세대수·면적·분양가·일정·모집공고문 PDF), 프로필 기반 특별·일반공급 자격 판정.

## 파일
- `index.html` — 페이지 전체(단일 파일). 같은 폴더의 `listings.json`이 있으면 그 데이터를, 없으면 내장 스냅샷을 사용.
- `listings.json` — 자동 생성되는 최신 데이터(아래 워크플로가 생성/갱신). 없으면 index.html의 내장 데이터로 동작.
- `tools/fetch-data.js` — 청약홈 오픈API를 호출해 `listings.json`을 만드는 Node 스크립트.
- `.github/workflows/update-data.yml` — 매일 06:00(KST) 자동 갱신 + 배포 시 1회 실행.

## 배포 & 자동 갱신 설정 (GitHub Pages)
1. 이 폴더를 GitHub 저장소로 push.
2. **Settings → Secrets and variables → Actions → New repository secret**
   - Name: `SERVICE_KEY`
   - Value: data.go.kr "청약홈 분양정보 조회 서비스" 오픈API **일반 인증키(Encoding)**
3. **Settings → Pages → Source: Deploy from a branch → Branch: `main` / `/root`** 저장.
4. **Actions 탭 → "청약 데이터 자동 갱신" → Run workflow** (또는 push 시 자동 1회) → `listings.json` 생성.
5. 접속: `https://<아이디>.github.io/<저장소>/`

로컬에서 직접 생성해보려면:
```bash
SERVICE_KEY=발급받은키 node tools/fetch-data.js
```

## 주의 (신뢰도)
자동화해도 이 페이지는 **참고용 예측**입니다. 실제 청약 전에는 반드시:
- 청약홈 **「청약자격 진단」**(공동인증 본인확인)
- 해당 단지 **입주자모집공고 원문(PDF)**
- 세대원 정보제공동의·통장 가입내역
을 확인하세요. 소득·자산 세부기준, 지역우선(거주기간), 재당첨/부적격은 공고문이 최종 기준입니다.

인증키는 저장소 코드에 넣지 말고 **Secrets**에만 두세요.
