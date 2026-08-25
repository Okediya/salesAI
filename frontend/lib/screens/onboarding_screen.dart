import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_ai_provider.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const OnboardingScreen({super.key, this.onNavigate});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();
  final _marketController = TextEditingController();
  final _pricingController = TextEditingController();
  final _valuePropsController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final active = context.read<SalesAiProvider>().activeProduct;
    if (active != null) {
      _nameController.text = active.name;
      _taglineController.text = active.tagline ?? '';
      _descController.text = active.description;
      _urlController.text = active.websiteUrl ?? '';
      _marketController.text = active.targetMarket ?? '';
      _pricingController.text = active.pricingModel ?? '';
      _valuePropsController.text = active.valuePropositions ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descController.dispose();
    _urlController.dispose();
    _marketController.dispose();
    _pricingController.dispose();
    _valuePropsController.dispose();
    super.dispose();
  }

  void _loadPreset(String title, String tagline, String desc, String url, String market, String pricing, String valProps) {
    _nameController.text = title;
    _taglineController.text = tagline;
    _descController.text = desc;
    _urlController.text = url;
    _marketController.text = market;
    _pricingController.text = pricing;
    _valuePropsController.text = valProps;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = context.read<SalesAiProvider>();
      await provider.onboardProduct({
        'name': _nameController.text.trim(),
        'tagline': _taglineController.text.trim(),
        'description': _descController.text.trim(),
        'website_url': _urlController.text.trim(),
        'target_market': _marketController.text.trim(),
        'pricing_model': _pricingController.text.trim(),
        'value_propositions': _valuePropsController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product DNA & ICP established successfully! 24/7 Prospecting kicked off.')),
        );
        if (widget.onNavigate != null) widget.onNavigate!(0); // Navigate to Mission Control
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Form(
            key: _formKey,
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
                      child: const Icon(Icons.psychology, color: AppTheme.cyanAccent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRODUCT DNA & ICP ONBOARDING',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppTheme.cyanAccent,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Teach SalesAI what you sell',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'SalesAI will analyze your product value proposition, synthesize ideal customer personas (ICP), and autonomously begin 24/7 prospecting and campaign generation.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Quick Startup Presets
                const Text(
                  'Quick Hackathon Presets:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      backgroundColor: AppTheme.bgSecondary,
                      avatar: const Icon(Icons.code, size: 16, color: AppTheme.cyanAccent),
                      label: const Text('DevPulse AI (DevTools)', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                      onPressed: () => _loadPreset(
                        'DevPulse AI',
                        'Autonomous Code Review & Performance Sentry',
                        'DevPulse AI autonomously analyzes enterprise pull requests, flags performance regressions, and suggests verified fixes before deployment.',
                        'https://devpulse.ai',
                        'Mid-to-large engineering teams, Series A-D B2B tech',
                        '\$299/mo per 10 engineers',
                        'Cuts code review time by 80%, prevents production regressions, saves \$150k/yr in CI compute'
                      ),
                    ),
                    ActionChip(
                      backgroundColor: AppTheme.bgSecondary,
                      avatar: const Icon(Icons.cloud, size: 16, color: AppTheme.purpleAccent),
                      label: const Text('CloudFin AI (FinOps)', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                      onPressed: () => _loadPreset(
                        'CloudFin AI',
                        'Autonomous Multi-Cloud Cost Optimization',
                        'CloudFin AI continuously monitors AWS and GCP infrastructure to automatically shut down idle workloads and renegotiate spot instances.',
                        'https://cloudfin.io',
                        'VP Infrastructure, CTOs at high-growth cloud SaaS',
                        '15% of verified cloud savings',
                        'Instant 30% reduction in cloud bills, zero manual DevOps overhead, continuous 24/7 sentry'
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: AppTheme.borderSubtle),
                const SizedBox(height: 20),

                // Form Fields
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product / Startup Name *',
                    hintText: 'e.g. Acme AI',
                    prefixIcon: Icon(Icons.business, size: 20),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Product name required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taglineController,
                  decoration: const InputDecoration(
                    labelText: 'One-Line Tagline',
                    hintText: 'e.g. Autonomous AI Outbound Sales Engine',
                    prefixIcon: Icon(Icons.short_text, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Product Description & Problem Solved *',
                    hintText: 'Describe what your product does, key capabilities, and who benefits...',
                    prefixIcon: Icon(Icons.description, size: 20),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Description required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'Website / Demo URL',
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.link, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _pricingController,
                        decoration: const InputDecoration(
                          labelText: 'Pricing Model',
                          hintText: 'e.g. \$49/mo, Free tier, \$5k pilot',
                          prefixIcon: Icon(Icons.monetization_on, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _marketController,
                  decoration: const InputDecoration(
                    labelText: 'Target Market / Industries',
                    hintText: 'e.g. B2B SaaS, E-commerce Tech, Healthcare AI',
                    prefixIcon: Icon(Icons.public, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valuePropsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Core Differentiators & Value Props',
                    hintText: 'e.g. 3x faster delivery, 50% cost savings, 24/7 autonomous operation...',
                    prefixIcon: Icon(Icons.star, size: 20),
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.rocket_launch),
                    label: Text(
                      _isSubmitting
                          ? 'StrategyAgent Analyzing Product DNA...'
                          : 'Activate 24/7 Autonomous Sales Engine',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
