import 'package:flutter/material.dart';

class OnboardingProvider extends ChangeNotifier {
  late PageController pageController;
  int _currentPage = 0;

  int get currentPage => _currentPage;

  OnboardingProvider() {
    pageController = PageController();
  }

  void updatePage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}