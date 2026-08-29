import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_guardians_provider.dart';

class ProvisionGuardianModal extends StatefulWidget {
  const ProvisionGuardianModal({super.key});

  @override
  State<ProvisionGuardianModal> createState() => _ProvisionGuardianModalState();
}

class _ProvisionGuardianModalState extends State<ProvisionGuardianModal> {
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _selectedGender = '';
  bool _isSaving = false;

  /// Validation and failure text, shown INSIDE this panel.
  ///
  /// Every message here used to be a SnackBar. A SnackBar is anchored to the
  /// bottom of the screen — and this panel is a bottom sheet sitting on that
  /// exact spot, so the message appeared behind it, nowhere near the field it
  /// was about. That is "validation messages are displayed in the wrong
  /// location... outside the panels instead of inside". The success message is
  /// still a SnackBar, deliberately: by then the panel has closed, so the bottom
  /// of the screen is free and is the right place for it.
  String? _errorText;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _fail(String message) => setState(() {
        _errorText = message;
        _isSaving  = false;
      });

  void _handleSave() async {
    setState(() => _errorText = null);

    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty) {
      _fail('Please provide all required fields (*).');
      return;
    }

    // The backend takes the email on trust and MongoDB enforces only
    // uniqueness, so a typo like "name@" was accepted here, rejected there, and
    // came back as the same blanket "Failed to provision account." — with no
    // hint that the email was the problem. Checked here, where the field is.
    final email = _emailCtrl.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _fail('Enter a valid email address, e.g. guardian@example.com.');
      return;
    }

    if (_phoneCtrl.text.isNotEmpty && (_phoneCtrl.text.length != 11 || !_phoneCtrl.text.startsWith('0'))) {
      _fail('Phone number must be exactly 11 digits and start with 0.');
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<AdminGuardiansProvider>();

    setState(() => _isSaving = true);

    final success = await provider.addGuardian({
      'firstName': _firstNameCtrl.text.trim(),
      'middleName': _middleNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'email': email,
      'phone': _phoneCtrl.text.trim(),
      'gender': _selectedGender,
    });

    if (!context.mounted) return;

    if (success) {
      setState(() => _isSaving = false);
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Guardian account provisioned successfully!', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFF10B981)),
      );
    } else {
      // The provider now carries the backend's own explanation — a duplicate
      // email, an expired session, a rejected field. Showing it beats the flat
      // "Failed to provision account." that hid every one of those behind the
      // same sentence.
      _fail(provider.errorMessage ?? 'Failed to provision account.');
    }
  }

  /// Inline message block — sits between the last field and the buttons, so it
  /// is the first thing under the user's thumb when a save is refused.
  Widget _buildErrorBanner(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.35) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF881337) : const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 18, color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorText!,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label, style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A), letterSpacing: 0.5)),
    );
  }

  Widget _buildEntryField(TextEditingController ctrl, String hint, bool isDark, {TextInputType type = TextInputType.text, int? maxLength}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLength: maxLength,
      style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : Colors.grey, fontSize: 14),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), width: 2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Provision Guardian Account', style: TextStyle(fontFamily: 'Montserrat', fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            Text('Create a secure profile for a family contact.', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14)),
            const SizedBox(height: 24),
            _buildFieldLabel('FIRST NAME *', isDark),
            _buildEntryField(_firstNameCtrl, 'Enter legal first name', isDark),
            const SizedBox(height: 16),
            _buildFieldLabel('MIDDLE NAME', isDark),
            _buildEntryField(_middleNameCtrl, 'Optional', isDark),
            const SizedBox(height: 16),
            _buildFieldLabel('LAST NAME *', isDark),
            _buildEntryField(_lastNameCtrl, 'Enter legal last name', isDark),
            const SizedBox(height: 16),
            _buildFieldLabel('CONTACT EMAIL *', isDark),
            _buildEntryField(_emailCtrl, 'guardian@example.com', isDark, type: TextInputType.emailAddress),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('PHONE', isDark),
                      _buildEntryField(_phoneCtrl, '09xxxxxxxxx', isDark, type: TextInputType.phone, maxLength: 11),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('GENDER', isDark),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            value: _selectedGender.isEmpty ? null : _selectedGender,
                            hint: Text('Select', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF64748B) : Colors.grey, fontSize: 14)),
                            icon: Icon(Icons.keyboard_arrow_down, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)),
                            style: TextStyle(fontFamily: 'Montserrat', color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                            items: const [
                              DropdownMenuItem(value: 'M', child: Text('Male')),
                              DropdownMenuItem(value: 'F', child: Text('Female')),
                            ],
                            onChanged: (val) => setState(() => _selectedGender = val!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_errorText != null) _buildErrorBanner(isDark),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A8E8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Provision Account', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}