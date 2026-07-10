import 'package:flutter/material.dart';

import '../navigation/home_navigation_service.dart';

class HomeIconButton extends StatelessWidget {
  const HomeIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back to map',
      icon: const Icon(Icons.home_outlined),
      onPressed: () => HomeNavigationService.goHome(context),
    );
  }
}
