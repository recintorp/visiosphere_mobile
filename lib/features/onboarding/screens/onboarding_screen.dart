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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 16),
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: provider.pageController,
                      onPageChanged: provider.updatePage,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildOnboardingPage(
                          context,
                          title: 'Welcome to',
                          mainTitle: 'VISIOSPHERE',
                          icon: Icons.family_restroom_rounded,
                          description: 'Connecting hearts, ensuring care.\nYour loved ones deserve the best.',
                        ),
                        _buildOnboardingPage(
                          context,
                          title: 'Real-time Support',
                          mainTitle: 'CARE MONITORING',
                          icon: Icons.health_and_safety_rounded,
                          description: 'Monitor daily reports and get serious\nincident notifications instantly.',
                        ),
                        _buildOnboardingPage(
                          context,
                          title: 'Stay Connected',
                          mainTitle: 'DIRECT CHAT',
                          icon: Icons.chat_bubble_outline_rounded,
                          description: 'Communicate directly with assigned\ncaregivers through our secure module.',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: SmoothPageIndicator(
                      controller: provider.pageController,
                      count: 3,
                      effect: ExpandingDotsEffect(
                        dotColor: AppColors.textWhite.withValues(alpha: 0.3),
                        activeDotColor: AppColors.textWhite,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 4,
                        spacing: 8,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (provider.currentPage == 2) {
                            context.go('/login');
                          } else {
                            provider.pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutCubic,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textWhite,
                          foregroundColor: AppColors.gradientEnd,
                          elevation: 8,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              provider.currentPage == 2 ? "Get Started" : 'Next Step',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              provider.currentPage == 2 ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                          ],
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
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: AppColors.textWhite.withValues(alpha: 0.8),
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
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
                  fontWeight: FontWeight.w900,
                  fontSize: 36,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 60),
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 200),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textWhite.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.textWhite.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 72,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 300),
              child: Text(
                description,
                style: TextStyle(
                  color: AppColors.textWhite.withValues(alpha: 0.9),
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