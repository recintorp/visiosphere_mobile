import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_guardians_provider.dart';

class EditGuardianModal extends StatefulWidget {
  final Map<String, dynamic> guardian;

  const EditGuardianModal({super.key, required this.guardian});

  @override
  State<EditGuardianModal> createState() => _EditGuardianModalState();
}

class _EditGuardianModalState extends State<EditGuardianModal> {
  late TextEditingController _firstNameCtrl;
  late TextEditingController _middleNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late String _selectedGender;
  late String _selectedStatus;

  /// Account Status is the system's until the guardian has set their password.
  /// Provisioning writes PENDING; guardianAuthService.setPassword() moves it to
  /// ACTIVE on its own. Until then the admin cannot touch it — and the backend
  /// refuses the change too, so this is a courtesy, not the enforcement.
  bool get _setupPending => widget.guardian['isPasswordSet'] != true;
  bool _isSaving = false;

  /// Validation and failure text, shown INSIDE this panel rather than as a
  /// SnackBar behind it. See the note in provision_guardian_modal.dart.
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.guardian['firstName'] ?? '');
    _middleNameCtrl = TextEditingController(text: widget.guardian['middleName'] ?? '');
    _lastNameCtrl = TextEditingController(text: widget.guardian['lastName'] ?? '');
    _emailCtrl = TextEditingController(text: widget.guardian['email'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.guardian['phone'] ?? '');
    _selectedGender = widget.guardian['gender'] ?? '';
    _selectedStatus = widget.guardian['status']?.toString().toUpperCase() ?? 'PENDING';
  }

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
    final String guardianId = widget.guardian['guardianId'] ?? widget.guardian['_id'];

    setState(() => _isSaving = true);

    final success = await provider.updateGuardian(
      guardianId,
      {
        'firstName': _firstNameCtrl.text.trim(),
        'middleName': _middleNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'email': email,
        'phone': _phoneCtrl.text.trim(),
        'gender': _selectedGender,
        'status': _selectedStatus,
      },
    );

    if (!mounted) return;

    if (success) {
      setState(() => _isSaving = false);
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Guardian account updated successfully!', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFF10B981)),
      );
    } else {
      _fail(provider.errorMessage ?? 'Failed to update account.');
    }
  }

  /// Inline message block — see [_errorText] for why this is not a SnackBar.
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
      child: Text(
        label, 
        style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A), letterSpacing: 0.5)
      ),
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
            Text('Edit Guardian Account', style: TextStyle(fontFamily: 'Montserrat', fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            Text('Update profile and status.', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14)),
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
            const SizedBox(height: 16),
            
            _buildFieldLabel('ACCOUNT STATUS', isDark),
            Container(
              width: double.infinity,
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
                  value: _selectedStatus,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: _setupPending
                          ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
                          : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8))),
                  style: TextStyle(fontFamily: 'Montserrat', color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  items: [
                    // PENDING is offered only so the disabled control has a
                    // value to display — DropdownButton asserts when `value` is
                    // absent from `items`. It is never selectable: the field is
                    // locked while setup is outstanding.
                    if (_setupPending)
                      const DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
                    const DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                    const DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                  ],
                  // A null onChanged is what disables a DropdownButton.
                  onChanged: _setupPending
                      ? null
                      : (val) => setState(() => _selectedStatus = val!),
                ),
              ),
            ),
            if (_setupPending)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  'Set automatically — becomes Active once this guardian sets their password.',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
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
                      backgroundColor: isDark ? const Color(0xFF00A8E8) : const Color(0xFF00435C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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