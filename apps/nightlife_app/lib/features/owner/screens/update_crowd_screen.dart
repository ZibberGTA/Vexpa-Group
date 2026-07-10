import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/home_icon_button.dart';
import '../../../core/widgets/premium_scaffold.dart';
import '../../analytics/services/analytics_service.dart';

class UpdateCrowdScreen extends StatefulWidget {
  final String venueId;
  final String venueName;
  final String currentLevel;

  const UpdateCrowdScreen({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.currentLevel,
  });

  @override
  State<UpdateCrowdScreen> createState() => _UpdateCrowdScreenState();
}

class _UpdateCrowdScreenState extends State<UpdateCrowdScreen> {
  String selectedLevel = '';

  final levels = [
    'quiet',
    'medium',
    'busy',
    'packed',
  ];

  final levelScores = {
    'quiet': 1,
    'steady': 2,
    'medium': 3,
    'busy': 4,
    'packed': 5,
  };

  @override
  void initState() {
    super.initState();
    selectedLevel = widget.currentLevel;
  }

  Future<void> _save() async {
    if (selectedLevel.isEmpty) return;

    await FirebaseFirestore.instance.collection('venues').doc(widget.venueId).update({
      'currentCrowdLevel': selectedLevel,
      'crowdLevel': selectedLevel,
      'currentCrowdScore': levelScores[selectedLevel] ?? 1,
      'crowdSource': 'owner',
      'crowdUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await AnalyticsService.logCrowdUpdate(
      venueId: widget.venueId,
      level: selectedLevel,
    );

    // Crowd changes are intentionally analytics-only.
    // User notifications are limited to saved-venue deals and events.

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Crowd updated')),
    );

    Navigator.pop(context);
  }

  Color _colorForLevel(String level) {
    switch (level) {
      case 'quiet':
        return Colors.green;
      case 'steady':
        return Colors.lightGreen;
      case 'medium':
        return Colors.orange;
      case 'busy':
        return Colors.deepOrange;
      case 'packed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _labelForLevel(String level) {
    switch (level) {
      case 'quiet':
        return 'Relaxed';
      case 'steady':
      case 'medium':
        return 'Steady';
      case 'busy':
        return 'Buzzing';
      case 'packed':
        return 'Lively';
      default:
        return level;
    }
  }

  String _descriptionForLevel(String level) {
    switch (level) {
      case 'quiet':
        return 'A relaxed atmosphere with plenty of space.';
      case 'steady':
      case 'medium':
        return 'A steady flow of customers with a comfortable atmosphere.';
      case 'busy':
        return 'A buzzing venue with strong atmosphere and good energy.';
      case 'packed':
        return 'A lively peak-time atmosphere with high energy.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Update Crowd - ${widget.venueName}'),
        actions: const [HomeIconButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF1E2030).withValues(alpha: 0.70),
              border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select current crowd level',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose the closest live crowd status for ${widget.venueName}.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...levels.map((level) {
            final selected = selectedLevel == level;
            final color = _colorForLevel(level);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    selectedLevel = level;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF1E2030).withValues(alpha: 0.70),
                    border: Border.all(
                      color: selected
                          ? color.withValues(alpha: 0.85)
                          : AppColors.primaryPurple.withValues(alpha: 0.24),
                      width: selected ? 1.4 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.18),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.groups_rounded, color: color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _labelForLevel(level),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _descriptionForLevel(level),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.64),
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle_rounded, color: color)
                      else
                        Icon(
                          Icons.radio_button_unchecked_rounded,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          _CrowdLogicCard(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Update Crowd'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrowdLogicCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.black.withValues(alpha: 0.36),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.schedule_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How crowd fading works',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Crowd levels naturally reduce over time if they are not updated again. This keeps DrinkSpot accurate when a venue forgets to refresh its status. For example: Packed can gradually reduce toward Busy, Medium and Quiet as time passes.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
