import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_ai_provider.dart';
import '../theme/app_theme.dart';

class AgentPulseCard extends StatefulWidget {
  const AgentPulseCard({super.key});

  @override
  State<AgentPulseCard> createState() => _AgentPulseCardState();
}

class _AgentPulseCardState extends State<AgentPulseCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesAiProvider>();
    final isRunning = provider.isAgentRunning;
    final mode = provider.autonomyMode;
    final currentTask = provider.currentTask;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRunning ? AppTheme.cyanAccent.withOpacity(0.3) : AppTheme.borderSubtle,
          width: 1.5,
        ),
        boxShadow: isRunning
            ? [
                BoxShadow(
                  color: AppTheme.cyanAccent.withOpacity(0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isRunning ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRunning ? AppTheme.emeraldGreen : AppTheme.amberWarning,
                        boxShadow: isRunning
                            ? [
                                BoxShadow(
                                  color: AppTheme.emeraldGreen.withOpacity(0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRunning ? '24/7 TASKMASTER AUTONOMOUS LOOP ACTIVE' : 'AGENT PAUSED',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isRunning ? AppTheme.emeraldGreen : AppTheme.amberWarning,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Autonomy Mode: $mode',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Autopilot / Copilot Switch
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    _buildModeButton(context, 'AUTOPILOT', mode == 'AUTOPILOT', () {
                      if (mode != 'AUTOPILOT') provider.toggleAutonomyMode();
                    }),
                    _buildModeButton(context, 'COPILOT', mode == 'COPILOT', () {
                      if (mode != 'COPILOT') provider.toggleAutonomyMode();
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppTheme.cyanAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current Goal: $currentTask',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => provider.triggerManualCycle(),
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Trigger Cycle', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => provider.toggleAgentRunning(),
                  icon: Icon(
                    isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: isRunning ? AppTheme.amberWarning : AppTheme.emeraldGreen,
                    size: 28,
                  ),
                  tooltip: isRunning ? 'Pause 24/7 Loop' : 'Start 24/7 Loop',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(BuildContext context, String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cyanAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
