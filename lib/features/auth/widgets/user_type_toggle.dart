import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../providers/auth_provider.dart';

class UserTypeToggle extends StatelessWidget {
  final UserType selectedUserType;
  final Function(UserType) onUserTypeChanged;

  const UserTypeToggle({
    super.key,
    required this.selectedUserType,
    required this.onUserTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textHint),
      ),
      child: Row(
        children: [
          _buildToggleButton(
            context,
            label: 'Admin',
            userType: UserType.admin,
            color: AppColors.adminColor,
          ),
          _buildToggleButton(
            context,
            label: 'Nurse',
            userType: UserType.nurse,
            color: AppColors.nurseColor,
          ),
          _buildToggleButton(
            context,
            label: 'Guardian',
            userType: UserType.guardian,
            color: AppColors.guardianColor,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context, {
    required String label,
    required UserType userType,
    required Color color,
  }) {
    final isSelected = selectedUserType == userType;

    return Expanded(
      child: GestureDetector(
        onTap: () => onUserTypeChanged(userType),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textLight,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}