# 스토어 제출 체크리스트 — 교무실 속닥속닥

번들 ID `com.schoolhub.sokdak` · 버전 `1.0.0+1` · 목표 출시 시점: **2026-10-07 강의 전**

## 0. 빌드 산출물

```bash
# iOS (App Store / TestFlight) → build/ios/ipa/*.ipa
flutter build ipa --release --dart-define-from-file=env.json

# Android (Google Play) → build/app/outputs/bundle/release/app-release.aab
flutter build appbundle --release --dart-define-from-file=env.json
```

- 스토어에 올릴 때마다 `pubspec.yaml`의 `version: 1.0.0+N` 에서 **N(빌드 번호)을 올려야** 합니다.
- Android 업로드 키: `~/.keystores/sokdak-upload.jks`, 비밀번호: `android/key.properties`
  - ⚠ **두 파일을 안전한 곳(비밀번호 관리자 등)에 백업하세요.** 잃어버리면 Play Console에서 업로드 키 재설정을 요청해야 합니다.
  - 이 파일들은 git에 올리지 않습니다(`.gitignore`에 포함).
- 릴리스 검증 완료: Android는 INTERNET 권한 포함, 업로드 키로 서명됨 / iOS는 Apple Distribution 서명, App Store용 프로필.

## 1. 두 스토어 공통 (먼저 끝낼 것)

| 항목 | 상태 | 비고 |
|---|---|---|
| 문의·신고 이메일 | ✅ | `orangenova91@gmail.com` (`lib/core/config/app_info.dart`). 앱 내 약관 화면과 웹 문서에 표시됨. 스토어에 공개되는 연락처 |
| 개인정보 처리방침 **웹 URL** | ⬜ **필요** | `dart run tool/gen_legal_html.dart` → `docs/legal/privacy.html` 을 웹에 게시 (GitHub Pages, Cloudflare Pages, Netlify 등). 문구를 고치면 생성 명령을 다시 실행할 것 |
| 계정 삭제 안내 URL | ⬜ 필요 | `docs/legal/account-deletion.html` 게시 (Google Play 필수) |
| 이용약관·처리방침 법률 검토 | ⬜ 권장 | 현재 본문은 초안. 운영 주체(상호/개인) 표기 포함해 검토 |
| 스크린샷·그래픽 | ✅ | `docs/screenshots/` (아래 3항) |
| 앱 설명, 키워드, 카테고리 | ⬜ | 카테고리: 소셜 네트워킹 또는 라이프스타일. 대상: 교사(성인) |
| 앱 아이콘 | ✅ | `assets/icon/` (1024px 원본, 알파 없음 확인) |
| 계정 삭제 기능 | ✅ | 내 정보 > 계정 삭제 (서버 데이터 삭제 검증됨) |
| 신고 / 차단 / 자동 숨김 | ✅ | 신고 3건 누적 시 자동 숨김 |
| 약관 동의 | ✅ | 가입 시 필수 체크 |

## 2. Apple (App Store Connect)

1. **앱 만들기**: My Apps → + → 새 앱. 번들 ID `com.schoolhub.sokdak` (빌드 시 Xcode 자동 서명이 App ID를 계정에 등록했을 수 있음. 목록에 있으면 선택)
2. **빌드 업로드**: `build/ios/ipa/*.ipa` 를 **Transporter** 앱에 드래그. 처리에 수 분~수십 분 소요.
3. **TestFlight**: 내부 테스터는 즉시 사용 가능. 외부 테스터는 첫 빌드에 베타 심사(보통 1일 이내)가 필요합니다.
4. **앱 정보**
   - 개인정보 처리방침 URL, 지원 URL
   - 연령 등급 설문: 사용자 생성 콘텐츠가 있다고 정직하게 응답
   - **앱 개인정보 보호(영양 라벨)**: 수집 데이터 = 사용자 콘텐츠(글, 댓글), 식별자(익명 사용자 ID). 모두 "사용자와 연결됨", **추적 없음**, 광고 없음
   - 수출 규정: 표준 암호화만 사용 (`ITSAppUsesNonExemptEncryption=false` 설정됨)
5. **심사 메모 (App Review Information)** — 아래 문안을 붙여 넣으세요.

```
로그인 정보는 필요하지 않습니다. 앱은 익명 로그인을 사용하며, 첫 화면에서 약관에 동의하고
"시작하기"를 누른 뒤 닉네임·지역(울산)·학교급을 선택하면 모든 기능을 사용할 수 있습니다.

사용자 생성 콘텐츠(Guideline 1.2) 대응:
- 약관 동의: 가입 전 이용약관·개인정보 처리방침에 필수 동의
- 신고: 모든 글/댓글에서 신고 가능(사유 선택). 신고가 3건 누적되면 자동으로 숨김 처리
- 차단: 작성자 차단 및 차단 해제(내 정보 > 차단한 사용자)
- 필터: 전화번호·주민등록번호 형태의 개인정보는 작성 시 차단
- 연락처: orangenova91@gmail.com — 신고 확인 후 24시간 내 조치를 목표로 합니다
- 계정 삭제: 내 정보 > 계정 삭제 (서버 데이터 즉시 삭제)
```

6. **심사 제출** → 결과까지 보통 1~3일. 반려에 대비해 **늦어도 10/1까지 제출**.

## 3. 스크린샷 (촬영 완료)

앱 화면 5장: 환영/가입, 속닥방 피드, 속닥 글 상세(공감·댓글), 노하우방 피드, 노하우 글 상세.
촬영용 샘플 글로 찍은 뒤 서버 데이터는 모두 삭제했습니다.

| 용도 | 위치 | 규격 |
|---|---|---|
| App Store iPhone 6.9" | `docs/screenshots/ios/*.png` | 1320×2868, 알파 없음 |
| Google Play 휴대전화 | `docs/screenshots/play/0*.png` | 1080×2160 (세로:가로 2:1 이내) |
| Google Play 아이콘 | `docs/screenshots/play/icon-512.png` | 512×512 |
| Google Play 홍보 그래픽 | `docs/screenshots/play/feature-graphic-1024x500.png` | 1024×500 |

- App Store Connect는 6.9" 스크린샷 하나만 올리면 다른 iPhone 크기에 자동 적용됩니다.
- 스크린샷의 닉네임·글은 모두 촬영용 가상 데이터입니다.

## 4. Google Play Console

1. **앱 만들기** → 패키지명 `com.schoolhub.sokdak`, Play 앱 서명 사용(업로드 키는 위 keystore)
2. **앱 콘텐츠 선언**
   - 개인정보처리방침 URL
   - 앱 액세스: 로그인 불필요(익명 가입) — 설명 기재
   - 광고: 없음 / 대상 연령: 성인(18+)
   - **데이터 보안**: 수집 = 사용자 ID, 게시물/댓글. 전송 중 암호화 **예**, 삭제 요청 가능 **예**(앱 내)
   - **계정 삭제**: 앱 내 경로 + 웹 URL(`account-deletion.html`)
   - 콘텐츠 등급 설문: 사용자 생성 콘텐츠 포함
3. **테스트 트랙 → 프로덕션**
   - ⚠ **신규 개인 개발자 계정은 프로덕션 출시 전에 비공개 테스트를 테스터 12명 이상, 14일 연속 진행해야 합니다.** (제가 알기로는 2023-11 이후 생성된 개인 계정에 해당하며, 정책은 바뀔 수 있으니 Play Console 안내를 확인하세요.) 조직 계정이면 해당 없음.
   - 해당된다면 **오늘 시작해야** 10/7 전에 14일을 채울 수 있습니다. 못 채우면 Android는 강의에서 **비공개 테스트 링크(초대)** 로 배포하는 방법이 있습니다.

## 5. 일정 (오늘 9/21 → 강의 10/7)

| 날짜 | 할 일 |
|---|---|
| 9/21~22 | 처리방침·계정삭제 페이지 웹 게시, 앱 설명·키워드 작성 |
| 9/23 | App Store Connect 앱 생성, TestFlight 업로드. Play Console 앱 생성, **비공개 테스트 시작(테스터 모집)** |
| 9/24~27 | 실기기 테스트(iOS/Android), 발견된 문제 수정 |
| ~9/30 | **Apple 심사 제출** (반려 대비 여유 확보) |
| 10/1~6 | 심사 결과 대응, Supabase 익명 로그인 한도 상향(아래 6항), 강의용 QR 준비 |
| 10/7 | 강의 |

## 6. 강의 당일 위험 요소

- **Supabase 익명 로그인 한도**: IP당 시간당 가입 횟수 제한이 있어(기본값은 대략 30회로 알고 있음) 강의장 50명이 같은 와이파이로 가입하면 일부가 실패할 수 있습니다. 대시보드 **Authentication → Rate Limits**에서 익명 로그인 한도를 올리세요.
- **CAPTCHA**: 공개 배포 전 익명 로그인에 켜는 것을 권장 (가짜 계정 대량 생성 방지). 켜면 앱에 CAPTCHA 연동 작업이 추가로 필요합니다.
- 강의 QR 코드는 스토어 URL을 가리키게 하고, 심사가 늦어질 때를 대비해 TestFlight 공개 링크/Play 비공개 테스트 링크를 예비로 준비하세요.

## 7. 알려진 한계 (심사·운영 전 인지)

- 욕설 필터가 없습니다(현재는 신고 누적 자동 숨김과 개인정보 패턴 차단만 있음). 심사에서 지적되면 금칙어 필터를 추가합니다.
- 서버는 정확한 작성 시각을 그대로 내려줍니다(화면에서만 흐리게 표시).
- 신고 접수 알림/관리 화면이 없습니다. 신고 내용은 Supabase 대시보드의 `reports` 테이블에서 확인하세요.
- 교사 인증은 미구현(이후 단계). 인증 도입 시 개인정보 처리방침의 5항을 갱신해야 합니다.
