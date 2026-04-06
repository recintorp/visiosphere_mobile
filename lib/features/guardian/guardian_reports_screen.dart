import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'providers/guardian_provider.dart';

class GuardianReportsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const GuardianReportsScreen({super.key, this.onMenuTap});

  @override
  State<GuardianReportsScreen> createState() => _GuardianReportsScreenState();
}

class _GuardianReportsScreenState extends State<GuardianReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedEmojiIndex;
  final TextEditingController _commentController = TextEditingController();
  bool _isSendingComment = false;

  final List<Map<String, dynamic>> _emojis = [
    {'emoji': '❤️', 'label': 'Love', 'key': 'heart'},
    {'emoji': '👍', 'label': 'Thanks', 'key': 'thumbsUp'},
    {'emoji': '😊', 'label': 'Happy', 'key': 'acknowledged'},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _getAssessmentForSelectedDate(List<dynamic> assessments) {
    for (var assessment in assessments) {
      if (assessment['createdAt'] != null) {
        DateTime createdAt = DateTime.parse(assessment['createdAt']).toLocal();
        if (createdAt.year == _selectedDate.year &&
            createdAt.month == _selectedDate.month &&
            createdAt.day == _selectedDate.day) {
          return assessment;
        }
      }
    }
    return null;
  }

  Widget _buildCustomAppBar() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF0FB2EA)),
            onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
          ),
          const Text(
            'Reports Archive',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF001F2D),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.blueGrey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuardianProvider>();
    final assignedElders = provider.assignedElders;
    final assessments = provider.assessments;

    final bool hasElder = assignedElders.isNotEmpty;
    final int currentIndex = provider.selectedElderIndex;
    
    final String elderName = (hasElder && currentIndex < assignedElders.length)
        ? '${assignedElders[currentIndex]['firstName']} ${assignedElders[currentIndex]['lastName']}'
        : (hasElder ? '${assignedElders[0]['firstName']} ${assignedElders[0]['lastName']}' : 'No Assigned Elder');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: _buildCalendarCard(assessments),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: _buildDailyJournalCard(hasElder, elderName, assessments),
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

  Widget _buildCalendarCard(List<dynamic> assessments) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'April 2026',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey.shade800,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.chevron_left, color: Colors.blueGrey.shade400),
                  const SizedBox(width: 16),
                  Icon(Icons.chevron_right, color: Colors.blueGrey.shade400),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCalendarGrid(assessments),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(List<dynamic> assessments) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    Set<int> daysWithReports = {};
    for (var a in assessments) {
      if (a['createdAt'] != null) {
        DateTime dt = DateTime.parse(a['createdAt']).toLocal();
        if (dt.year == 2026 && dt.month == 4) {
          daysWithReports.add(dt.day);
        }
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days
              .map((d) => Text(d,
                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)))
              .toList(),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 30,
          itemBuilder: (context, index) {
            int day = index + 1;
            bool isSelected = _selectedDate.day == day;
            bool hasReport = daysWithReports.contains(day);

            return GestureDetector(
              onTap: () => setState(() => _selectedDate = DateTime(2026, 4, day)),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF004B6B) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF001F2D),
                      ),
                    ),
                    if (hasReport && !isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDailyJournalCard(bool hasElder, String elderName, List<dynamic> assessments) {
    final String formattedDate = '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.year}';
    
    final assessment = _getAssessmentForSelectedDate(assessments);
    final bool hasReportData = assessment != null;

    if (hasReportData) {
      if (assessment['reactions'] != null) {
        for (int i = 0; i < _emojis.length; i++) {
          if (assessment['reactions'][_emojis[i]['key']] == true) {
            _selectedEmojiIndex = i;
            break;
          }
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.book_outlined, color: Color(0xFF0FB2EA), size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Daily Journal',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F2D)),
                        ),
                      ],
                    ),
                    if (hasReportData)
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                        onPressed: () {},
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildJournalHeaderItem('Elder', elderName),
                _buildJournalHeaderItem('Date', formattedDate),
                if (hasReportData) ...[
                  _buildJournalHeaderItem('Nurse', assessment['authorName'] ?? 'Unknown'),
                  const SizedBox(height: 8),
                  Text(
                    assessment['title'] ?? 'Daily Assessment',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF004B6B)),
                  ),
                ],
                const SizedBox(height: 16),
                
                if (!hasReportData)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.assignment_late_outlined, size: 48, color: Colors.blueGrey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          'No Report Available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001F2D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'There is no daily assessment filed for this date yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade400),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.05)),
                    ),
                    child: _renderBlocks(assessment['blocks']),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Leave a reaction:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_emojis.length, (index) {
                      bool isSelected = _selectedEmojiIndex == index;
                      return GestureDetector(
                        onTap: () async {
                          setState(() {
                            if (_selectedEmojiIndex == index) {
                              _selectedEmojiIndex = null;
                            } else {
                              _selectedEmojiIndex = index;
                            }
                          });
                          
                          final reactionKey = _emojis[index]['key'];
                          final isActive = _selectedEmojiIndex == index;
                          
                          final success = await context.read<GuardianProvider>().sendReaction(
                            assessment['_id'], 
                            reactionKey, 
                            isActive
                          );
                          
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isActive ? 'Reaction added' : 'Reaction removed'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE8F4FD) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0FB2EA).withValues(alpha: 0.3) : Colors.transparent,
                            ),
                          ),
                          child: Text(_emojis[index]['emoji'], style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Message to the Care Team:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Type your message or follow-up question here...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.blueGrey.shade300),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0FB2EA)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSendingComment 
                        ? null 
                        : () async {
                            if (_commentController.text.trim().isEmpty) return;
                            
                            setState(() => _isSendingComment = true);
                            
                            final success = await context.read<GuardianProvider>().sendComment(
                              assessment['_id'], 
                              _commentController.text
                            );
                            
                            if (mounted) {
                              setState(() => _isSendingComment = false);
                              if (success) {
                                _commentController.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Comment sent to care team')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to send comment. Try again.')),
                                );
                              }
                            }
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0FB2EA),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSendingComment 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Send Message', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (assessment['comments'] != null && assessment['comments'].isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Previous Comments:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF001F2D)),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(assessment['comments'].length, (index) {
                      final comment = assessment['comments'][index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  comment['senderName'] ?? 'User',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: comment['senderRole'] == 'Guardian' ? Colors.blue.shade50 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    comment['senderRole'] ?? '',
                                    style: TextStyle(
                                      fontSize: 10, 
                                      color: comment['senderRole'] == 'Guardian' ? Colors.blue.shade700 : Colors.green.shade700
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              comment['text'] ?? '',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ]
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderBlocks(List<dynamic>? blocks) {
    if (blocks == null || blocks.isEmpty) {
      return const Text('No detailed notes provided.', style: TextStyle(color: Colors.blueGrey));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map<Widget>((block) {
        final type = block['type'];
        final content = block['content'];
        final fileUrl = block['fileUrl'];

        if (type == 'text') {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              content?.toString() ?? '',
              style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568), height: 1.5),
            ),
          );
        }

        if (type == 'checklist' && content is List) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content.map<Widget>((item) {
                final bool isChecked = item['checked'] == true;
                final String text = item['text']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 18,
                        color: isChecked ? const Color(0xFF0FB2EA) : Colors.blueGrey.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 14,
                            color: isChecked ? Colors.blueGrey : const Color(0xFF4A5568),
                            decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }

        if (type == 'image' && fileUrl != null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                fileUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  const Text('Image failed to load', style: TextStyle(color: Colors.red)),
              ),
            ),
          );
        }

        if (type == 'chart') {
          final title = content?['chartTitle'] ?? 'Data Chart';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD), 
                borderRadius: BorderRadius.circular(8)
              ),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart, color: Color(0xFF0FB2EA)),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F2D))),
                ]
              )
            )
          );
        }

        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildJournalHeaderItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F2D), fontSize: 13),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Color(0xFF4A5568), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}