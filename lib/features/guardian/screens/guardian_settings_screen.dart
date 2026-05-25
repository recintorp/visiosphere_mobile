import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/guardian_provider.dart';
import '../providers/guardian_settings_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/api_constants.dart';

class GuardianSettingsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const GuardianSettingsScreen({super.key, this.onMenuTap});

  @override
  State<GuardianSettingsScreen> createState() => _GuardianSettingsScreenState();
}

class _GuardianSettingsScreenState extends State<GuardianSettingsScreen> with AutomaticKeepAliveClientMixin {
  String _cacheSize = 'Calculating...';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      double totalSize = 0;
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true, followLinks: false).forEach((FileSystemEntity entity) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }
      if (mounted) {
        setState(() {
          _cacheSize = '${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cacheSize = 'Unknown');
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true, followLinks: false).forEach((FileSystemEntity entity) {
          if (entity is File) {
            entity.deleteSync();
          }
        });
      }
      setState(() {
        _cacheSize = '0.00 MB';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to clear cache.'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _pickAndUploadImage(BuildContext context, GuardianProvider provider) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final file = File(image.path);
      final success = await provider.uploadProfilePhoto(file);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Profile photo updated!' : 'Failed to upload photo.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showProfileUpdateSheet(BuildContext context, ThemeData theme) {
    final provider = context.read<GuardianProvider>();
    final guardianData = provider.guardianData;
    
    final firstNameController = TextEditingController(text: guardianData?['firstName'] ?? '');
    final lastNameController = TextEditingController(text: guardianData?['lastName'] ?? '');
    final emailController = TextEditingController(text: guardianData?['email'] ?? '');
    final phoneController = TextEditingController(text: guardianData?['phone'] ?? '');
    
    String? selectedBirthdayStr;
    if (guardianData?['birthday'] != null) {
      try {
        selectedBirthdayStr = DateTime.parse(guardianData!['birthday']).toLocal().toString().split(' ')[0];
      } catch (_) {}
    }
    
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Update Profile',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await _pickAndUploadImage(context, provider);
                          setModalState(() {}); 
                        },
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          backgroundImage: guardianData?['profilePhoto'] != null
                              ? NetworkImage('${ApiConstants.baseUrl.replaceAll('/api', '')}${guardianData!['profilePhoto']}')
                              : null,
                          child: guardianData?['profilePhoto'] == null
                              ? Icon(Icons.camera_alt, color: theme.colorScheme.primary)
                              : null,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: firstNameController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: const InputDecoration(labelText: 'First Name', prefixIcon: Icon(Icons.person_outline)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: lastNameController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: const InputDecoration(labelText: 'Last Name', prefixIcon: Icon(Icons.person_outline)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(1980),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: theme.colorScheme,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedBirthdayStr = picked.toIso8601String().split('T')[0];
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Birthday',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      child: Text(
                        selectedBirthdayStr ?? 'Select Date',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        final email = emailController.text.trim();
                        if (email.isEmpty || !email.contains('@') || firstNameController.text.isEmpty || lastNameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required fields correctly.'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        setModalState(() => isLoading = true);
                        
                        final success = await provider.updateProfileInfo(
                          firstName: firstNameController.text.trim(),
                          lastName: lastNameController.text.trim(),
                          email: email,
                          phone: phoneController.text.trim(),
                          birthday: selectedBirthdayStr,
                        );
                        
                        if (context.mounted) {
                          setModalState(() => isLoading = false);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Profile updated successfully!' : 'Failed to update profile.'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading 
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _showEmergencyContactSheet(BuildContext context, ThemeData theme) {
    final provider = context.read<GuardianProvider>();
    final emergencyData = provider.guardianData?['emergencyContact'] ?? {};
    
    final nameController = TextEditingController(text: emergencyData['name'] ?? '');
    final phoneController = TextEditingController(text: emergencyData['phone'] ?? '');
    final relationshipController = TextEditingController(text: emergencyData['relationship'] ?? '');
    
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Contact',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  'Who should the facility call if you are unreachable?',
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: relationshipController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: const InputDecoration(labelText: 'Relationship (e.g., Sister, Son)', prefixIcon: Icon(Icons.family_restroom)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      setModalState(() => isLoading = true);
                      
                      final success = await provider.updateEmergencyContact(
                        name: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        relationship: relationshipController.text.trim(),
                      );
                      
                      if (context.mounted) {
                        setModalState(() => isLoading = false);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Emergency Contact saved!' : 'Failed to save contact.'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading 
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2))
                        : const Text('Save Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showPasswordChangeSheet(BuildContext context, ThemeData theme) {
    final provider = context.read<GuardianProvider>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Password',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: oldPasswordController,
                  obscureText: obscureOld,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_clock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setModalState(() => obscureOld = !obscureOld),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setModalState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      final oldPass = oldPasswordController.text;
                      final newPass = newPasswordController.text;
                      final confPass = confirmPasswordController.text;

                      if (oldPass.isEmpty || newPass.isEmpty || confPass.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields.'), backgroundColor: Colors.red));
                        return;
                      }

                      if (newPass != confPass) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match.'), backgroundColor: Colors.red));
                        return;
                      }

                      if (newPass.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters.'), backgroundColor: Colors.red));
                        return;
                      }

                      setModalState(() => isLoading = true);
                      final success = await provider.changePassword(oldPass, newPass);
                      
                      if (context.mounted) {
                        setModalState(() => isLoading = false);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Password changed successfully!' : 'Incorrect current password or server error.'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading 
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2))
                        : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showAboutDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/visio.png',
                height: 60,
                color: theme.brightness == Brightness.dark ? Colors.white : null,
              ),
              const SizedBox(height: 20),
              Text(
                'VisioSphere V 1.0.0',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              Text(
                'VisioSphere is an advanced eldercare monitoring system designed for real-time health and safety tracking. Built to provide families with peace of mind and empower caregivers with actionable insights.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Close'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomAppBar(ThemeData theme) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.menu, color: theme.colorScheme.primary),
            onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
          ),
          Expanded(
            child: Text(
              'Settings',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final settingsProvider = context.watch<GuardianSettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final guardianProvider = context.watch<GuardianProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(theme),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: _buildSectionHeader('ACCOUNT & SECURITY', theme),
                    ),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: _buildSettingsCard(
                        theme: theme,
                        children: [
                          _buildActionTile(
                            icon: Icons.person_outline,
                            title: 'Profile Information',
                            subtitle: 'Update details and profile picture',
                            theme: theme,
                            onTap: () => _showProfileUpdateSheet(context, theme),
                          ),
                          _buildDivider(theme),
                          _buildActionTile(
                            icon: Icons.lock_outline,
                            title: 'Change Password',
                            subtitle: 'Manage your security credentials',
                            theme: theme,
                            onTap: () => _showPasswordChangeSheet(context, theme),
                          ),
                          _buildDivider(theme),
                          _buildActionTile(
                            icon: Icons.contact_phone_outlined,
                            title: 'Emergency Contacts',
                            subtitle: 'Who we call if you are unreachable',
                            theme: theme,
                            onTap: () => _showEmergencyContactSheet(context, theme),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: _buildSectionHeader('APPEARANCE', theme),
                    ),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 250),
                      child: _buildSettingsCard(
                        theme: theme,
                        children: [
                          _buildThemeSelector(themeProvider, guardianProvider, theme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                      child: _buildSectionHeader('NOTIFICATIONS', theme),
                    ),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                      child: _buildSettingsCard(
                        theme: theme,
                        children: [
                          _buildSwitchTile(
                            icon: Icons.notifications_active_outlined,
                            title: 'Push Notifications',
                            subtitle: 'Real-time alerts on this device',
                            value: settingsProvider.pushEnabled,
                            theme: theme,
                            onChanged: (val) => settingsProvider.togglePushNotifications(val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 500),
                      child: _buildSectionHeader('SYSTEM', theme),
                    ),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 600),
                      child: _buildSettingsCard(
                        theme: theme,
                        children: [
                          _buildActionTile(
                            icon: Icons.info_outline,
                            title: 'About VisioSphere',
                            subtitle: 'Version 1.0.0',
                            theme: theme,
                            onTap: () => _showAboutDialog(context, theme),
                          ),
                          _buildDivider(theme),
                          _buildActionTile(
                            icon: Icons.cleaning_services_outlined,
                            title: 'Clear Cache',
                            subtitle: 'Free up local storage space',
                            trailingText: _cacheSize,
                            theme: theme,
                            onTap: _clearCache,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title, 
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.w800, 
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
        )
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children, required ThemeData theme}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildThemeSelector(ThemeProvider themeProvider, GuardianProvider guardianProvider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select App Theme',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildThemeButton(ThemeMode.system, Icons.brightness_auto, 'Auto', themeProvider, guardianProvider, theme)),
              const SizedBox(width: 12),
              Expanded(child: _buildThemeButton(ThemeMode.light, Icons.light_mode, 'Light', themeProvider, guardianProvider, theme)),
              const SizedBox(width: 12),
              Expanded(child: _buildThemeButton(ThemeMode.dark, Icons.dark_mode, 'Dark', themeProvider, guardianProvider, theme)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton(ThemeMode mode, IconData icon, String label, ThemeProvider themeProvider, GuardianProvider guardianProvider, ThemeData theme) {
    final isSelected = themeProvider.themeMode == mode;
    return GestureDetector(
      onTap: () async {
        String themeStr = 'default';
        String dbThemeStr = 'Auto';
        
        if (mode == ThemeMode.light) {
          themeStr = 'light';
          dbThemeStr = 'Light';
        }
        if (mode == ThemeMode.dark) {
          themeStr = 'dark';
          dbThemeStr = 'Dark';
        }
        
        themeProvider.setTheme(themeStr);
        await guardianProvider.updateAppTheme(dbThemeStr);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant, 
              size: 28
            ),
            const SizedBox(height: 8),
            Text(
              label, 
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.bold, 
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailingText,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: theme.colorScheme.primary, size: 24),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(trailingText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8))),
          if (trailingText != null) const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ThemeData theme,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: theme.colorScheme.primary, size: 24),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: theme.colorScheme.onPrimary,
        activeTrackColor: theme.colorScheme.primary,
        inactiveThumbColor: theme.colorScheme.onSurface,
        inactiveTrackColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(height: 1, thickness: 1, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1), indent: 76, endIndent: 20);
  }
}