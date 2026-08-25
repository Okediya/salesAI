import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://127.0.0.1:8000'});

  Future<DashboardStatsModel> getStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/agent/stats'));
      if (response.statusCode == 200) {
        return DashboardStatsModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error loading stats: $e');
    }
  }

  Future<List<LeadModel>> getLeads({String? status, int? productId}) async {
    try {
      String url = '$baseUrl/leads/';
      List<String> queryParams = [];
      if (status != null) queryParams.add('status=$status');
      if (productId != null) queryParams.add('product_id=$productId');
      if (queryParams.isNotEmpty) url += '?${queryParams.join('&')}';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LeadModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load leads: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error loading leads: $e');
    }
  }

  Future<ProductModel?> getActiveProduct() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/active'));
      if (response.statusCode == 200) {
        if (response.body == 'null' || response.body.isEmpty) return null;
        return ProductModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<ProductModel> onboardProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productData),
      );
      if (response.statusCode == 200) {
        return ProductModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Onboarding failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error onboarding product: $e');
    }
  }

  Future<List<CampaignModel>> getCampaigns({int? leadId}) async {
    try {
      String url = '$baseUrl/campaigns/';
      if (leadId != null) url += '?lead_id=$leadId';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CampaignModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load campaigns: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error loading campaigns: $e');
    }
  }

  Future<void> updateLeadStatus(int leadId, String newStatus) async {
    try {
      await http.patch(
        Uri.parse('$baseUrl/leads/$leadId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );
    } catch (e) {
      throw Exception('Failed to update lead status: $e');
    }
  }

  Future<void> controlAgent(String action, {String? mode, int? interval}) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/agent/control'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': action,
          if (mode != null) 'autonomy_mode': mode,
          if (interval != null) 'cycle_interval': interval,
        }),
      );
    } catch (e) {
      throw Exception('Failed to control agent: $e');
    }
  }

  Future<void> seedDemo() async {
    try {
      await http.post(Uri.parse('$baseUrl/agent/seed-demo'));
    } catch (e) {
      throw Exception('Failed to seed demo data: $e');
    }
  }

  Future<Map<String, dynamic>> simulateReply(int leadId, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/leads/$leadId/simulate-reply?message=${Uri.encodeComponent(message)}'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to simulate reply: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error simulating reply: $e');
    }
  }

  Future<LeadModel> createLead(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/leads/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return LeadModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create lead: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error creating lead: $e');
    }
  }

  Future<Map<String, dynamic>> dispatchEmail(int leadId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/leads/$leadId/dispatch-email'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to dispatch email: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error dispatching email: $e');
    }
  }

  Future<Map<String, dynamic>> dispatchWhatsApp(int leadId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/leads/$leadId/dispatch-whatsapp'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to dispatch WhatsApp: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error dispatching WhatsApp: $e');
    }
  }
}

final apiService = ApiService();
