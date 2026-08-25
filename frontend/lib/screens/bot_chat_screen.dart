import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_ai_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/batch_upload_modal.dart';

class BotChatScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const BotChatScreen({super.key, this.onNavigate});

  @override
  State<BotChatScreen> createState() => _BotChatScreenState();
}

class _BotChatScreenState extends State<BotChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickPrompts = [
    "Find verified B2B decision makers for my product",
    "Draft a high-converting Telegram ad",
    "Follow up with all active prospects today",
    "Help me onboard my product and set up pricing",
    "Check pipeline metrics and conversion rate",
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = customText ?? _inputController.text.trim();
    if (text.isEmpty) return;

    if (customText == null) {
      _inputController.clear();
    }

    final provider = context.read<SalesAiProvider>();
    _scrollToBottom();
    await provider.sendChatMessage(text);
    _scrollToBottom();
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
    final messages = provider.chatMessages;
    final isLoading = provider.isChatLoading;
    final activeProduct = provider.activeProduct;

    return Column(
      children: [
        // Top Bot Banner & Active Product Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: AppTheme.bgSecondary,
            border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.pureWhite,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SALES AI BOT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    activeProduct != null
                        ? 'Active Product: ${activeProduct.name}'
                        : 'No product connected. Share your website or details below.',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _openBatchUpload,
                icon: const Icon(Icons.upload_file, size: 14, color: AppTheme.textPrimary),
                label: const Text('Import Contacts', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),

        // Quick Suggestion Chips Bar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: AppTheme.bgPrimary,
            border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _quickPrompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final prompt = _quickPrompts[index];
              return InkWell(
                onTap: () => _sendMessage(prompt),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    prompt,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ),
              );
            },
          ),
        ),

        // Chat Message List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: messages.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messages.length && isLoading) {
                return _buildTypingIndicator();
              }
              final msg = messages[index];
              final isUser = msg['sender'] == 'user';
              return _buildMessageBubble(msg['text'] ?? '', isUser, msg);
            },
          ),
        ),

        // Bottom Input Area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.bgSecondary,
            border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _openBatchUpload,
                icon: const Icon(Icons.add, color: AppTheme.textSecondary),
                tooltip: 'Paste or Import Customer List',
              ),
              Expanded(
                child: TextField(
                  controller: _inputController,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Type your message, phone, email, website link, or customer list...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: isLoading ? null : () => _sendMessage(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: const Icon(Icons.arrow_upward, size: 18, color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(String text, bool isUser, Map<String, dynamic> msg) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: const BoxConstraints(maxWidth: 650),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.bgCardHover : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUser ? AppTheme.borderGlow : AppTheme.borderSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isUser ? 'YOU' : 'SALES AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: isUser ? AppTheme.textSecondary : AppTheme.pureWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                height: 1.45,
              ),
            ),
            if (!isUser && msg['action_type'] == 'PROSPECTS_DISCOVERED') ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  if (widget.onNavigate != null) widget.onNavigate!(1); // Open Pipeline
                },
                child: const Text('View Discovered Leads in Pipeline', style: TextStyle(fontSize: 11)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.pureWhite),
            ),
            SizedBox(width: 10),
            Text(
              'SalesAI is thinking...',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
