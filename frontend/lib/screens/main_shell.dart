import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_ai_provider.dart';
import '../theme/app_theme.dart';
import 'bot_chat_screen.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';
import 'pipeline_screen.dart';
import 'campaigns_screen.dart';
import 'settings_screen.dart';
import '../widgets/batch_upload_modal.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<String> _viewTitles = [
    'AI Sales Bot',
    'Pipeline Kanban',
    'Campaigns & Ads',
    'Product Setup & Sync',
    'Telemetry Dashboard',
    'Automation Settings',
  ];

  void _onNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openBatchUpload() {
    showDialog(
      context: context,
      builder: (_) => const BatchUploadModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesAiProvider>();
    final isRunning = provider.isAgentRunning;

    final List<Widget> screens = [
      BotChatScreen(onNavigate: _onNavigate),
      const PipelineScreen(),
      const CampaignsScreen(),
      OnboardingScreen(onNavigate: _onNavigate),
      DashboardScreen(onNavigate: _onNavigate),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSecondary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        shape: const Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: const Text(
                'SALES AI',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isRunning ? AppTheme.pureWhite : AppTheme.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isRunning ? 'AUTONOMOUS LOOP ACTIVE' : 'AGENT PAUSED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: isRunning ? AppTheme.textSecondary : AppTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          // View Switcher Dropdown Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedIndex,
                dropdownColor: AppTheme.bgCard,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.pureWhite),
                items: [
                  for (int i = 0; i < _viewTitles.length; i++)
                    DropdownMenuItem<int>(
                      value: i,
                      child: Text(
                        _viewTitles[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedIndex == i ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedIndex == i ? AppTheme.pureWhite : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedIndex = val;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Import Contacts Button
          OutlinedButton.icon(
            onPressed: _openBatchUpload,
            icon: const Icon(Icons.add, size: 14, color: AppTheme.pureWhite),
            label: const Text('Import List', style: TextStyle(fontSize: 12, color: AppTheme.pureWhite)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 10),

          // Quick Trigger Cycle Button
          ElevatedButton.icon(
            onPressed: () => provider.triggerManualCycle(),
            icon: const Icon(Icons.play_arrow, size: 14, color: Colors.black),
            label: const Text('Run Cycle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: screens[_selectedIndex],
    );
  }
}
