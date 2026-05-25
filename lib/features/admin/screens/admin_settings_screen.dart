import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_settings_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/theme_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final bool isNurseView;

  const AdminSettingsScreen({super.key, this.onMenuTap, this.isNurseView = false});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nurseIdController = TextEditingController();
  
  bool _dataLoaded = false;
  String _selectedTheme = 'default';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<AdminSettingsProvider>();
    final authProvider = context.read<AuthProvider>();
    
    await provider.fetchSettings();
    
    if (mounted) {
      setState(() {
        _displayNameController.text = provider.displayName.isNotEmpty ? provider.displayName : (authProvider.userName ?? '');
        _selectedTheme = provider.theme;
        _dataLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _nurseIdController.dispose();
    super.dispose();
  }

  void _show2FASetupModal(BuildContext context, AdminSettingsProvider provider, bool isDark) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscurePin = true;
    bool obscureConfirm = true;
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext innerContext, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(innerContext).viewInsets.bottom,
                left: 24, right: 24, top: 32,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4), 
                      border: Border.all(color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFD1FAE5), width: 4), 
                      shape: BoxShape.circle
                    ),
                    child: const Icon(Icons.security, color: Color(0xFF10B981), size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text('Secure 2FA PIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Text('Create a 6-digit PIN to secure your account.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  
                  if (localError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2), 
                        borderRadius: BorderRadius.circular(8), 
                        border: Border.all(color: isDark ? const Color(0xFF881337).withValues(alpha: 0.5) : const Color(0xFFFECACA))
                      ),
                      child: Text(localError!, textAlign: TextAlign.center, style: TextStyle(color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48), fontWeight: FontWeight.bold, fontSize: 13)),
                    ),

                  TextField(
                    controller: pinController,
                    obscureText: obscurePin,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: '••••••', counterText: "", labelText: 'Enter 6-Digit PIN', floatingLabelAlignment: FloatingLabelAlignment.center,
                      labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      hintStyle: TextStyle(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00A8E8)),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePin ? Icons.visibility_off : Icons.visibility, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        onPressed: () {
                          setModalState(() {
                            obscurePin = !obscurePin;
                          });
                        }
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: confirmController,
                    obscureText: obscureConfirm,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: '••••••', counterText: "", labelText: 'Confirm PIN', floatingLabelAlignment: FloatingLabelAlignment.center,
                      labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      hintStyle: TextStyle(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00A8E8)),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)), 
                        onPressed: () {
                          setModalState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        }
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : () async {
                        if (pinController.text.length != 6) {
                          setModalState(() {
                            localError = 'PIN must be exactly 6 digits.';
                          });
                          return;
                        }
                        if (pinController.text != confirmController.text) {
                          setModalState(() {
                            localError = 'PINs do not match.';
                          });
                          return;
                        }
                        setModalState(() {
                          localError = null;
                        });
                        final success = await provider.toggle2FA(true, pin: pinController.text);
                        if (!modalContext.mounted) {
                          return;
                        }
                        if (success) {
                          Navigator.pop(modalContext);
                        } else {
                          setModalState(() {
                            localError = provider.saveMessage ?? 'Failed to enable 2FA';
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: provider.isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Enable Security', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: provider.isLoading ? null : () {
                      Navigator.pop(modalContext);
                    }, 
                    child: Text('Cancel', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.bold))
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeactivateModal(BuildContext context, AdminSettingsProvider provider, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2), 
                  border: Border.all(color: isDark ? const Color(0xFF881337).withValues(alpha: 0.5) : const Color(0xFFFFE4E6), width: 4), 
                  shape: BoxShape.circle
                ),
                child: Icon(Icons.warning_rounded, color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48), size: 32),
              ),
              const SizedBox(height: 16),
              Text('Deactivate Account?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48))),
              const SizedBox(height: 12),
              Text('You will be logged out immediately. Only another Administrator can reactivate your account.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14, height: 1.5)),
              const SizedBox(height: 32),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await provider.deactivateAccount();
                        if (!modalContext.mounted) {
                          return;
                        }
                        if (success) {
                          modalContext.go('/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Yes, Deactivate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(modalContext);
                      },
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text('Cancel', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomAppBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white, 
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)))
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu, color: isDark ? Colors.white : const Color(0xFF00A8E8)),
            onPressed: widget.onMenuTap ?? () {
              Scaffold.of(context).openDrawer();
            },
          ),
          Image.asset('assets/images/visio.png', height: 36, color: isDark ? Colors.white : null, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported)),
          Icon(Icons.notifications_none, color: isDark ? Colors.white : const Color(0xFF00A8E8)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: widget.isNurseView ? 1 : 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Consumer2<AdminSettingsProvider, AuthProvider>(
            builder: (context, provider, authProvider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomAppBar(isDark),
                  
                  Container(
                    width: double.infinity,
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('System Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF00212E), letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('Manage your account preferences and global privacy policies.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                        const SizedBox(height: 24),
                        
                        TabBar(
                          indicatorColor: const Color(0xFF00A8E8),
                          indicatorWeight: 3,
                          labelColor: const Color(0xFF00A8E8),
                          unselectedLabelColor: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
                          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Montserrat', fontSize: 13),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Montserrat', fontSize: 13),
                          tabs: [
                            const Tab(icon: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.person, size: 18), SizedBox(width: 8), Text('Account')])),
                            if (!widget.isNurseView)
                              const Tab(icon: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.security, size: 18), SizedBox(width: 8), Text('Privacy')])),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (provider.saveMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: provider.saveMessage!.contains('Error') || provider.saveMessage!.contains('Failed') 
                          ? (isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2)) 
                          : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: provider.saveMessage!.contains('Error') || provider.saveMessage!.contains('Failed') 
                            ? (isDark ? const Color(0xFF881337).withValues(alpha: 0.5) : const Color(0xFFFECACA)) 
                            : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFD1FAE5))
                        )
                      ),
                      child: Text(
                        provider.saveMessage!, textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13, 
                          color: provider.saveMessage!.contains('Error') || provider.saveMessage!.contains('Failed') 
                            ? (isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48)) 
                            : (isDark ? const Color(0xFF34D399) : const Color(0xFF10B981))
                        ),
                      ),
                    ),

                  Expanded(
                    child: !_dataLoaded
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A8E8)))
                      : TabBarView(
                          children: [
                            _buildAccountTab(provider, authProvider, isDark),
                            if (!widget.isNurseView)
                              _buildDataPrivacyTab(provider, isDark),
                          ],
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

  Widget _buildAccountTab(AdminSettingsProvider provider, AuthProvider authProvider, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildCard(
          title: 'Profile Details',
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DISPLAY NAME', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569), letterSpacing: 1.0)),
              const SizedBox(height: 8),
              TextField(
                controller: _displayNameController,
                style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
                decoration: InputDecoration(
                  isDense: true, 
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), width: 2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('INTERFACE THEME', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569), letterSpacing: 1.0)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(8), color: isDark ? const Color(0xFF1E293B) : Colors.white),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true, value: _selectedTheme,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    iconEnabledColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontFamily: 'Montserrat'),
                    items: const [
                      DropdownMenuItem(value: 'light', child: Text('Light Mode')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark Mode')),
                      DropdownMenuItem(value: 'default', child: Text('System Default')),
                    ],
                    onChanged: (val) { 
                      if (val != null) {
                        setState(() {
                          _selectedTheme = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await provider.updateAdminProfile(_displayNameController.text, _selectedTheme);
                    if (!mounted) return;
                    if (success) {
                      context.read<ThemeProvider>().setTheme(_selectedTheme);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A8E8), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Save Profile Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildCard(
          title: 'Security & Authentication',
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 16),
              Text('CURRENT PASSWORD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569), letterSpacing: 1.0)),
              const SizedBox(height: 8),
              TextField(
                controller: _oldPasswordController, obscureText: true, 
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
                  filled: true, fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))), 
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))), 
                  suffixIcon: Icon(Icons.visibility_off, color: isDark ? const Color(0xFF64748B) : Colors.blueGrey, size: 18)
                )
              ),
              const SizedBox(height: 16),
              Text('NEW PASSWORD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569), letterSpacing: 1.0)),
              const SizedBox(height: 8),
              TextField(
                controller: _newPasswordController, obscureText: true, 
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
                  filled: true, fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))), 
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))), 
                  suffixIcon: Icon(Icons.visibility_off, color: isDark ? const Color(0xFF64748B) : Colors.blueGrey, size: 18)
                )
              ),
              const SizedBox(height: 16),
              Text('CONFIRM NEW PASSWORD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569), letterSpacing: 1.0)),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController, obscureText: true, 
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
                  filled: true, fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)))
                )
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    if (_newPasswordController.text != _confirmPasswordController.text) {
                      return;
                    }
                    await provider.changeAdminPassword(_oldPasswordController.text, _newPasswordController.text);
                    _oldPasswordController.clear(); 
                    _newPasswordController.clear(); 
                    _confirmPasswordController.clear();
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), foregroundColor: const Color(0xFF00A8E8), side: const BorderSide(color: Color(0xFF00A8E8), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Two-Factor Authentication', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: provider.is2FAEnabled ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4)) : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)), 
                      borderRadius: BorderRadius.circular(6)
                    ),
                    child: Text(provider.is2FAEnabled ? 'ENABLED' : 'DISABLED', style: TextStyle(color: provider.is2FAEnabled ? (isDark ? const Color(0xFF34D399) : const Color(0xFF10B981)) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0))
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text('Require a secure 6-digit PIN code during every login attempt.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 12),
              SwitchListTile(
                value: provider.is2FAEnabled,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFF10B981),
                activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.5),
                title: const Text('Enable 2FA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                onChanged: (val) {
                  if (val) {
                    _show2FASetupModal(context, provider, isDark);
                  } else {
                    provider.toggle2FA(false);
                  }
                },
              ),
            ],
          ),
        ),
        if (!widget.isNurseView) ...[
          const SizedBox(height: 24),
          _buildCard(
            title: 'Nurse Account Linking',
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Link a Nurse profile to quickly switch roles without logging out.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                const SizedBox(height: 16),
                if (provider.linkedNurseId.isEmpty) ...[
                  Text('NURSE ID', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569), letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nurseIdController, 
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'e.g. N-202601', 
                      hintStyle: TextStyle(color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                      isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
                      filled: true, fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)))
                    )
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () { 
                        provider.linkNurseAccount(_nurseIdController.text); 
                        _nurseIdController.clear(); 
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: isDark ? const Color(0xFF00A8E8) : const Color(0xFF00212E), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Link Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CURRENTLY LINKED NURSE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B), letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                Text(provider.linkedNurseId, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), fontSize: 18)),
                              ],
                            ),
                            OutlinedButton(
                              onPressed: () {
                                provider.unlinkNurseAccount();
                              },
                              style: OutlinedButton.styleFrom(foregroundColor: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48), side: BorderSide(color: isDark ? const Color(0xFF881337) : const Color(0xFFFECACA)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                              child: const Text('Unlink', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), height: 1)),
                        SwitchListTile(
                          value: provider.enableSidebarToggle,
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: const Color(0xFF00A8E8),
                          activeTrackColor: const Color(0xFF00A8E8).withValues(alpha: 0.5),
                          title: Text('Sidebar Role Switcher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                          subtitle: Text('Show the toggle in the sidebar to switch views instantly.', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                          onChanged: (val) {
                            provider.toggleSidebarFeature(val);
                          },
                        ),
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(color: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.2) : const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF881337).withValues(alpha: 0.5) : const Color(0xFFFECACA))),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Danger Zone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48))),
              const SizedBox(height: 16),
              Text('Deactivate Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text('Temporarily disable your access. You will be logged out immediately and will require another administrator to reactivate your profile.', style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showDeactivateModal(context, provider, isDark);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                  child: const Text('Deactivate Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataPrivacyTab(AdminSettingsProvider provider, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)))),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: isDark ? Colors.white : const Color(0xFF00212E), size: 24),
                    const SizedBox(width: 12),
                    Text('Global Data Compliance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF00212E))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF451A03).withValues(alpha: 0.3) : const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.5) : const Color(0xFFFDE68A))),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text('System policies are strictly locked by the Principal Administrator to ensure legal compliance.', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309), fontSize: 13))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('CCTV Video Retention Policy', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Automatic permanent deletion cycle for recorded facility footage.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                          child: Text('${provider.videoRetentionDays} Days', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Text('SYSTEM LOCKED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), letterSpacing: 1.0)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text('Audit Trail Auto-Archive', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Timeframe before activity logs are permanently purged from the active database.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                          child: Text('${provider.auditArchiveDays} Days', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Text('SYSTEM LOCKED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), letterSpacing: 1.0)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)))),
            child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF00212E))),
          ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}