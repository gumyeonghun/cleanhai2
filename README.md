# CleanHai2 (클린하이 2.0)

## 👋 프로젝트 소개 (Introduction)
**CleanHai2**는 청소가 필요한 고객(집주인/Owner)과 전문 청소 매니저(Staff)를 연결해주는 **청소 및 정리수납 중개 플랫폼**입니다.
누구나 쉽게 청소를 의뢰하고, 검증된 전문가에게 서비스를 받을 수 있도록 돕습니다. 또한, 청소 매니저는 자신의 일정을 관리하고 수익을 창출할 수 있습니다.

### 💡 주요 기능 (Key Features)
*   **사용자 유형 분리**: `Owner`(의뢰인)와 `Staff`(청소 매니저)로 구분하여 맞춤형 UI/UX 제공.
*   **실시간 매칭 시스템**:
    *   Owner가 청소 요청(Request)을 등록하면 주변 Staff에게 노출.
    *   Staff가 대기 목록(Waiting List)에 등록하면 Owner가 프로필을 보고 요청 가능.
*   **채팅 (Chat)**: 매칭 전/후 실시간 대화 기능 (이미지 전송 지원).
*   **결제 (Payments)**: Toss Payments 연동을 통한 안전한 카드 결제 시스템.
*   **위치 기반 매칭**: 사용자 위치 기반으로 가까운 매니저/의뢰인을 추천.
*   **리뷰 및 평점**: 서비스 완료 후 상호 평가 시스템.

---

## 🛠 기술 스택 (Tech Stack)

### Front-end (App)
*   **Framework**: [Flutter](https://flutter.dev/)
*   **Language**: Dart
*   **State Management**: **[GetX](https://pub.dev/packages/get)**
    *   상태 관리(`Rx`, `.obs`), 의존성 주입(`Get.put`), 라우팅(`Get.to`) 등 앱 전반의 코어를 담당합니다.

### Back-end (Serverless)
*   **Platform**: [Firebase](https://firebase.google.com/)
*   **Database**: Cloud Firestore (NoSQL)
*   **Auth**: Firebase Authentication (Email, Kakao, Apple, Google)
*   **Storage**: Cloud Storage (이미지 저장)
*   **Server Logic**: Cloud Functions (푸시 알림 등)

### Major Libraries
*   `tosspayments_widget_sdk_flutter`: 토스 페이먼츠 결제 연동
*   `kakao_flutter_sdk`: 카카오 로그인
*   `kpostal` / `geocoding`: 도로명 주소 검색 및 좌표 변환

---

## 📂 프로젝트 상세 구조 및 파일 설명 (File Structure Guide)
신규 입사자를 위해 프로젝트의 주요 폴더와 파일을 상세히 설명합니다.

### 1. `lib/data` (Data Layer)
데이터 모델과 외부 데이터 소스(Firebase)와의 통신을 담당합니다.

#### `lib/data/model` (데이터 모델)
*   **`user_model.dart`**: 사용자 정보(User) 모델. `userType` 필드로 'owner'/'staff'를 구분하며, 주소 및 프로필 정보를 포함합니다.
*   **`cleaning_request.dart`**: 청소 의뢰(Request) 정보 모델. 청소 날짜, 시간, 평수, 가격, 상태(매칭 대기, 완료 등) 정보를 담습니다.
*   **`cleaning_staff.dart`**: 청소 매니저(Staff) 프로필 모델. 근무 가능 지역, 경력, 소개글 등을 포함합니다.
*   **`chat_room.dart`**: 채팅방 모델. 참여자(users) 정보와 마지막 메시지 등을 관리합니다.
*   **`chat_message.dart`**: 개별 채팅 메시지 모델. 보낸 사람 ID, 내용, 타임스탬프, 이미지(선택) 등을 포함합니다.
*   **`review.dart`**: 청소 완료 후 작성되는 리뷰 및 평점 데이터 모델.
*   **`cleaning_knowhow.dart`**: (확장 기능) 청소 노하우 게시글 모델.
*   **`cleaning_recommendation.dart`**: (확장 기능) 추천/랭킹 관련 모델.
*   **`completion_report.dart`**: 청소 완료 후 매니저가 작성하는 완료 보고서 모델.
*   **`progress_note.dart`**: 진행 상황 기록용 모델.

#### `lib/data/repository` (데이터 저장소)
*   **`cleaning_repository.dart`**: 청소 요청(CleaningRequest) 및 매니저(CleaningStaff) 데이터의 CRUD(생성/조회/수정/삭제)를 담당하는 핵심 저장소입니다. Firestore의 `cleaning_requests`, `cleaning_staffs` 컬렉션과 통신합니다.
*   **`chat_repository.dart`**: 채팅방 생성, 메시지 전송 및 수신(Stream) 로직을 처리합니다. Firestore의 `chat_rooms` 컬렉션을 관리합니다.

### 2. `lib/service` (Service Layer)
앱 전반에서 공통적으로 사용되는 비즈니스 로직이나 외부 SDK 래퍼(Wrapper)입니다.
*   **`toss_payment_service.dart`**: 토스 페이먼츠 결제 요청 및 승인/실패 처리를 담당하는 서비스입니다.

### 3. `lib/ui` (Presentation Layer)
화면(UI)과 사용자의 인터랙션을 처리하는 계층입니다.

#### `lib/ui/page/auth` (인증)
*   **`login_signup_page.dart`**: 로그인 및 회원가입 화면. 이메일, 카카오, 애플, 구글 로그인을 모두 처리하며 `Obx`를 통해 화면 전환(로그인<->회원가입)을 관리합니다.
*   **`auth_controller.dart`**: 인증 로직의 핵심. Firebase Auth 및 Firestore 사용자 생성을 직접 처리합니다.
    *   `signInWithKakao()`, `signInWithApple()`, `signInWithGoogle()`: 소셜 로그인 구현.
    *   `submitForm()`: 이메일 회원가입/로그인 처리.

#### `lib/ui/page/main` (메인)
*   **`main_page.dart`**: 앱의 메인 뼈대(Scaffold). BottomNavigationBar(홈, 채팅, 프로필 등)를 포함하며 탭 전환을 관리합니다.
*   **`main_controller.dart`**: 현재 선택된 탭 인덱스(`currentIndex`)를 관리합니다.

#### `lib/ui/page/cleaning` (청소 관련 핵심 기능)
청소 서비스의 핵심 기능들이 모여 있는 폴더입니다.
*   **`home/`**:
    *   **`home_page.dart`**: 앱 실행 시 첫 화면. 사용자 유형(Owner/Staff)에 따라 다른 목록을 보여줍니다.
        *   Owner에게는 주변 매니저 목록(`StaffWaitingList`)을, Staff에게는 주변 청소 요청(`CleaningRequestList`)을 보여줍니다.
    *   **`home_controller.dart`**: 홈 화면의 데이터 로딩 및 필터링 로직을 담당합니다.
*   **`detail/`**: 청소 요청 상세 내역 화면.
*   **`write/`**: 청소 요청(글) 작성 화면.
*   **`chat/`**: 채팅 목록 및 채팅방 화면.
*   **`profile/`**: 내 정보(프로필) 관리 및 설정 화면.
*   **`history/`**: 이용 내역 및 결제 내역 확인.
*   **`review/`**: 리뷰 작성 및 조회.
*   **`staff_waiting/`**: 매니저가 구직 등록(대기 등록)을 하는 화면.

### 4. `lib/utils` (Utilities)
*   **`location_utils.dart`**: 위치 관련 헬퍼 함수. 좌표 간 거리 계산이나 주소 포맷팅 등을 단순화합니다.

---

## 📝 개발 컨벤션 (Conventions)
1.  **네이밍 규칙**:
    *   파일: `snake_case` (예: `auth_controller.dart`)
    *   클래스: `PascalCase` (예: `AuthController`)
    *   변수/함수: `camelCase` (예: `isLoading`)
2.  **아키텍처 규칙**:
    *   **View(Page)**는 오직 **Controller**하고만 대화합니다. Repository를 직접 호출하지 마세요.
    *   **Controller**는 UI 상태(`Rx`)를 관리하고 Repository를 호출하여 데이터를 가져옵니다.
    *   **GetX** 사용 시 `Get.put()`으로 컨트롤러를 의존성 주입하고, `Obx(() => ...)`로 UI를 감싸 반응형으로 만듭니다.

---

## 🚀 시작 가이드 (Getting Started)
1.  `pubspec.yaml`의 의존성을 설치합니다: `flutter pub get`
2.  `lib/main.dart`를 실행하여 앱을 시작합니다.
3.  개발 시 `debugPrint`를 사용하여 로그를 확인하세요.

---

## 🤝 기여 및 문의
프로젝트 구조나 코드에 대해 궁금한 점이 있다면 언제든 이슈를 등록하거나 팀에게 문의해주세요. 함께 더 좋은 서비스를 만들어갑시다! 🚀
