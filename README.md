# 청소5분대기조 (CleanHai2)

**청소5분대기조**는 숙박업소, 사무실, 건물 등 다양한 공간의 청소 의뢰인과 전문 청소 인력을 연결해주는 O2O 플랫폼입니다.
위치 기반 매칭, 실시간 의뢰 등록, 전문가 프로필 관리 등을 통해 빠르고 효율적인 청소 서비스를 제공합니다.

## 📱 주요 기능

### 1. 홈 (청소 의뢰 목록)
- **의뢰 탐색**: 등록된 청소 의뢰를 리스트 형태로 확인합니다.
- **필터링**: 청소 종류(숙박업소, 사무실 등)별로 필터링하여 볼 수 있습니다.
- **검색**: 제목, 내용, 주소 등으로 원하는 의뢰를 검색할 수 있습니다.
- **위치 기반 정렬**: 사용자의 현재 위치를 기반으로 가까운 의뢰 순으로 정렬됩니다.

### 2. 대기중인 청소 전문가
- **전문가 찾기**: 현재 작업 가능한 청소 전문가 목록을 확인합니다.
- **프로필 확인**: 전문가의 평점, 리뷰 수, 경력 등을 확인할 수 있습니다.
- **즉시 의뢰**: 마음에 드는 전문가에게 직접 청소를 의뢰할 수 있습니다.

### 3. 의뢰 및 전문가 등록
- **간편 등록**: 사진, 위치, 금액, 청소 내용 등을 입력하여 손쉽게 의뢰를 등록합니다.
- **자동 등록**: 요일과 시간을 설정해두면 매주 자동으로 의뢰나 대기 상태가 등록되는 편의 기능을 제공합니다.

### 4. 결제 및 정산
- **안전 결제**: Toss Payments 연동을 통해 안전하게 결제할 수 있습니다.
- **정산 관리**: 전문가는 완료된 작업에 대한 정산 내역을 투명하게 확인할 수 있습니다.

## 🏗 프로젝트 구조 (Architecture)

이 프로젝트는 **Flutter** 프레임워크와 **GetX** 상태 관리 라이브러리를 사용하여 개발되었습니다.
유지보수와 확장성을 고려하여 **Clean Architecture**의 개념을 도입한 계층형 구조를 따릅니다.

### 📂 폴더 구조

```
lib/
├── data/                  # 데이터 계층 (Data Layer)
│   ├── model/             # 데이터 모델 (DTO)
│   │   ├── cleaning_request.dart  # 청소 의뢰 모델
│   │   ├── cleaning_staff.dart    # 청소 전문가 모델
│   │   └── user_model.dart        # 사용자 모델
│   └── repository/        # 데이터 저장소 (Firebase 통신)
│       ├── cleaning_repository.dart
│       └── ...
│
├── service/               # 서비스 계층 (Service Layer)
│   ├── auth_service.dart  # 인증 관련 로직
│   └── ...
│
├── ui/                    # UI 계층 (Presentation Layer)
│   ├── page/              # 화면 단위 폴더
│   │   ├── cleaning/      # 청소 관련 페이지 모음
│   │   │   ├── home/      # 홈 화면 (의뢰 목록)
│   │   │   ├── detail/    # 상세 화면
│   │   │   ├── staff_waiting/ # 전문가 대기 목록
│   │   │   └── write/     # 글쓰기 화면
│   │   ├── profile/       # 프로필 화면
│   │   └── ...
│   └── widgets/           # 공통 위젯
│
└── utils/                 # 유틸리티 (위치 계산 등)
```

### 🛠 기술 스택 (Tech Stack)

- **Framework**: Flutter
- **Language**: Dart
- **State Management**: GetX (Reactive State Management)
- **Backend / DB**: Firebase (Authentication, Firestore, Storage)
- **Payment**: Toss Payments
- **Location**: Geolocator (위치 기반 서비스)

## 💡 개발 컨벤션

- **Naming**: 파일명은 `snake_case`, 클래스명은 `PascalCase`, 변수명은 `camelCase`를 사용합니다.
- **Pattern**: MVVM 패턴을 기반으로 View(Page)와 ViewModel(Controller)을 분리하여 개발합니다.
- **Dependency Injection**: GetX의 Dependency Management(`Get.put`, `Get.find`)를 적극 활용합니다.

## 🚀 시작하기

1. 프로젝트 클론: `git clone [repository_url]`
2. 패키지 설치: `flutter pub get`
3. 앱 실행: `flutter run`
