import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_ai_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';
import 'pipeline_screen.dart';
import 'campaigns_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _onNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesAiProvider>();
    final isRunning = provider.isAgentRunning;

    final List<Widget> screens = [
      DashboardScreen(onNavigate: _onNavigate),
      OnboardingScreen(onNavigate: _onNavigate),
      const PipelineScreen(),
      const CampaignsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Row(
        children: [
          // Sidebar / Nav Rail
          Container(
            width: 240,
            decoration: const BoxDecoration(
              color: AppTheme.bgSecondary,
              border: Border(right: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.cyanAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppTheme.cyanAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SalesAI',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'TaskMaster 24/7 Agent',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.cyanAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.borderSubtle, height: 1),
                const SizedBox(height: 16),

                // Navigation Items
                _buildNavItem(0, 'Mission Control', Icons.dashboard_rounded),
                _buildNavItem(1, 'Product DNA & ICP', Icons.psychology_rounded),
                _buildNavItem(2, 'Pipeline Kanban', Icons.view_kanban_rounded),
                _buildNavItem(3, 'Campaign Studio', Icons.campaign_rounded),
                _buildNavItem(4, 'Agent Tuning', Icons.tune_rounded),

                const Spacer(),

                // Bottom Autonomous Status Pill
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRunning ? AppTheme.emeraldGreen : AppTheme.amberWarning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isRunning ? '24/7 Autopilot' : 'Agent Paused',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isRunning ? AppTheme.emeraldGreen : AppTheme.amberWarning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Viewport
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppTheme.bgSecondary,
                    border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.smart_toy, color: AppTheme.cyanAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Google Agentic Hackathon: TaskMaster Track',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.purpleAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.purpleAccent.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'Gemini 2.5 Flash + ADK',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.purpleAccent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Active Page Content
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavigate(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cyanAccent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppTheme.cyanAccent.withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.cyanAccent : AppTheme.textSecondary,
            ),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
