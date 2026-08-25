import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/sales_ai_provider.dart';
import '../theme/app_theme.dart';

class SimulateReplyModal extends StatefulWidget {
  final LeadModel lead;

  const SimulateReplyModal({super.key, required this.lead});

  @override
  State<SimulateReplyModal> createState() => _SimulateReplyModalState();
}

class _SimulateReplyModalState extends State<SimulateReplyModal> {
  final TextEditingController _controller = TextEditingController();
  bool _isProcessing = false;
  Map<String, dynamic>? _analysisResult;

  final List<String> _quickTemplates = [
    "We're interested in scaling this. Can you send over pricing or a demo link?",
    "Looks nice, but our Q3 budget is completely locked right now. Any discount?",
    "How does this integrate with our current CRM and tech stack?",
    "Please unsubscribe me and remove me from your list."
  ];

  String _selectedChannel = 'TELEGRAM';
  bool _autoDispatch = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _analysisResult = null;
    });

    try {
      final provider = context.read<SalesAiProvider>();
      final result = await provider.handleInboundMessage(
        widget.lead.id,
        text,
        channel: _selectedChannel,
        autoDispatch: _autoDispatch,
      );
      setState(() {
        _analysisResult = {
          'sentiment': result['sentiment'],
          'intent_score': result['intent_score'],
          'recommended_action': result['recommended_action'],
          'suggested_reply': result['agent_reply'],
          'dispatch_result': result['dispatch_result'],
        };
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing reply: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology, color: AppTheme.cyanAccent, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Simulate Inbound Reply from ${widget.lead.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Quick Presets:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickTemplates.map((template) {
                  return ActionChip(
                    backgroundColor: AppTheme.bgSecondary,
                    label: Text(
                      template.length > 40 ? '${template.substring(0, 40)}...' : template,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
                    ),
                    onPressed: () {
                      _controller.text = template;
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter simulated message from lead...',
                  labelText: 'Inbound Message',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedChannel,
                          dropdownColor: AppTheme.bgCard,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'TELEGRAM', child: Text('Channel: Telegram', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
                            DropdownMenuItem(value: 'EMAIL', child: Text('Channel: Email', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
                            DropdownMenuItem(value: 'WHATSAPP', child: Text('Channel: WhatsApp', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
                          ],
                          onChanged: (val) => setState(() => _selectedChannel = val ?? 'TELEGRAM'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _autoDispatch,
                        activeColor: AppTheme.cyanAccent,
                        checkColor: Colors.black,
                        onChanged: (val) => setState(() => _autoDispatch = val ?? false),
                      ),
                      const Text('Auto-Dispatch Reply', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _submitReply,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isProcessing ? 'SDR Analyzing...' : 'Run SDR Autonomous Analysis & Reply'),
                ),
              ),
              if (_analysisResult != null) ...[
                const SizedBox(height: 20),
                const Divider(color: AppTheme.borderSubtle),
                const SizedBox(height: 14),
                const Text(
                  'SDR AGENT REAL-TIME INTENT ANALYSIS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppTheme.emeraldGreen,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildResultMetric('Sentiment', _analysisResult!['sentiment'] ?? 'NEUTRAL', AppTheme.cyanAccent),
                    const SizedBox(width: 12),
                    _buildResultMetric('Intent Score', '${_analysisResult!['intent_score'] ?? 0}/100', AppTheme.purpleAccent),
                    const SizedBox(width: 12),
                    _buildResultMetric('Action', _analysisResult!['recommended_action'] ?? 'NONE', AppTheme.emeraldGreen),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Generated Counter-Response:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Text(
                    _analysisResult!['suggested_reply'] ?? '',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultMetric(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
