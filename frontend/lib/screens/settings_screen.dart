import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_ai_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _searchGroundingEnabled = true;
  double _confidenceThreshold = 0.75;
  int _cycleIntervalSeconds = 30;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesAiProvider>();
    final isRunning = provider.isAgentRunning;
    final mode = provider.autonomyMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cyanAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune, color: AppTheme.cyanAccent, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TASKMASTER AGENT TUNING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppTheme.cyanAccent,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Autonomous Loop & Gemini Settings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: AppTheme.borderSubtle),
              const SizedBox(height: 20),

              // Autonomy Mode Card
              const Text(
                'Autonomy Level',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildAutonomyOption(
                      title: 'AUTOPILOT (Full Autonomy)',
                      description: 'Prospects leads, generates copy, and dispatches campaigns 24/7 without manual approval.',
                      isSelected: mode == 'AUTOPILOT',
                      color: AppTheme.emeraldGreen,
                      onTap: () {
                        if (mode != 'AUTOPILOT') provider.toggleAutonomyMode();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAutonomyOption(
                      title: 'COPILOT (Human-in-the-Loop)',
                      description: 'Prepares leads and campaigns in DRAFT mode for 1-click human verification before sending.',
                      isSelected: mode == 'COPILOT',
                      color: AppTheme.purpleAccent,
                      onTap: () {
                        if (mode != 'COPILOT') provider.toggleAutonomyMode();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(color: AppTheme.borderSubtle),
              const SizedBox(height: 20),

              // Loop Frequency Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Autonomous Cycle Interval',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  Text(
                    '${_cycleIntervalSeconds}s (Demo Speed)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.cyanAccent),
                  ),
                ],
              ),
              Slider(
                value: _cycleIntervalSeconds.toDouble(),
                min: 10,
                max: 120,
                divisions: 11,
                activeColor: AppTheme.cyanAccent,
                inactiveColor: AppTheme.bgSecondary,
                onChanged: (v) {
                  setState(() {
                    _cycleIntervalSeconds = v.toInt();
                  });
                },
              ),

              const SizedBox(height: 20),

              // Google Search Grounding Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Google Search Grounding (Gemini Tool)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Grounds company prospecting and competitor intelligence in live web data.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                value: _searchGroundingEnabled,
                activeColor: AppTheme.cyanAccent,
                onChanged: (val) {
                  setState(() {
                    _searchGroundingEnabled = val;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Minimum Confidence Threshold
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Minimum Prospect Confidence Threshold',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  Text(
                    '${(_confidenceThreshold * 100).toInt()}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.purpleAccent),
                  ),
                ],
              ),
              Slider(
                value: _confidenceThreshold,
                min: 0.5,
                max: 0.95,
                divisions: 9,
                activeColor: AppTheme.purpleAccent,
                inactiveColor: AppTheme.bgSecondary,
                onChanged: (v) {
                  setState(() {
                    _confidenceThreshold = v;
                  });
                },
              ),

              const SizedBox(height: 24),
              const Divider(color: AppTheme.borderSubtle),
              const SizedBox(height: 20),

              // Quick Actions
              const Text(
                'Engine Controls',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => provider.toggleAgentRunning(),
                    icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(isRunning ? 'Pause Autonomous Engine' : 'Resume Autonomous Engine'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => provider.fetchInitialData(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Force UI Refresh'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutonomyOption({
    required String title,
    required String description,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? color : AppTheme.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
