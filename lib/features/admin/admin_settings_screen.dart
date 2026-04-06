import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/admin_settings_provider.dart';
import '../../providers/admin_auth_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const AdminSettingsScreen({super.key, this.onMenuTap});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final TextEditingController _zoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminSettingsProvider>().fetchSettings();
      }
    });
  }

  @override
  void dispose() {
    _zoneController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, String currentTime, String shiftType) async {
    final provider = context.read<AdminSettingsProvider>();
    TimeOfDay initialTime = const TimeOfDay(hour: 6, minute: 0);
    
    try {
      if (currentTime.isNotEmpty) {
        final parts = currentTime.split(':');
        initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0FB2EA)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      provider.updateShift(shiftType, formattedTime);
    }
  }

  String _formatTimeDisplay(String time24) {
    if (time24.isEmpty) return 'Select Time';
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:$minute $ampm';
    } catch (_) {
      return time24;
    }
  }

  String _getSensitivityLabel(int value) {
    if (value > 70) return 'High Sensitivity';
    if (value > 40) return 'Medium Sensitivity';
    return 'Low Sensitivity';
  }

  void _show2FASetupModal(BuildContext context, AdminAuthProvider authProvider) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscurePin = true;
    bool obscureConfirm = true;
    String? localError;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 32,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Setup 2FA PIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001F2D))),
                  const SizedBox(height: 8),
                  const Text('Enter a 6-digit PIN to secure your account.', style: TextStyle(color: Colors.blueGrey), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  
                  if (localError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        localError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),

                  TextField(
                    controller: pinController,
                    obscureText: obscurePin,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '••••••',
                      counterText: "",
                      labelText: 'Enter 6-Digit PIN',
                      floatingLabelAlignment: FloatingLabelAlignment.center,
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0FB2EA)),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePin ? Icons.visibility_off : Icons.visibility, color: Colors.blueGrey),
                        onPressed: () => setModalState(() => obscurePin = !obscurePin),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '••••••',
                      counterText: "",
                      labelText: 'Confirm PIN',
                      floatingLabelAlignment: FloatingLabelAlignment.center,
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0FB2EA)),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.blueGrey),
                        onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        if (pinController.text.length != 6) {
                          setModalState(() => localError = 'PIN must be exactly 6 digits.');
                          return;
                        }
                        if (pinController.text != confirmController.text) {
                          setModalState(() => localError = 'PINs do not match.');
                          return;
                        }

                        setModalState(() {
                          isSaving = true;
                          localError = null;
                        });

                        final success = await authProvider.toggle2FA(authProvider.adminId!, true, pin: pinController.text);
                        
                        if (!context.mounted) return;

                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('2FA Enabled Successfully!'), backgroundColor: Colors.green),
                          );
                        } else {
                          setModalState(() {
                            isSaving = false;
                            localError = authProvider.errorMessage ?? 'Failed to enable 2FA.';
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0FB2EA),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Enable 2FA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
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

  Widget _buildCustomAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF0066CC)),
            onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
          ),
          Image.asset('assets/images/visio.png', height: 36, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported)),
          const Icon(Icons.notifications_none, color: Color(0xFF0066CC)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: Consumer2<AdminSettingsProvider, AdminAuthProvider>(
          builder: (context, settingsProvider, authProvider, child) {
            return Column(
              children: [
                _buildCustomAppBar(),
                _buildHeader(),
                if (settingsProvider.saveMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: settingsProvider.saveMessage!.contains('Error') || settingsProvider.saveMessage!.contains('Failed') 
                          ? Colors.red.withValues(alpha: 0.1) 
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: settingsProvider.saveMessage!.contains('Error') || settingsProvider.saveMessage!.contains('Failed') 
                          ? Colors.red.withValues(alpha: 0.3) 
                          : Colors.green.withValues(alpha: 0.3),
                      )
                    ),
                    child: Text(
                      settingsProvider.saveMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: settingsProvider.saveMessage!.contains('Error') || settingsProvider.saveMessage!.contains('Failed') 
                          ? Colors.red 
                          : Colors.green,
                      ),
                    ),
                  ),
                Expanded(
                  child: settingsProvider.isLoading && settingsProvider.zones.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0FB2EA)))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        children: [
                          _buildFacilityAccordion(settingsProvider),
                          const SizedBox(height: 12),
                          _buildAIAccordion(settingsProvider),
                          const SizedBox(height: 12),
                          _buildNotificationsAccordion(settingsProvider),
                          const SizedBox(height: 12),
                          _buildDataPrivacyAccordion(settingsProvider),
                          const SizedBox(height: 12),
                          _buildAccountAccordion(settingsProvider, authProvider),
                          const SizedBox(height: 40),
                        ],
                      ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.blueGrey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: settingsProvider.isLoading ? null : () => settingsProvider.saveSettings(),
                      icon: settingsProvider.isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(settingsProvider.isLoading ? 'Saving...' : 'Save All Settings', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 110,
          decoration: const BoxDecoration(color: Color(0xFFE8F4FD), borderRadius: BorderRadius.only(bottomRight: Radius.circular(60))),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(duration: const Duration(milliseconds: 800), child: const Text('System Configuration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF001F2D)))),
              FadeInDown(delay: const Duration(milliseconds: 100), child: const Text('System Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0066CC)))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccordionWrapper({required String title, required IconData icon, required Widget child}) {
    return FadeInUp(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.blueGrey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(icon, color: const Color(0xFF0FB2EA)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF001F2D), fontSize: 16)),
            iconColor: const Color(0xFF0FB2EA),
            collapsedIconColor: Colors.blueGrey,
            childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            children: [child],
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityAccordion(AdminSettingsProvider provider) {
    return _buildAccordionWrapper(
      title: 'Facility Configuration',
      icon: Icons.business,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Define zones and shift timings for your facility.', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
          const SizedBox(height: 24),
          const Text('ZONE MANAGEMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0FB2EA))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _zoneController,
                  decoration: InputDecoration(
                    hintText: 'Enter zone name...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  provider.addZone(_zoneController.text);
                  _zoneController.clear();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0FB2EA), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.zones.isNotEmpty)
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(8)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.zones.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.blueGrey.withValues(alpha: 0.2)),
                itemBuilder: (context, index) {
                  final zone = provider.zones[index];
                  return ListTile(
                    title: Text(zone['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(zone['description'], style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => provider.removeZone(index)),
                  );
                },
              ),
            ),
          const SizedBox(height: 32),
          const Text('SHIFT TIMINGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0FB2EA))),
          const SizedBox(height: 12),
          _buildShiftSelector('Morning Shift Start', provider.morningShift, () => _selectTime(context, provider.morningShift, 'morning')),
          const SizedBox(height: 8),
          _buildShiftSelector('Afternoon Shift Start', provider.afternoonShift, () => _selectTime(context, provider.afternoonShift, 'afternoon')),
          const SizedBox(height: 8),
          _buildShiftSelector('Night Shift Start', provider.nightShift, () => _selectTime(context, provider.nightShift, 'night')),
        ],
      ),
    );
  }

  Widget _buildShiftSelector(String label, String time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F2D))),
            Row(
              children: [
                Text(_formatTimeDisplay(time), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0FB2EA))),
                const SizedBox(width: 8),
                const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAIAccordion(AdminSettingsProvider provider) {
    return _buildAccordionWrapper(
      title: 'AI Sensitivity & Thresholds',
      icon: Icons.memory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Adjust the sensitivity and alert thresholds for the AI detection system.', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
          const SizedBox(height: 24),
          const Text('FALL DETECTION SENSITIVITY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0FB2EA))),
          const SizedBox(height: 8),
          Text(_getSensitivityLabel(provider.fallSensitivity), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F2D))),
          Slider(
            value: provider.fallSensitivity.toDouble(),
            min: 0,
            max: 100,
            activeColor: const Color(0xFF0FB2EA),
            inactiveColor: Colors.blueGrey.withValues(alpha: 0.2),
            onChanged: (val) => provider.updateAiSetting('fallSensitivity', val.toInt()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0%', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
              Text('${provider.fallSensitivity}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0FB2EA))),
              const Text('100%', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
            ],
          ),
          const SizedBox(height: 32),
          const Text('THERMAL ALERT THRESHOLD (°C)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0FB2EA))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  controller: TextEditingController(text: provider.thermalThreshold.toString())..selection = TextSelection.collapsed(offset: provider.thermalThreshold.toString().length),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2))),
                  ),
                  onChanged: (val) {
                    final num = double.tryParse(val);
                    if (num != null) provider.updateAiSetting('thermalThreshold', num);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: provider.thermalThreshold >= 38.0 
                  ? const Text('Warning: High threshold (may miss heatstroke)', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold))
                  : const SizedBox(),
              )
            ],
          ),
          const SizedBox(height: 32),
          const Text('INACTIVITY TIMER (MINUTES)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0FB2EA))),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: provider.inactivityTimer.toString())..selection = TextSelection.collapsed(offset: provider.inactivityTimer.toString().length),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2))),
              suffixText: 'Minutes',
            ),
            onChanged: (val) {
              final num = int.tryParse(val);
              if (num != null) provider.updateAiSetting('inactivityTimer', num);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsAccordion(AdminSettingsProvider provider) {
    return _buildAccordionWrapper(
      title: 'Notifications & API',
      icon: Icons.notifications_active,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configure how alerts are sent to nurses, guardians, and emergency contacts.', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('SMS Gateway Integration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(provider.smsEnabled ? 'SMS Enabled' : 'SMS Disabled', style: TextStyle(color: provider.smsEnabled ? Colors.green : Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 12)),
            value: provider.smsEnabled,
            activeTrackColor: const Color(0xFF0FB2EA).withValues(alpha: 0.5),
            activeThumbColor: const Color(0xFF0FB2EA),
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => provider.updateNotificationSetting('smsEnabled', val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Emergency Broadcast Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(provider.emergencyBroadcast ? 'Active (All nurses alerted)' : 'Inactive', style: TextStyle(color: provider.emergencyBroadcast ? Colors.redAccent : Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 12)),
            value: provider.emergencyBroadcast,
            activeTrackColor: Colors.redAccent.withValues(alpha: 0.5),
            activeThumbColor: Colors.redAccent,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => provider.updateNotificationSetting('emergencyBroadcast', val),
          ),
          const Divider(),
          const SizedBox(height: 16),
          const Text('GUARDIAN NOTIFICATION DELAY (MINUTES)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0FB2EA))),
          const SizedBox(height: 8),
          const Text('Wait before alerting guardians (gives nurses time to confirm situation).', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: provider.guardianDelay.toString())..selection = TextSelection.collapsed(offset: provider.guardianDelay.toString().length),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2))),
              suffixText: 'Minutes',
            ),
            onChanged: (val) {
              final num = int.tryParse(val);
              if (num != null) provider.updateNotificationSetting('guardianDelay', num);
            },
          ),
          const SizedBox(height: 8),
          const Text('Set to 0 for immediate notification', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildDataPrivacyAccordion(AdminSettingsProvider provider) {
    return _buildAccordionWrapper(
      title: 'Data & Privacy',
      icon: Icons.security,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configure data retention policies to comply with privacy regulations.', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
          const SizedBox(height: 24),
          const Text('CCTV VIDEO RETENTION (DAYS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0FB2EA))),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: provider.videoRetentionDays.toString())..selection = TextSelection.collapsed(offset: provider.videoRetentionDays.toString().length),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2))),
              suffixText: 'Days',
            ),
            onChanged: (val) {
              final num = int.tryParse(val);
              if (num != null) provider.updateDataSetting('videoRetentionDays', num);
            },
          ),
          const SizedBox(height: 8),
          Text('Videos older than ${provider.videoRetentionDays} days will be overwritten.', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
          const SizedBox(height: 24),
          const Text('AUDIT TRAIL AUTO-ARCHIVE (DAYS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0FB2EA))),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: provider.auditArchiveDays.toString())..selection = TextSelection.collapsed(offset: provider.auditArchiveDays.toString().length),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2))),
              suffixText: 'Days',
            ),
            onChanged: (val) {
              final num = int.tryParse(val);
              if (num != null) provider.updateDataSetting('auditArchiveDays', num);
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Text('Privacy Compliance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
                SizedBox(height: 8),
                Text('• Review retention policies with your legal team.\n• Ensure GDPR/HIPAA compliance.\n• Document all retention policy changes.', style: TextStyle(fontSize: 12, color: Colors.brown, height: 1.5)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAccountAccordion(AdminSettingsProvider settingsProvider, AdminAuthProvider authProvider) {
    final bool is2FAEnabled = authProvider.adminData?['is2FAEnabled'] ?? false;

    return _buildAccordionWrapper(
      title: 'Account Preferences',
      icon: Icons.manage_accounts,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Manage your account-specific UI preferences and security settings.', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Two-Factor Authentication (2FA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              is2FAEnabled ? '2FA Enabled' : '2FA Disabled', 
              style: TextStyle(
                color: is2FAEnabled ? Colors.green : Colors.blueGrey, 
                fontWeight: FontWeight.bold, 
                fontSize: 12
              )
            ),
            value: is2FAEnabled,
            activeTrackColor: Colors.green.withValues(alpha: 0.5),
            activeThumbColor: Colors.green,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) async {
              if (val) {
                _show2FASetupModal(context, authProvider);
              } else {
                final success = await authProvider.toggle2FA(authProvider.adminId!, false);
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('2FA Disabled'), backgroundColor: Colors.blueGrey),
                  );
                }
              }
            },
          ),
          const Text('Require a 6-digit PIN code in addition to your password when logging in.', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
          const Divider(height: 32),
          SwitchListTile(
            title: const Text('Sidebar Role Switcher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              settingsProvider.enableSidebarToggle ? 'Toggle Enabled' : 'Toggle Disabled', 
              style: TextStyle(
                color: settingsProvider.enableSidebarToggle ? const Color(0xFF0FB2EA) : Colors.blueGrey, 
                fontWeight: FontWeight.bold, 
                fontSize: 12
              )
            ),
            value: settingsProvider.enableSidebarToggle,
            activeTrackColor: const Color(0xFF0FB2EA).withValues(alpha: 0.5),
            activeThumbColor: const Color(0xFF0FB2EA),
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => settingsProvider.toggleSidebarFeature(val),
          ),
          const Text('Enable the Admin ↔ Nurse quick-switch toggle in the sidebar.', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
        ],
      ),
    );
  }
}