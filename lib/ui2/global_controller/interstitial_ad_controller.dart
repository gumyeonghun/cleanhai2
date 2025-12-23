// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
//
// class InterstitialAdController extends GetxController {
//   var instertitialAd = Rx<InterstitialAd?>(null);
//
//   int _numLoadAttempts = 0;
//   static const int _maxFailedLoadAttempts = 3;
//
//   @override
//   void onInit() {
//     super.onInit();
//
//     loadAd();
//   }
//
//   void loadAd() async {
//     await MobileAds.instance.initialize();
//     InterstitialAd.load(
//       adUnitId: 'ca-app-pub-3940256099942544/1033173712',
//       request: const AdRequest(),
//       adLoadCallback: InterstitialAdLoadCallback(
//         onAdLoaded: (InterstitialAd ad) {
//           debugPrint('Ad was loaded.');
//           instertitialAd.value = ad;
//           _numLoadAttempts = 0; // 로드 성공 시 카운트 초기화
//
//           // 광고 이벤트 콜백 설정
//           ad.fullScreenContentCallback = FullScreenContentCallback(
//             onAdDismissedFullScreenContent: (InterstitialAd ad) {
//               debugPrint('Ad dismissed.');
//               ad.dispose();
//               loadAd(); // 광고가 닫히면 다음 광고 미리 로드
//             },
//             onAdFailedToShowFullScreenContent:
//                 (InterstitialAd ad, AdError error) {
//               debugPrint('Ad failed to show: $error');
//               ad.dispose();
//               loadAd(); // 보여주기 실패 시에도 다시 로드
//             },
//           );
//         },
//         onAdFailedToLoad: (LoadAdError error) {
//           debugPrint('Ad failed to load with error: $error');
//           _numLoadAttempts += 1;
//           instertitialAd.value = null;
//
//           if (_numLoadAttempts <= _maxFailedLoadAttempts) {
//             final delay = Duration(seconds: 4);
//             debugPrint(
//               'Retrying to load ad in $delay... (Attempt $_numLoadAttempts)',
//             );
//
//             Future.delayed(delay, () {
//               loadAd();
//             });
//           }
//         },
//       ),
//     );
//   }
//
//   Future<void> showAd() async {
//     if (instertitialAd.value != null) {
//       await instertitialAd.value!.show();
//       instertitialAd.value = null;
//     }
//   }
// }
