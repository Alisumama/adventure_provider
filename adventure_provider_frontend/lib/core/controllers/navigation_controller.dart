import 'package:get/get.dart';

/// Drives the main shell bottom navigation [currentIndex].
class NavigationController extends GetxController {
  static const int tabHome = 0;
  static const int tabTrack = 1;
  static const int tabCommunity = 2;
  static const int tabProfile = 3;

  final RxInt currentIndex = 0.obs;

  void setIndex(int index) => changePage(index);

  /// Bottom navigation: updates [currentIndex] for [IndexedStack].
  void changePage(int index) {
    if (index < 0 || index > tabProfile) return;
    currentIndex.value = index;
  }
}
