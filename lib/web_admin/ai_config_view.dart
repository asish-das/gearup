import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIConfigView extends StatefulWidget {
  const AIConfigView({super.key});

  @override
  State<AIConfigView> createState() => _AIConfigViewState();
}

class _AIConfigViewState extends State<AIConfigView> {
  final _apiKeyController = TextEditingController();
  final _systemPromptController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedModel = 'Gemini 1.5 Pro';
  double _temperature = 0.7;
  bool _enableChatbot = true;
  bool _enableAnalysis = true;
  bool _enableHealthAlerts = true;
  bool _enableServiceSuggestions = true;

  @override
  void initState() {
    super.initState();
    _loadAIConfig();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  Future<void> _loadAIConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('ai_config')
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _apiKeyController.text = data['api_key'] ?? '';
          _systemPromptController.text = data['system_prompt'] ?? '';
          _selectedModel = data['model'] ?? 'Gemini 1.5 Pro';
          _temperature = (data['temperature'] ?? 0.7).toDouble();
          _enableChatbot = data['enable_chatbot'] ?? true;
          _enableAnalysis = data['enable_analysis'] ?? true;
          _enableHealthAlerts = data['enable_health_alerts'] ?? true;
          _enableServiceSuggestions = data['enable_service_suggestions'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading AI config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('config')
          .doc('ai_config')
          .set({
        'api_key': _apiKeyController.text,
        'system_prompt': _systemPromptController.text,
        'model': _selectedModel,
        'temperature': _temperature,
        'enable_chatbot': _enableChatbot,
        'enable_analysis': _enableAnalysis,
        'enable_health_alerts': _enableHealthAlerts,
        'enable_service_suggestions': _enableServiceSuggestions,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Configuration saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving AI config: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Container(
          color: const Color(0xFFF6F6F8),
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildModelCard(),
                      const SizedBox(height: 24),
                      _buildAPIKeyCard(),
                      const SizedBox(height: 24),
                      _buildPromptCard(),
                      const SizedBox(height: 24),
                      _buildCapabilitySwitches(),
                      const SizedBox(height: 24),
                      _buildRecommendationsCard(),
                      const SizedBox(height: 40),
                      _buildSaveButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF5D40D4).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy, color: Color(0xFF5D40D4), size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              'AI Configuration',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your core AI models, API integrations, and assistant behaviors across the platform.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildModelCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Core Model Settings',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI ENGINE',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedModel,
                          isExpanded: true,
                          items: [
                            'Gemini 1.5 Pro',
                            'Gemini 1.5 Flash',
                            'GPT-4o',
                            'GPT-4 Turbo',
                            'Claude 3.5 Sonnet',
                          ].map((model) {
                            return DropdownMenuItem(
                              value: model,
                              child: Text(model, style: GoogleFonts.manrope()),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedModel = val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TEMPERATURE',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          _temperature.toStringAsFixed(1),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D40D4),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _temperature,
                      min: 0,
                      max: 2,
                      activeColor: const Color(0xFF5D40D4),
                      inactiveColor: const Color(0xFFE2E8F0),
                      onChanged: (val) => setState(() => _temperature = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAPIKeyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'API Integration',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              const Icon(Icons.vpn_key_outlined, color: Colors.amber, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'API KEY',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter your AI service API key',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your API key is encrypted and never shared. Ensure your billable account is active.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global System Instructions',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Define the core personality and behavior constraints for all AI agents in the system.',
            style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _systemPromptController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'e.g. You are a helpful automotive service advisor for GearUp...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilitySwitches() {
    return Row(
      children: [
        Expanded(
          child: _buildSwitchCard(
            'Customer Chatbot',
            'Allow AI to interact with users for booking assistance.',
            Icons.chat_bubble_outline,
            _enableChatbot,
            (val) => setState(() => _enableChatbot = val),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildSwitchCard(
            'Automated Analysis',
            'AI-driven insights on revenue and growth reports.',
            Icons.insights_outlined,
            _enableAnalysis,
            (val) => setState(() => _enableAnalysis = val),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'AI Recommendations System (Free)',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ACTIVE',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Smart suggestions for vehicle owners and service centers such as health checks and service recommendations.',
            style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSwitchCard(
                  'Health Check Alerts',
                  'Proactive warnings based on vehicle data.',
                  Icons.monitor_heart_outlined,
                  _enableHealthAlerts,
                  (val) => setState(() => _enableHealthAlerts = val),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildSwitchCard(
                  'Service Suggestions',
                  'AI-driven recommended services.',
                  Icons.build_circle_outlined,
                  _enableServiceSuggestions,
                  (val) => setState(() => _enableServiceSuggestions = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF5D40D4).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF5D40D4), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF5D40D4),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: _isSaving ? null : _saveConfig,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5D40D4), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5D40D4).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                'Save Infrastructure Profile',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
        ),
      ),
    );
  }
}
