import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/admin_elders_provider.dart';

class AdminEldersScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final bool isNurseView;

  const AdminEldersScreen({super.key, this.onMenuTap, this.isNurseView = false});

  @override
  State<AdminEldersScreen> createState() => _AdminEldersScreenState();
}

class _AdminEldersScreenState extends State<AdminEldersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _expandedNotesId;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminEldersProvider>().fetchResidents();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddResidentModal(BuildContext context) {
    final firstNameCtrl = TextEditingController();
    final middleNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    String? selectedHouse = 'House of St. Charble';

    final provider = context.read<AdminEldersProvider>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add New Resident',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF001F2D)),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close, color: Colors.blueGrey, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildModalLabel('FIRST NAME *'),
                      _buildModalTextField(firstNameCtrl, 'Enter first name'),
                      const SizedBox(height: 16),
                      _buildModalLabel('MIDDLE NAME (OPTIONAL)'),
                      _buildModalTextField(middleNameCtrl, 'Enter middle name'),
                      const SizedBox(height: 16),
                      _buildModalLabel('LAST NAME *'),
                      _buildModalTextField(lastNameCtrl, 'Enter last name'),
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
                            items: provider.houses.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                            onChanged: (val) => setModalState(() => selectedHouse = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
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
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);
                                
                                if (firstNameCtrl.text.trim().isEmpty || lastNameCtrl.text.trim().isEmpty) {
                                  messenger.showSnackBar(const SnackBar(content: Text('First and Last name required')));
                                  return;
                                }
                                
                                final data = {
                                  'firstName': firstNameCtrl.text.trim(),
                                  'middleName': middleNameCtrl.text.trim(),
                                  'lastName': lastNameCtrl.text.trim(),
                                  'house': selectedHouse,
                                };
                                
                                final success = await provider.addResident(data);
                                if (success) {
                                  navigator.pop();
                                  messenger.showSnackBar(const SnackBar(content: Text('Resident Added Successfully')));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0FB2EA),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Add Resident', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleExcelImport() async {
    final provider = context.read<AdminEldersProvider>();
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        var file = result.files.single.path!;
        var bytes = File(file).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        
        List<Map<String, dynamic>> importedResidents = [];
        
        for (var table in excel.tables.keys) {
          for (var row in excel.tables[table]!.rows.skip(1)) {
            if (row.isEmpty || row[0]?.value == null) continue;
            
            String fullName = row[0]!.value.toString().trim();
            if (fullName.isEmpty) continue;

            List<String> nameParts = fullName.split(RegExp(r'\s+'));
            String fName = '';
            String mName = '';
            String lName = '';

            if (nameParts.length == 1) {
              fName = nameParts[0];
            } else if (nameParts.length == 2) {
              fName = nameParts[0];
              lName = nameParts[1];
            } else {
              fName = nameParts[0];
              lName = nameParts.last;
              mName = nameParts.sublist(1, nameParts.length - 1).join(' ');
            }

            importedResidents.add({
              'firstName': fName,
              'middleName': mName,
              'lastName': lName,
              'house': provider.selectedHouse,
              'attendance': null,
              'notes': '',
            });
          }
        }

        if (importedResidents.isEmpty) {
          messenger.showSnackBar(const SnackBar(content: Text('No valid data found in Excel.')));
          return;
        }

        messenger.showSnackBar(const SnackBar(content: Text('Importing residents...')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error importing Excel: $e')));
    }
  }

  Future<void> _generateAndPrintPdf() async {
    final provider = context.read<AdminEldersProvider>();
    final doc = pw.Document();

    final house = provider.selectedHouse;
    final total = provider.houseHeadcount;
    final present = provider.presentCount;
    final absent = provider.notPresentCount;
    final absentList = provider.houseResidents.where((r) => r['attendance'] == 'Not Present').toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Daily Attendance Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#014E64'))),
              pw.SizedBox(height: 10),
              pw.Text('House: $house', style: const pw.TextStyle(fontSize: 16)),
              pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildPdfStat('Total Residents', total.toString(), PdfColor.fromHex('#014E64')),
                  _buildPdfStat('Present', present.toString(), PdfColor.fromHex('#16a34a')),
                  _buildPdfStat('Not Present', absent.toString(), PdfColor.fromHex('#dc2626')),
                ]
              ),
              pw.SizedBox(height: 30),
              if (absentList.isNotEmpty) ...[
                pw.Text('Absent Residents:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#dc2626'))),
                pw.SizedBox(height: 10),
                pw.ListView.builder(
                  itemCount: absentList.length,
                  itemBuilder: (context, index) {
                    final r = absentList[index];
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Text('${index + 1}. ${r['firstName']} ${r['lastName']}', style: const pw.TextStyle(fontSize: 14)),
                    );
                  },
                ),
              ] else ...[
                pw.Text('All residents are present today!', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#16a34a'))),
              ]
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Attendance_${house.replaceAll(' ', '_')}.pdf',
    );
  }

  pw.Widget _buildPdfStat(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: color)),
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
      ]
    );
  }

  Widget _buildModalLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF001F2D)),
      ),
    );
  }

  Widget _buildModalTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: Color(0xFF001F2D)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.blueGrey.withValues(alpha: 0.5), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0FB2EA))),
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
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Color(0xFF0066CC)),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: const Icon(Icons.notifications), color: const Color(0xFF0066CC), onPressed: () {}),
              Positioned(
                right: 12,
                top: 12,
                child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
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
      floatingActionButton: widget.isNurseView 
        ? null 
        : FloatingActionButton(
            onPressed: () => _showAddResidentModal(context),
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
                    borderRadius: BorderRadius.only(bottomRight: Radius.circular(60)),
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F2D)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 100),
                        child: const Text(
                          'Residents Management',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0066CC)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  if (!widget.isNurseView) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleExcelImport,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Import Excel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0066CC),
                          side: const BorderSide(color: Color(0xFF0066CC)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _generateAndPrintPdf,
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF027091),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Consumer<AdminEldersProvider>(
              builder: (context, provider, child) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: provider.houses.map((house) {
                      final isActive = provider.selectedHouse == house;
                      final shortName = house.replaceAll('House of St. ', '');
                      return GestureDetector(
                        onTap: () => provider.setHouse(house),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF0FB2EA) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isActive ? const Color(0xFF0FB2EA) : Colors.blueGrey.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            shortName,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }
            ),

            Consumer<AdminEldersProvider>(
              builder: (context, provider, child) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryStat(provider.houseHeadcount.toString(), 'Total', const Color(0xFF0066CC)),
                        _buildSummaryStat(provider.presentCount.toString(), 'Present', Colors.green),
                        _buildSummaryStat(provider.notPresentCount.toString(), 'Absent', Colors.red),
                        _buildSummaryStat(provider.withNotesCount.toString(), 'Notes', Colors.orange),
                      ],
                    ),
                  ),
                );
              }
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      onChanged: (value) => context.read<AdminEldersProvider>().setSearchTerm(value),
                      decoration: const InputDecoration(
                        hintText: 'Search Residents...',
                        hintStyle: TextStyle(color: Colors.blueGrey, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.blueGrey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.swipe, size: 14, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Text('Swipe right for Present, left for Absent', style: TextStyle(color: Colors.blueGrey.withValues(alpha: 0.7), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: Consumer<AdminEldersProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF0FB2EA)));
                  }

                  final residents = provider.filteredResidents;

                  if (residents.isEmpty) {
                    return const Center(
                      child: Text('No residents found.', style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: provider.fetchResidents,
                    color: const Color(0xFF0FB2EA),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 80),
                      itemCount: residents.length,
                      itemBuilder: (context, index) {
                        final resident = residents[index];
                        final id = resident['_id'] ?? resident['id'] ?? '';
                        
                        return FadeInUp(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 50),
                          child: Dismissible(
                            key: Key(id),
                            background: _buildSwipeBackground(Colors.green, Icons.check, 'Present', Alignment.centerLeft),
                            secondaryBackground: _buildSwipeBackground(Colors.red, Icons.close, 'Absent', Alignment.centerRight),
                            confirmDismiss: (direction) async {
                              final status = direction == DismissDirection.startToEnd ? 'Present' : 'Not Present';
                              final messenger = ScaffoldMessenger.of(context);
                              await provider.updateAttendance(id, status);
                              messenger.clearSnackBars();
                              messenger.showSnackBar(SnackBar(
                                content: Text('Marked as $status'),
                                backgroundColor: status == 'Present' ? Colors.green : Colors.red,
                                duration: const Duration(seconds: 1),
                              ));
                              return false; 
                            },
                            child: _buildResidentCard(resident, provider),
                          ),
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

  Widget _buildSwipeBackground(Color color, IconData icon, String text, Alignment alignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildResidentCard(dynamic resident, AdminEldersProvider provider) {
    final String firstName = resident['firstName'] ?? '';
    final String lastName = resident['lastName'] ?? '';
    final String fullName = '$firstName $lastName';
    final String status = resident['attendance'] ?? 'Unmarked';
    final String notes = resident['notes'] ?? '';
    final bool hasNotes = notes.trim().isNotEmpty;
    final id = resident['_id'] ?? resident['id'] ?? '';
    
    Color statusColor = Colors.blueGrey;
    if (status == 'Present') statusColor = Colors.green;
    if (status == 'Not Present') statusColor = Colors.red;

    final isExpanded = _expandedNotesId == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blueGrey.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F2D))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedNotesId = null;
                      } else {
                        _expandedNotesId = id;
                        _notesController.text = notes;
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: hasNotes ? const Color(0xFF0FB2EA) : Colors.blueGrey.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    hasNotes ? 'View Notes' : 'Add Notes',
                    style: TextStyle(
                      color: hasNotes ? const Color(0xFF0FB2EA) : Colors.blueGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.blueGrey.withValues(alpha: 0.1)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daily Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type observation notes here...',
                      hintStyle: TextStyle(color: Colors.blueGrey.withValues(alpha: 0.5)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2))),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _expandedNotesId = null),
                        child: const Text('Cancel', style: TextStyle(color: Colors.blueGrey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await provider.saveNotes(id, _notesController.text);
                          setState(() => _expandedNotesId = null);
                          messenger.showSnackBar(const SnackBar(content: Text('Notes Saved')));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066CC),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Save', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}