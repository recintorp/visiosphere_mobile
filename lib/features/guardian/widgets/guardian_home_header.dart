import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/guardian_provider.dart';
import '../../../core/constants/api_constants.dart';

class GuardianHomeHeader extends StatelessWidget {
  const GuardianHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<GuardianProvider>();
    final guardianData = provider.guardianData;

    final String fullName = guardianData != null 
        ? '${guardianData['firstName']} ${guardianData['lastName']}'
        : 'Loading...';
    final String guardianId = guardianData != null ? guardianData['guardianId'] : '...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'ID: $guardianId',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          FadeInRight(
            duration: const Duration(milliseconds: 800),
            child: _buildProfileImage(guardianData?['profilePhoto'], theme),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? photoUrl, ThemeData theme) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      final fullUrl = photoUrl.startsWith('http') 
          ? photoUrl 
          : '${ApiConstants.baseUrl.replaceAll('/api', '')}$photoUrl';
          
      return Container(
        height: 75,
        width: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
          image: DecorationImage(
            image: NetworkImage(fullUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    
    return Container(
      height: 75,
      width: 75,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
    );
  }
}