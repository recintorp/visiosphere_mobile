import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class GuardianAlertsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const GuardianAlertsScreen({super.key, this.onMenuTap});

  @override
  State<GuardianAlertsScreen> createState() => _GuardianAlertsScreenState();
}

class _GuardianAlertsScreenState extends State<GuardianAlertsScreen> {
  final List<Map<String, dynamic>> _alerts = [
    {
      'id': '1',
      'title': 'Fall Detected',
      'time': '5m ago',
      'description': 'Your assigned elder was detected experiencing a fall in the Living Room.',
      'severity': 'critical',
      'icon': Icons.warning_amber_rounded,
      'isAcknowledged': false,
      'nurseMessage': null,
    },
    {
      'id': '2',
      'title': 'Abnormal Temperature',
      'time': '4:36 AM',
      'description': 'Your assigned elder recorded a high temperature of 38.5°C.',
      'severity': 'high',
      'icon': Icons.thermostat,
      'isAcknowledged': true,
      'nurseMessage': 'You: "Thank you for letting me know, I will monitor."',
    },
    {
      'id': '3',
      'title': 'Agitation Detected',
      'time': 'Yesterday',
      'description': 'Elevated pacing and agitation detected in the Garden Area.',
      'severity': 'medium',
      'icon': Icons.psychology,
      'isAcknowledged': true,
      'nurseMessage': null,
    },
  ];

  void _acknowledgeAlert(int index) {
    setState(() {
      _alerts[index]['isAcknowledged'] = true;
    });
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
            'Real-Time Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF001F2D),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: Colors.blueGrey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                itemCount: _alerts.length,
                itemBuilder: (context, index) {
                  return FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: Duration(milliseconds: 100 * index),
                    child: _buildAlertCard(_alerts[index], index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, int index) {
    Color severityColor;
    Color iconBgColor;

    switch (alert['severity']) {
      case 'critical':
        severityColor = const Color(0xFFFF4B4B);
        iconBgColor = const Color(0xFFFFEAEA);
        break;
      case 'high':
        severityColor = const Color(0xFFFF9800);
        iconBgColor = const Color(0xFFFFF0DB);
        break;
      case 'medium':
      default:
        severityColor = const Color(0xFFFFB74D);
        iconBgColor = const Color(0xFFFFF4E5);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: severityColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(alert['icon'], color: severityColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            alert['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001F2D),
                            ),
                          ),
                        ),
                        Text(
                          alert['time'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      alert['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A5568),
                        height: 1.4,
                      ),
                    ),
                    if (alert['nurseMessage'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FBFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blueGrey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.reply, size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                alert['nurseMessage'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: alert['isAcknowledged']
                              ? Row(
                                  key: const ValueKey('acknowledged'),
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Acknowledged',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                )
                              : ElevatedButton(
                                  key: const ValueKey('confirm_button'),
                                  onPressed: () => _acknowledgeAlert(index),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF004B6B),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    'Confirm',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Message Nurse'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0FB2EA),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}