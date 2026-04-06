import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../../../core/constants/colors.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<OnboardingProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  // Skip Button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Page View
                  Expanded(
                    child: PageView(
                      controller: provider.pageController,
                      onPageChanged: provider.updatePage,
                      children: [
                        _buildOnboardingPage(
                          context,
                          title: 'Welcome to',
                          mainTitle: 'VISIOSPHERE',
                          icon: Icons.people,
                          description:
                              'Connecting hearts, ensuring care.\nYour loved ones deserve the best.',
                        ),
                        _buildOnboardingPage(
                          context,
                          title: 'Real-time Support',
                          mainTitle: 'CARE MONITORING',
                          icon: Icons.security,
                          description:
                              'Monitor daily reports and get serious\nincident notifications instantly.',
                        ),
                        _buildOnboardingPage(
                          context,
                          title: 'Stay Connected',
                          mainTitle: 'DIRECT CHAT',
                          icon: Icons.chat,
                          description:
                              'Communicate directly with assigned\ncaregivers through our secure chat\nmodule.',
                        ),
                      ],
                    ),
                  ),
                  // Page Indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: SmoothPageIndicator(
                      controller: provider.pageController,
                      count: 3,
                      effect: ExpandingDotsEffect(
                        dotColor: AppColors.textWhite.withOpacity(0.4),
                        activeDotColor: AppColors.textWhite,
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 8,
                      ),
                    ),
                  ),
                  // Next/Let's Go Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (provider.currentPage == 2) {
                            context.go('/login');
                          } else {
                            provider.pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          provider.currentPage == 2 ? "Let's Go" : 'Next',
                          style: const TextStyle(
                            color: AppColors.gradientEnd,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(
    BuildContext context, {
    required String title,
    required String mainTitle,
    required IconData icon,
    required String description,
  }) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 100),
              child: Text(
                mainTitle,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 200),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.textWhite.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(
                  icon,
                  size: 70,
                  color: AppColors.textWhite,
                ),
              ),
            ),
            const SizedBox(height: 48),
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 300),
              child: Text(
                description,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 16,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}