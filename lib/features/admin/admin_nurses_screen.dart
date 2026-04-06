import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/admin_nurses_provider.dart';

class AdminNursesScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  
  const AdminNursesScreen({super.key, this.onMenuTap});

  @override
  State<AdminNursesScreen> createState() => _AdminNursesScreenState();
}

class _AdminNursesScreenState extends State<AdminNursesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminNursesProvider>().fetchNurses();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddNurseModal(BuildContext context) {
    final firstNameCtrl = TextEditingController();
    final middleNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    DateTime? selectedDate;
    String? selectedGender;
    String? selectedHouse = 'House of St. Charble';

    final houses = [
      'House of St. Charble',
      'House of St. Gabriell',
      'House of St. Rose of Lima',
      'House of St. Sebastian',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add New Nurse',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF001F2D),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close, color: Colors.blueGrey, size: 24),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildModalLabel('FIRST NAME *'),
                            _buildModalTextField(firstNameCtrl, 'Enter first name'),
                            const SizedBox(height: 16),
                            _buildModalLabel('MIDDLE NAME (OPTIONAL)'),
                            _buildModalTextField(middleNameCtrl, 'Enter middle name (optional)'),
                            const SizedBox(height: 16),
                            _buildModalLabel('LAST NAME *'),
                            _buildModalTextField(lastNameCtrl, 'Enter last name'),
                            const SizedBox(height: 16),
                            _buildModalLabel('EMAIL ADDRESS *'),
                            _buildModalTextField(emailCtrl, 'Enter email address', keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _buildModalLabel('BIRTHDAY *'),
                            GestureDetector(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(0xFF0FB2EA),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      selectedDate == null ? 'mm / dd / yyyy' : '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
                                      style: TextStyle(
                                        color: selectedDate == null ? Colors.blueGrey.withValues(alpha: 0.5) : const Color(0xFF001F2D),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Icon(Icons.calendar_today, color: Colors.blueGrey.withValues(alpha: 0.5), size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildModalLabel('GENDER *'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedGender,
                                  hint: Text('Select Gender', style: TextStyle(color: Colors.blueGrey.withValues(alpha: 0.5), fontSize: 14)),
                                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey.withValues(alpha: 0.5)),
                                  items: const [
                                    DropdownMenuItem(value: 'M', child: Text('Male')),
                                    DropdownMenuItem(value: 'F', child: Text('Female')),
                                  ],
                                  onChanged: (val) => setModalState(() => selectedGender = val),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildModalLabel('HOUSE ASSIGNED *'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedHouse,
                                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey.withValues(alpha: 0.5)),
                                  items: houses.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                                  onChanged: (val) => setModalState(() => selectedHouse = val),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0FB2EA),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Add Nurse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Color(0xFF001F2D),
        ),
      ),
    );
  }

  Widget _buildModalTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF001F2D)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.blueGrey.withValues(alpha: 0.5), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0FB2EA)),
        ),
      ),
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
          Image.asset(
            'assets/images/visio.png',
            height: 36,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported, color: Color(0xFF0066CC)),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                color: const Color(0xFF0066CC),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNurseModal(context),
        backgroundColor: const Color(0xFF0FB2EA),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomAppBar(),
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 130,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F4FD),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(60),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: const Text(
                          'Account Management',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001F2D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 100),
                        child: const Text(
                          'Nurses Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0066CC),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F9FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        context.read<AdminNursesProvider>().setSearchTerm(value);
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search by Nurse ID or Name...',
                        hintStyle: TextStyle(color: Colors.blueGrey, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.blueGrey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 36,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            context.read<AdminNursesProvider>().toggleSortOrder();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF0FB2EA)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: const Row(
                              children: [
                                Icon(Icons.sort_by_alpha, size: 16, color: Color(0xFF0FB2EA)),
                                SizedBox(width: 4),
                                Text(
                                  'Sort',
                                  style: TextStyle(
                                    color: Color(0xFF0FB2EA),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Consumer<AdminNursesProvider>(
                            builder: (context, provider, child) {
                              return ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _buildFilterPill('All', provider),
                                  _buildFilterPill('Active', provider),
                                  _buildFilterPill('Inactive', provider),
                                  _buildFilterPill('On Leave', provider),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<AdminNursesProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF0FB2EA)),
                    );
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(provider.errorMessage!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: provider.fetchNurses,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final nurses = provider.nurses;

                  if (nurses.isEmpty) {
                    return const Center(
                      child: Text(
                        'No nurses found.',
                        style: TextStyle(color: Colors.blueGrey, fontSize: 16),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: provider.fetchNurses,
                    color: const Color(0xFF0FB2EA),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 80),
                      itemCount: nurses.length,
                      itemBuilder: (context, index) {
                        final nurse = nurses[index];
                        return FadeInUp(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 50),
                          child: _buildNurseCard(nurse),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String status, AdminNursesProvider provider) {
    final isActive = provider.filterStatus == status;
    return GestureDetector(
      onTap: () => provider.setFilterStatus(status),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0FB2EA) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF0FB2EA) : Colors.blueGrey.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            color: isActive ? Colors.white : Colors.blueGrey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildNurseCard(dynamic nurse) {
    final String firstName = nurse['firstName'] ?? '';
    final String lastName = nurse['lastName'] ?? '';
    final String fullName = '$firstName $lastName';
    final String nurseId = nurse['nurseId'] ?? 'N/A';
    final String gender = nurse['gender'] ?? '';
    final String house = nurse['houseAssigned']?.replaceAll('House of St. ', '') ?? 'N/A';
    final String status = nurse['status'] ?? 'Inactive';
    final String birthdayStr = nurse['birthday'] ?? '';
    
    String formattedBirthday = 'N/A';
    if (birthdayStr.isNotEmpty) {
      try {
        final DateTime bday = DateTime.parse(birthdayStr);
        formattedBirthday = '${bday.month}/${bday.day}/${bday.year}';
      } catch (_) {}
    }

    final bool isFemale = gender.toUpperCase() == 'F';
    final bool isActive = status == 'Active';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        nurseId,
                        style: const TextStyle(
                          color: Color(0xFF0066CC),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isActive ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.blueGrey),
                  onSelected: (value) {
                    if (value == 'edit') {
                    } else if (value == 'delete') {
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              fullName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF001F2D),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFemale ? Colors.pink.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isFemale ? 'Female' : 'Male',
                    style: TextStyle(
                      color: isFemale ? Colors.pink : Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF0FB2EA).withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    house,
                    style: const TextStyle(
                      color: Color(0xFF0FB2EA),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.blueGrey.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.cake, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(
                  formattedBirthday,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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