CLAUDE.md(GEMINI.md) 예시 및 작성 방법
이 문서는 프로젝트의 구조, 컨벤션, 그리고 개발 가이드라인을 설명합니다. AI 코딩 어시스턴트에게 이 파일을 컨텍스트로 제공하면 프로젝트 스타일에 맞는 코드를 생성하는 데 도움이 됩니다.
개발 컨벤션 (Development Conventions)
1. 네이밍 규칙 (Naming Conventions)
   파일명 (File Names): snake_case를 사용합니다. (예: post_repository.dart, home_page.dart)
   클래스명 (Class Names): PascalCase를 사용합니다. (예: PostRepository, HomePage)
   변수/함수명 (Variable/Function Names): camelCase를 사용합니다. (예: fetchPosts(), isLoading)
2. 상태 관리 및 라우팅 (State Management & Routing)
   GetX: 상태 관리, 의존성 주입(DI), 라우팅에 모두 GetX를 사용합니다.
   Reactive State: 단순 상태(GetBuilder)보다는 반응형 상태(Rx, .obs, Obx) 사용을 권장합니다.
   Controller: UI의 상태(Rx)를 관리하고 사용자 이벤트를 처리합니다. 직접적인 비즈니스 로직보다는 Repository나 Service를 호출하여 로직을 수행하고, 그 결과를 UI에 반영하는 조율자(Orchestrator) 역할을 합니다.
   Routing: Named Route 대신 Get.to((Page())를 사용하여 직관적으로 라우팅합니다.
3. 아키텍처 (Architecture)
   이 프로젝트는 관심사 분리(Separation of Concerns)를 위해 다음과 같은 계층 구조를 따릅니다:
   Data Layer (lib/data): 데이터 처리와 관련된 로직을 담당합니다.
   model: 데이터 구조 정의 (DTO). fromJson, toJson 메서드를 포함합니다.
   repository: 데이터 소스(Firebase 등)와의 직접적인 통신(CRUD)을 담당합니다.
   Service Layer (lib/service): 앱 전역에서 사용되는 로직이나 외부 도구(Tool) 기능을 담당합니다.
   예: AuthService (인증), ImageService (이미지 피커), PermissionService (권한 관리) 등.
   주로 GetxService를 상속받아 구현하며, 앱 시작 시 메모리에 상주하거나 필요할 때 로드됩니다.
   UI Layer (lib/ui): 화면 구성과 사용자 상호작용을 담당합니다.
   page: 각 화면(Page) 단위로 폴더를 구성합니다.
   widgets: 여러 페이지에서 재사용되는 공통 위젯을 관리합니다.
4. 의존성 가이드라인 (Dependency Guidelines)
   계층 간의 의존성 방향을 지키면 코드가 꼬이는 것을 방지할 수 있습니다.
   Controller (조율자):
   가능: Service, Repository를 호출할 수 있습니다.
   역할: UI의 요청을 받아 Service와 Repository를 적절히 호출하고, 그 결과를 UI 상태에 반영합니다. 서로 다른 Service 간의 데이터 전달도 Controller가 중재하는 것이 좋습니다.
   Service (도구/로직):
   가능: Repository를 호출할 수 있습니다. (다른 Service 호출은 지양하고 Controller가 조율하도록 권장)
   불가능: Controller나 Page(UI)를 호출하면 안 됩니다.
   Repository (데이터):
   불가능: Controller, Page를 호출하면 안 됩니다.
   권장: Service를 직접 호출하기보다는, 필요한 값(예: userId)을 Controller로부터 파라미터로 전달받는 것이 좋습니다.
   Page (UI):
   가능: 오직 Controller만 호출해야 합니다.
   불가능: Service나 Repository를 직접 호출하지 마세요.
   예시 폴더 구조 (Project Structure)
   lib/
   ├── data/
   │   ├── model/
   │   │   └── post.dart             # 블로그 포스트 데이터 모델
   │   └── repository/
   │       ├── post_repository.dart  # 데이터 통신
   │       └── user_repository.dart  # 사용자 데이터 통신
   ├── service/                      # 공통 비즈니스 로직 및 도구
   │   ├── auth_service.dart         # 로그인/로그아웃 등 인증 로직
   │   └── image_service.dart        # 이미지 선택/압축 등 기능
   ├── ui/
   │   ├── page/
   │   │   ├── home/                 # 홈 화면
   │   │   │   ├── home_page.dart
   │   │   │   └── home_controller.dart
   │   │   └── ...
   │   └── widgets/                  # 공통 위젯
   └── main.dart                     # 앱 진입점
   ​
   개발 워크플로우 (Development Workflow)
   새로운 기능을 추가할 때는 다음 순서를 따르는 것을 권장합니다:
   Model 정의 (lib/data/model): 데이터 구조 정의.
   Repository/Service 구현:
   데이터 통신이 필요하면 Repository를 구현합니다.
   공통 기능이나 도구적 성격의 로직은 Service에 구현합니다.
   Controller 구현 (lib/ui/page/...):
   필요한 Repository와 Service를 주입받습니다.
   UI 상태(Rx)를 정의하고, Repo/Service를 호출하여 데이터를 처리합니다.
   UI 구현 (lib/ui/page/...):
   파라미터가 없는 경우: StatelessWidget을 사용하고 build 메서드 내에서 Get.put으로 Controller를 주입합니다.
   파라미터가 있는 경우: StatefulWidget을 사용하고, 생성자로 파라미터를 받아 initState에서 Controller를 초기화합니다.
   Obx를 사용하여 화면을 구성합니다.
   코드 스니펫 (Code Snippets)
   기본 페이지 구조 (StatelessWidget + Get.put)
   import 'package:flutter/material.dart';
   import 'package:get/get.dart';
   import 'my_controller.dart';

class MyPage extends StatelessWidget {
const MyPage({super.key});

@override
Widget build(BuildContext context) {
// Controller 주입 (Dependency Injection)
final controller = Get.put(MyController());
final repository = Get.put(MyRepository());

    return Scaffold(
      appBar: AppBar(title: const Text('Title')),
      body: Obx(() {
        return Center(child: Text(controller.someState.value));
      }),
    );
}
}
​
파라미터가 있는 페이지 구조 (StatefulWidget + init)
페이지에 파라미터를 전달해야 하는 경우, StatefulWidget을 사용하고 생성자로 데이터를 받습니다.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'my_controller.dart';
import 'my_model.dart';

class MyPage extends StatefulWidget {
final DateTime selectedDate;
final MyModel? data;

const MyPage({
super.key,
required this.selectedDate,
this.data,
});

@override
State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
final MyController controller = Get.put(MyController());

@override
void initState() {
super.initState();
// Controller의 init 메서드로 파라미터 전달
controller.init(widget.selectedDate, widget.data);
}



@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Title')),
body: Obx(() {
return Center(child: Text(controller.someState.value));
}),
);
}
}
​
Controller에서는 init 메서드를 제공합니다:
class MyController extends GetxController {
DateTime? selectedDate;
MyModel? data;

void init(DateTime date, MyModel? model) {
selectedDate = date;
data = model;

    // 초기화 로직
    if (data != null) {
      // 수정 모드
    } else {
      // 생성 모드
    }
}
}
​
라우팅 시에는 생성자로 파라미터를 전달합니다:
// Controller에서
void goToMyPage() {
Get.to(() => MyPage(
selectedDate: DateTime.now(),
data: someData,
));
}
​
기본 서비스 구조 (GetxService)
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ImageService extends GetxService {
final ImagePicker _picker = ImagePicker();

// 갤러리에서 이미지 선택
Future<XFile?> pickImage() async {
return await _picker.pickImage(source: ImageSource.gallery);
}
}
​
기본 컨트롤러 구조 (GetxController)
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // XFile 사용을 위해 필요
import '../../data/repository/post_repository.dart';
import '../../service/auth_service.dart';
import '../../service/image_service.dart';

class MyController extends GetxController {
// Repository & Service 주입 (Dependency Injection)
final PostRepository _postRepository = Get.find<PostRepository>();
final AuthService _authService = Get.find<AuthService>();
final ImageService _imageService = Get.find<ImageService>();

final RxList posts = [].obs;
final RxBool isLoading = false.obs;
final Rx<XFile?> selectedImage = Rx<XFile?>(null);

@override
void onInit() {
super.onInit();
fetchPosts();
}

void fetchPosts() async {
isLoading.value = true;
try {
// Repository를 통해 데이터 요청
var result = await _postRepository.getPosts();
posts.assignAll(result);
} finally {
isLoading.value = false;
}
}

void onImagePick() async {
// Service를 통해 이미지 선택 로직 수행
var image = await _imageService.pickImage();
if (image != null) {
selectedImage.value = image;
}
}

void logout() {
_authService.signOut();
}
}