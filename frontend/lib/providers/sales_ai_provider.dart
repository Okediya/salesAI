import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class SalesAiProvider with ChangeNotifier {
  final ApiService _api = apiService;
  final WebSocketService _ws = wsService;

  DashboardStatsModel? _stats;
  List<LeadModel> _leads = [];
  List<CampaignModel> _campaigns = [];
  ProductModel? _activeProduct;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  final List<Map<String, dynamic>> _chatMessages = [
    {
      'sender': 'bot',
      'text': 'Hello. I am SalesAI, your dedicated autonomous sales and marketing partner. Give me your phone number, email, or startup website, and I will begin finding customers and driving your outbound pipeline.',
      'time': DateTime.now(),
    }
  ];
  bool _isChatLoading = false;

  DashboardStatsModel? get stats => _stats;
  List<LeadModel> get leads => _leads;
  List<CampaignModel> get campaigns => _campaigns;
  ProductModel? get activeProduct => _activeProduct;
  List<Map<String, dynamic>> get chatMessages => _chatMessages;
  bool get isChatLoading => _isChatLoading;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAgentRunning => _stats?.agentState.isRunning ?? false;
  String get autonomyMode => _stats?.agentState.autonomyMode ?? 'AUTOPILOT';
  String get currentTask => _stats?.agentState.currentTask ?? 'Idle';

  SalesAiProvider() {
    _init();
  }

  void _init() {
    fetchInitialData();
    _ws.addListener(_onWsEvent);
    _ws.connect();

    // Fallback periodic poll to guarantee UI fresh state
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      refreshStatsSilent();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _ws.removeListener(_onWsEvent);
    super.dispose();
  }

  void _onWsEvent(String event, Map<String, dynamic> data) {
    // When any background cycle finishes or events fire, refresh stats & leads
    refreshStatsSilent();
    fetchLeadsSilent();
    fetchCampaignsSilent();
  }

  Future<void> fetchInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        refreshStatsSilent(),
        fetchLeadsSilent(),
        fetchCampaignsSilent(),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshStatsSilent() async {
    try {
      _stats = await _api.getStats();
      _activeProduct = _stats?.activeProduct;
      notifyListeners();
    } catch (e) {
      // debug
    }
  }

  Future<void> fetchLeadsSilent() async {
    try {
      _leads = await _api.getLeads();
      notifyListeners();
    } catch (e) {
      // debug
    }
  }

  Future<void> fetchCampaignsSilent() async {
    try {
      _campaigns = await _api.getCampaigns();
      notifyListeners();
    } catch (e) {
      // debug
    }
  }

  Future<void> onboardProduct(Map<String, dynamic> productData) async {
    _isLoading = true;
    notifyListeners();
    try {
      _activeProduct = await _api.onboardProduct(productData);
      await refreshStatsSilent();
      await fetchLeadsSilent();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleAgentRunning() async {
    final newAction = isAgentRunning ? 'PAUSE' : 'START';
    await _api.controlAgent(newAction);
    await refreshStatsSilent();
  }

  Future<void> toggleAutonomyMode() async {
    final newMode = autonomyMode == 'AUTOPILOT' ? 'COPILOT' : 'AUTOPILOT';
    await _api.controlAgent('SET_MODE', mode: newMode);
    await refreshStatsSilent();
  }

  Future<void> triggerManualCycle() async {
    await _api.controlAgent('TRIGGER_CYCLE');
    await refreshStatsSilent();
    await fetchLeadsSilent();
    await fetchCampaignsSilent();
  }


  Future<void> updateLeadPipelineStatus(int leadId, String status) async {
    await _api.updateLeadStatus(leadId, status);
    await fetchLeadsSilent();
    await refreshStatsSilent();
  }

  Future<Map<String, dynamic>> testSdrReply(int leadId, String message) async {
    final result = await _api.simulateReply(leadId, message);
    await fetchLeadsSilent();
    await refreshStatsSilent();
    return result;
  }

  Future<LeadModel> createCustomLead(Map<String, dynamic> leadData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final lead = await _api.createLead(leadData);
      await fetchLeadsSilent();
      await fetchCampaignsSilent();
      await refreshStatsSilent();
      return lead;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> dispatchEmail(int leadId) async {
    try {
      final result = await _api.dispatchEmail(leadId);
      await fetchLeadsSilent();
      await fetchCampaignsSilent();
      await refreshStatsSilent();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> dispatchWhatsApp(int leadId) async {
    try {
      final result = await _api.dispatchWhatsApp(leadId);
      await fetchLeadsSilent();
      await fetchCampaignsSilent();
      await refreshStatsSilent();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> dispatchTelegram(int leadId) async {
    try {
      final result = await _api.dispatchTelegram(leadId);
      await fetchLeadsSilent();
      await fetchCampaignsSilent();
      await refreshStatsSilent();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> syncWebsite(int productId, {String? websiteUrl}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _api.syncWebsite(productId, websiteUrl: websiteUrl);
      await refreshStatsSilent();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> analyzeProductImage(int productId, String imageBase64, {String? notes}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _api.analyzeProductImage(productId, imageBase64, notes: notes);
      await refreshStatsSilent();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> handleInboundMessage(
    int leadId,
    String message, {
    String channel = 'TELEGRAM',
    bool autoDispatch = true,
  }) async {
    try {
      final result = await _api.handleInboundMessage(
        leadId,
        message,
        channel: channel,
        autoDispatch: autoDispatch,
      );
      await fetchLeadsSilent();
      await fetchCampaignsSilent();
      await refreshStatsSilent();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendChatMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Append user message immediately
    _chatMessages.add({
      'sender': 'user',
      'text': trimmed,
      'time': DateTime.now(),
    });
    _isChatLoading = true;
    notifyListeners();

    try {
      final history = _chatMessages.map((m) => {
        'role': m['sender'] == 'user' ? 'user' : 'model',
        'parts': m['text'].toString(),
      }).toList();

      final res = await _api.sendChatMessage(trimmed, history: history.cast<Map<String, String>>());
      final botReply = res['reply'] as String? ?? 'Message processed.';

      _chatMessages.add({
        'sender': 'bot',
        'text': botReply,
        'time': DateTime.now(),
        'action_type': res['action_type'],
        'action_data': res['action_data'],
      });

      await refreshStatsSilent();
      await fetchLeadsSilent();
      await fetchCampaignsSilent();
    } catch (e) {
      _chatMessages.add({
        'sender': 'bot',
        'text': 'I encountered an issue processing your request: $e. Please verify backend connection.',
        'time': DateTime.now(),
      });
    } finally {
      _isChatLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> batchImportLeads(String rawContacts) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _api.batchImportLeads(rawContacts);
      await fetchLeadsSilent();
      await fetchCampaignsSilent();
      await refreshStatsSilent();
      
      // Also post a summary message into the bot chat
      _chatMessages.add({
        'sender': 'bot',
        'text': 'Imported ${result['imported_count']} new contacts into your sales pipeline. Automated daily follow-ups and touchpoints are scheduled.',
        'time': DateTime.now(),
      });
      
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

