class ProductModel {
  final int id;
  final String name;
  final String? tagline;
  final String description;
  final String? websiteUrl;
  final String? targetMarket;
  final String? pricingModel;
  final String? valuePropositions;
  final String? icpSummary;
  final String? targetRoles;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.name,
    this.tagline,
    required this.description,
    this.websiteUrl,
    this.targetMarket,
    this.pricingModel,
    this.valuePropositions,
    this.icpSummary,
    this.targetRoles,
    required this.isActive,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      tagline: json['tagline'],
      description: json['description'] ?? '',
      websiteUrl: json['website_url'],
      targetMarket: json['target_market'],
      pricingModel: json['pricing_model'],
      valuePropositions: json['value_propositions'],
      icpSummary: json['icp_summary'],
      targetRoles: json['target_roles'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class LeadModel {
  final int id;
  final int productId;
  final String name;
  final String company;
  final String? role;
  final String? email;
  final String? linkedinUrl;
  final String? twitterHandle;
  final String? companyWebsite;
  final String? industry;
  final double confidenceScore;
  final String status;
  final String? painPoints;
  final String? personalizationHooks;
  final bool isApproved;
  final DateTime createdAt;

  LeadModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.company,
    this.role,
    this.email,
    this.linkedinUrl,
    this.twitterHandle,
    this.companyWebsite,
    this.industry,
    required this.confidenceScore,
    required this.status,
    this.painPoints,
    this.personalizationHooks,
    required this.isApproved,
    required this.createdAt,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      company: json['company'] ?? '',
      role: json['role'],
      email: json['email'],
      linkedinUrl: json['linkedin_url'],
      twitterHandle: json['twitter_handle'],
      companyWebsite: json['company_website'],
      industry: json['industry'],
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.85,
      status: json['status'] ?? 'DISCOVERED',
      painPoints: json['pain_points'],
      personalizationHooks: json['personalization_hooks'],
      isApproved: json['is_approved'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now() 
          : DateTime.now(),
    );
  }
}

class CampaignModel {
  final int id;
  final int productId;
  final int? leadId;
  final String channel;
  final String? subject;
  final String body;
  final int sequenceStep;
  final String status;
  final DateTime? sentAt;
  final DateTime createdAt;

  CampaignModel({
    required this.id,
    required this.productId,
    this.leadId,
    required this.channel,
    this.subject,
    required this.body,
    required this.sequenceStep,
    required this.status,
    this.sentAt,
    required this.createdAt,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      leadId: json['lead_id'],
      channel: json['channel'] ?? 'EMAIL',
      subject: json['subject'],
      body: json['body'] ?? '',
      sequenceStep: json['sequence_step'] ?? 1,
      status: json['status'] ?? 'DRAFT',
      sentAt: json['sent_at'] != null ? DateTime.tryParse(json['sent_at']) : null,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now() 
          : DateTime.now(),
    );
  }
}

class ActivityLogModel {
  final int id;
  final String agentRole;
  final String action;
  final String? details;
  final String level;
  final DateTime createdAt;

  ActivityLogModel({
    required this.id,
    required this.agentRole,
    required this.action,
    this.details,
    required this.level,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] ?? 0,
      agentRole: json['agent_role'] ?? 'Agent',
      action: json['action'] ?? '',
      details: json['details'],
      level: json['level'] ?? 'INFO',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now() 
          : DateTime.now(),
    );
  }
}

class AgentStateModel {
  final bool isRunning;
  final String autonomyMode;
  final int cycleInterval;
  final int cyclesCompleted;
  final DateTime? lastCycleAt;
  final String currentTask;

  AgentStateModel({
    required this.isRunning,
    required this.autonomyMode,
    required this.cycleInterval,
    required this.cyclesCompleted,
    this.lastCycleAt,
    required this.currentTask,
  });

  factory AgentStateModel.fromJson(Map<String, dynamic> json) {
    return AgentStateModel(
      isRunning: json['is_running'] ?? false,
      autonomyMode: json['autonomy_mode'] ?? 'AUTOPILOT',
      cycleInterval: json['cycle_interval'] ?? 30,
      cyclesCompleted: json['cycles_completed'] ?? 0,
      lastCycleAt: json['last_cycle_at'] != null 
          ? DateTime.tryParse(json['last_cycle_at']) 
          : null,
      currentTask: json['current_task'] ?? 'Idle',
    );
  }
}

class DashboardStatsModel {
  final int totalLeads;
  final int discoveredLeads;
  final int contactedLeads;
  final int engagedLeads;
  final int qualifiedLeads;
  final int wonLeads;
  final int totalCampaignsSent;
  final double averageIntentScore;
  final AgentStateModel agentState;
  final ProductModel? activeProduct;
  final List<ActivityLogModel> recentActivities;

  DashboardStatsModel({
    required this.totalLeads,
    required this.discoveredLeads,
    required this.contactedLeads,
    required this.engagedLeads,
    required this.qualifiedLeads,
    required this.wonLeads,
    required this.totalCampaignsSent,
    required this.averageIntentScore,
    required this.agentState,
    this.activeProduct,
    required this.recentActivities,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalLeads: json['total_leads'] ?? 0,
      discoveredLeads: json['discovered_leads'] ?? 0,
      contactedLeads: json['contacted_leads'] ?? 0,
      engagedLeads: json['engaged_leads'] ?? 0,
      qualifiedLeads: json['qualified_leads'] ?? 0,
      wonLeads: json['won_leads'] ?? 0,
      totalCampaignsSent: json['total_campaigns_sent'] ?? 0,
      averageIntentScore: (json['average_intent_score'] as num?)?.toDouble() ?? 0.0,
      agentState: AgentStateModel.fromJson(json['agent_state'] ?? {}),
      activeProduct: json['active_product'] != null 
          ? ProductModel.fromJson(json['active_product']) 
          : null,
      recentActivities: (json['recent_activities'] as List<dynamic>?)
              ?.map((item) => ActivityLogModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}
