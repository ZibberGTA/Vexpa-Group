import 'package:flutter/material.dart';

class HomeNavigationService {
  static final ValueNotifier<int> selectedTabIndex = ValueNotifier<int>(0);

  static void goHome(BuildContext context) {
    selectedTabIndex.value = 0;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
