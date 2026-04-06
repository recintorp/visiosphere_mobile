import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_assessments_provider.dart';
import '../../providers/admin_elders_provider.dart';
import '../../providers/admin_auth_provider.dart';

class AdminAssessmentsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final bool isNurseView;
  
  const AdminAssessmentsScreen({super.key, this.onMenuTap, this.isNurseView = false});

  @override
  State<AdminAssessmentsScreen> createState() => _AdminAssessmentsScreenState();
}

class _AdminAssessmentsScreenState extends State<AdminAssessmentsScreen> {
  String? _selectedResidentId;
  bool _isCreating = false;
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminEldersProvider>().fetchResidents();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _handleAddWidget(String type) {
    context.read<AdminAssessmentsProvider>().addBlock(type);
  }

  Future<void> _pickImage(String blockId) async {
    final picker = ImagePicker();
    final provider = context.read<AdminAssessmentsProvider>();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      provider.updateBlockFile(blockId, image.path);
    }
  }

  Future<void> _pickFile(String blockId) async {
    final provider = context.read<AdminAssessmentsProvider>();
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      provider.updateBlockFile(blockId, result.files.single.path);
    }
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
    final residents = context.watch<AdminEldersProvider>().residents;
    final assessmentsProvider = context.watch<AdminAssessmentsProvider>();
    final admin = context.read<AdminAuthProvider>().adminData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(),
            _buildHeader(),
            _buildResidentSelector(residents),
            Expanded(
              child: _isCreating 
                ? _buildReportBuilder(assessmentsProvider, admin) 
                : _buildAssessmentHistory(assessmentsProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 100,
          decoration: const BoxDecoration(color: Color(0xFFE8F4FD), borderRadius: BorderRadius.only(bottomRight: Radius.circular(60))),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(child: const Text('Daily Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF001F2D)))),
              FadeInDown(delay: const Duration(milliseconds: 100), child: const Text('Assessments & Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0066CC)))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResidentSelector(List<dynamic> residents) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2))),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            hint: const Text('Select a Resident...'),
            value: _selectedResidentId,
            items: residents.map((r) {
              final id = r['_id'] ?? r['residentId'];
              return DropdownMenuItem<String>(value: id.toString(), child: Text('${r['firstName']} ${r['lastName']}'));
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedResidentId = val;
                _isCreating = false;
              });
              if (val != null) context.read<AdminAssessmentsProvider>().fetchAssessments(val);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentHistory(AdminAssessmentsProvider provider) {
    if (_selectedResidentId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.blueGrey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('Please select a resident to view history', style: TextStyle(color: Colors.blueGrey)),
          ],
        ),
      );
    }

    if (provider.isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ElevatedButton(
                onPressed: () => setState(() => _isCreating = true),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0FB2EA), elevation: 0),
                child: const Text('+ New Report', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: provider.assessments.length,
            itemBuilder: (context, index) {
              final report = provider.assessments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(report['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('By ${report['authorName']} • ${report['date'].toString().split('T')[0]}'),
                  trailing: widget.isNurseView 
                    ? null 
                    : IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => provider.deleteAssessment(report['_id'], _selectedResidentId!),
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportBuilder(AdminAssessmentsProvider provider, Map<String, dynamic>? admin) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: TextField(
            controller: _titleController,
            onChanged: (v) => provider.setReportTitle(v),
            decoration: const InputDecoration(hintText: 'Enter Report Title...', border: UnderlineInputBorder()),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: provider.blocks.length,
            itemBuilder: (context, index) => _buildBlockItem(provider.blocks[index], provider),
          ),
        ),
        _buildWidgetPicker(),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => setState(() => _isCreating = false), child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final resident = context.read<AdminEldersProvider>().residents.firstWhere((r) => (r['_id'] ?? r['residentId']) == _selectedResidentId);
                    final success = await provider.submitReport(
                      residentId: _selectedResidentId!,
                      residentName: '${resident['firstName']} ${resident['lastName']}',
                      authorId: admin?['customId'] ?? 'ADMIN',
                      authorName: '${admin?['firstName']} ${admin?['lastName']}',
                    );
                    if (success) {
                      _titleController.clear();
                      setState(() => _isCreating = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0),
                  child: const Text('Submit Report', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlockItem(Map<String, dynamic> block, AdminAssessmentsProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(block['type'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              GestureDetector(onTap: () => provider.removeBlock(block['id']), child: const Icon(Icons.close, size: 16, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          _buildBlockContent(block, provider),
        ],
      ),
    );
  }

  Widget _buildBlockContent(Map<String, dynamic> block, AdminAssessmentsProvider provider) {
    switch (block['type']) {
      case 'text':
        return TextField(
          maxLines: null,
          onChanged: (v) => provider.updateBlockContent(block['id'], v),
          decoration: const InputDecoration(hintText: 'Type notes here...', border: InputBorder.none),
        );
      case 'checklist':
        final List items = block['content'];
        return Column(
          children: [
            ...items.asMap().entries.map((entry) {
              int idx = entry.key;
              var item = entry.value;
              return Row(
                children: [
                  Checkbox(value: item['checked'], onChanged: (v) {
                    items[idx]['checked'] = v;
                    provider.updateBlockContent(block['id'], items);
                  }),
                  Expanded(child: TextField(
                    decoration: const InputDecoration(hintText: 'Task...', border: InputBorder.none),
                    onChanged: (v) {
                      items[idx]['text'] = v;
                      provider.updateBlockContent(block['id'], items);
                    },
                  )),
                ],
              );
            }),
            TextButton(onPressed: () {
              items.add({'text': '', 'checked': false});
              provider.updateBlockContent(block['id'], items);
            }, child: const Text('+ Add Item')),
          ],
        );
      case 'chart':
        final content = block['content'];
        final List dataPoints = content['dataPoints'];
        return Column(
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Chart Title'),
              onChanged: (v) {
                content['chartTitle'] = v;
                provider.updateBlockContent(block['id'], content);
              },
            ),
            ...dataPoints.asMap().entries.map((entry) {
              int idx = entry.key;
              return Row(
                children: [
                  Expanded(child: TextField(decoration: const InputDecoration(hintText: 'Time'), onChanged: (v) {
                    dataPoints[idx]['label'] = v;
                    provider.updateBlockContent(block['id'], content);
                  })),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Value'), onChanged: (v) {
                    dataPoints[idx]['value'] = double.tryParse(v) ?? 0.0;
                    provider.updateBlockContent(block['id'], content);
                  })),
                ],
              );
            }),
            TextButton(onPressed: () {
              dataPoints.add({'label': '', 'value': 0.0});
              provider.updateBlockContent(block['id'], content);
            }, child: const Text('+ Add Data Point')),
            SizedBox(height: 150, child: _buildLineChart(dataPoints)),
          ],
        );
      case 'image':
      case 'file':
        return block['fileUrl'] == null 
          ? Center(child: TextButton.icon(onPressed: () => block['type'] == 'image' ? _pickImage(block['id']) : _pickFile(block['id']), icon: const Icon(Icons.upload), label: Text('Upload ${block['type']}')))
          : Text(block['fileUrl'], style: const TextStyle(fontSize: 12, color: Colors.blue));
      default:
        return const SizedBox();
    }
  }

  Widget _buildLineChart(List data) {
    if (data.isEmpty) return const SizedBox();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble())).toList(),
            isCurved: true,
            color: const Color(0xFF0FB2EA),
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetPicker() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _pickerBtn('Text', Icons.text_fields, 'text'),
          _pickerBtn('Checklist', Icons.check_box, 'checklist'),
          _pickerBtn('Chart', Icons.show_chart, 'chart'),
          _pickerBtn('Image', Icons.image, 'image'),
          _pickerBtn('File', Icons.attach_file, 'file'),
        ],
      ),
    );
  }

  Widget _pickerBtn(String label, IconData icon, String type) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: const Color(0xFF0066CC)),
        label: Text(label),
        onPressed: () => _handleAddWidget(type),
        backgroundColor: Colors.white,
      ),
    );
  }
}