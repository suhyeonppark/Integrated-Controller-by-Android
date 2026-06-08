# 개발 진행 현황 (AMX CE Control)

Android 태블릿 독립형 AMX CE-IRS4 / CE-REL8 컨트롤 앱.
서버 없이 태블릿이 TCP 44197로 장비에 직접 접속.

최종 업데이트: 2026-06-08

---

## ✅ 완료된 사항

### 1. 프로젝트 기반
- Flutter 프로젝트 생성 (`amx_ce_control`, org `com.amxctrl`, Android/iOS)
- 의존성: `shared_preferences`(설정 저장), `wakelock_plus`(화면 꺼짐 방지)
- AndroidManifest: `INTERNET` 권한, **가로(landscape) 우선**, 화면 유지
- 앱 시작 시 wakelock 활성화, 가로 우선 + 세로 fallback

### 2. 통신 계층 (매뉴얼 검증 완료)
- `CeTcpClient`: connect→send→close 방식, 자동 `\n` 추가, timeout, 모든 소켓
  오류를 한국어 메시지로 변환(앱 미크래시), 연결 테스트
- `CeIrs4Client` (IR 전용 명령 생성):
  - `exec /ir/{port}/bufferedSendNamedIr "{name}"` (이름)
  - `exec /ir/{port}/bufferedSendIr {index}` (번호)
  - `exec /ir/{port}/loadIrFile "{file}"`
- `CeRel8Client` (릴레이 전용 명령 생성, **매뉴얼 확인됨**):
  - ON/close: `set /relay/{n}/state true`
  - OFF/open: `set /relay/{n}/state false`
  - 순간(momentary)은 소프트웨어로 처리(close→대기→open, open 실패 시 재시도+경고)
- ※ UI 코드는 TCP 문자열을 직접 만들지 않음. 모든 명령은 위 클라이언트에서만 생성.

### 3. 액션 / 라우팅
- `ActionRouter`: action_id → 실제 동작 (IR / 릴레이 / 매크로), 주입된 resolver로
  액션 조회 → 런타임 편집 가능
- `InterlockManager`: 릴레이 안전 로직(openBeforeClose, 순간/래칭 처리) — 향후 모터
  부하(스크린/리프트) 대비 유지
- 매크로: 시스템 ON/OFF, 발표/대기 모드, 전체 디스플레이 ON/OFF
  (홈 화면, v1에서는 고정)

### 4. 화면 구성
- **홈**: 시스템 ON/OFF, 발표/대기 모드, 전체 디스플레이 ON/OFF (매크로)
- **IR 제어**: 사용자 정의 버튼을 그룹별로 렌더링 (기본: TV1, TV2, 프로젝터)
- **전원 제어**: 사용자 정의 버튼 (기본: 순차전원 전체/순차1/순차2)
- **설정**: 장비 IP/포트/타임아웃/버튼잠금 + 연결 테스트 + **버튼 편집** 진입
- 상단 상태바(IRS4/REL8 ONLINE/OFFLINE), 하단 4탭 네비게이션

### 5. 장비 구성 (현재 기본값)
- IR 포트: 1 = TV1, 2 = TV2, 3 = 프로젝터
- 릴레이: 1 = 순차전원 전체(master), 2 = 순차1, 3 = 순차2 (래칭, close=ON/open=OFF)

### 6. 버튼 편집 시스템 (설정 → 버튼 편집)
- 버튼이 코드 상수가 아니라 **편집 가능한 데이터**(`ButtonConfig`,
  `buttons_v1` 키로 저장)
- 버튼 **추가 / 삭제 / 수정**, 그룹(섹션)별 목록, **기본값 복원**
- IR 버튼: 라벨, 그룹, **포트(1~4)**, **IR 채널 방식(이름/번호)**, **채널 값**,
  확인 팝업, 위험색
- 전원 버튼: 라벨, 그룹, **릴레이 번호(1~8)**, 동작(ON유지/OFF유지/순간),
  순간 시간, **길게 누르기(2초)**, 확인/위험

### 7. 안전 / UX
- **TV(IR) 버튼은 단일 탭, 전원 버튼은 2초 길게 누르기**(진행 막대 표시, 중간에
  떼면 취소) — 홀드가 확인 팝업을 대체
- 위험 탭 버튼(시스템 OFF, 전체 디스플레이 OFF, 프로젝터 OFF 등) 확인 팝업
- 연타 방지: 버튼 누른 뒤 `button_lock_ms` 동안 비활성화, 매크로 실행 중 전체 비활성화
- 릴레이 순간 동작 open 실패 시 재시도 + 강한 경고 다이얼로그
- IR/릴레이는 단방향 → "명령 전송됨"만 표시(장비 상태 단정 안 함)
- 네트워크 오류로 앱이 죽지 않음, 명확한 한국어 메시지

### 8. 검증
- `flutter analyze` → 이슈 0
- `flutter test` → 6개 테스트 통과 (IR/릴레이 명령 포맷, 버튼 직렬화, 기본 버튼·매크로 정합성)
- `flutter build apk --debug` → 빌드 성공
  (`build/app/outputs/flutter-apk/app-debug.apk`)

---

## ⏳ 미완료 / 다음 후보
- 홈 화면 **매크로 스텝 편집기** (현재 매크로는 코드 고정)
- 버튼 **순서 드래그 변경** (현재 추가 시 그룹 끝에 추가)
- 실제 장비 상태 피드백(리미트 센서/RS-232/전류 감지 등) — 초기 버전 범위 외
- 실제 태블릿 설치 + 현장 IR 코드 이름/`.irl`/릴레이 배선 검증

---

## 코드 구조
```
lib/
  main.dart, app.dart, app_state.dart        # 진입점, 앱, 전역 상태(AppScope)
  config/  app_config, config_repository,
           button_repository, default_buttons # 설정·버튼 저장 / 기본값
  ce/      ce_tcp_client, ce_irs4_client,
           ce_rel8_client                      # 통신 계층(명령 생성)
  actions/ action_ids, action_models,
           action_router, interlock_manager,
           macro_registry                      # 액션 정의·라우팅·매크로
  models/  command_result, device_status,
           button_config                       # 데이터 모델
  screens/ home, ir, relay(power), settings,
           main_shell, button_list,
           button_edit                         # 화면
  widgets/ control_button, status_bar,
           confirm_dialog, section_card,
           grouped_buttons_view                # 위젯
```

상세 빌드/프로토콜 정보는 [README.md](README.md) 참고.
