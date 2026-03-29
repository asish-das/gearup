import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:gearup/mobile_user/service_centers.dart';
import 'package:gearup/mobile_user/emergency_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? suggestions;
  ChatMessage(this.text, this.isUser, {this.suggestions});
}

class AIChatModal extends StatefulWidget {
  const AIChatModal({super.key});

  @override
  State<AIChatModal> createState() => _AIChatModalState();
}

class _AIChatModalState extends State<AIChatModal> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      "Hi there! I'm GearUp AI. How can I help you with your vehicle today?",
      false,
      suggestions: [
        "Car making noise",
        "Squeaky brakes",
        "Need an oil change",
        "Battery won't start",
        "AC not blowing cold",
        "Steering wheel shaking",
        "Check engine light is on",
        "Need flat tire help",
      ],
    )
  ];
  final ScrollController _scrollController = ScrollController();
  String? _pendingAction;

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text.trim();
    setState(() {
      _messages.add(ChatMessage(userText, true));
    });
    _controller.clear();
    _scrollToBottom();

    // Simulate AI response processing
    Future.delayed(const Duration(milliseconds: 600), () {
      _generateAIResponse(userText);
    });
  }

  void _generateAIResponse(String userText) {
    String aiResponse = "I can help with booking services or diagnosing basic issues. Could you provide more details?";
    List<String>? suggestions;
    final lowerText = userText.toLowerCase();

    // Check if the user is confirming a pending action
    if (lowerText == "yes" || lowerText == "sure" || lowerText == "ok" || lowerText == "yeah" || lowerText == "yep" || lowerText == "please") {
      if (_pendingAction == 'booking') {
        _pendingAction = null;
        Navigator.pop(context); // Close the chat
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceCentersScreen()));
        return;
      } else if (_pendingAction == 'emergency') {
        _pendingAction = null;
        Navigator.pop(context); // Close the chat
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen()));
        return;
      }
    } else if (lowerText == "no" || lowerText == "no thanks" || lowerText.contains("not right now") || lowerText.contains("later")) {
      _pendingAction = null;
      aiResponse = "No problem! Let me know if you need anything else.";
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(aiResponse, false));
      });
      _scrollToBottom();
      return;
    }

    // Reset pending action by default
    _pendingAction = null;
    
    if (lowerText.contains("making noise") || lowerText.contains("weird sound") || lowerText.contains("noise")) {
      aiResponse = "Possible engine issue. Recommend inspection. Would you like to book an appointment with a nearby service center?";
      _pendingAction = 'booking';
      suggestions = ["Yes", "No, thanks"];
    } else if (lowerText.contains("brakes") || lowerText.contains("squeak")) {
      aiResponse = "Brake pads might be worn out. It is crucial to have them checked for safety. Want me to help you book a service?";
      _pendingAction = 'booking';
      suggestions = ["Yes", "No"];
    } else if (lowerText.contains("oil") || lowerText.contains("change")) {
      aiResponse = "You can book an oil change easily from the app. I recommend synthetic oil for better engine health. Should we open the list of centers?";
      _pendingAction = 'booking';
      suggestions = ["Yes", "Not now"];
    } else if (lowerText.contains("battery") || lowerText.contains("won't start")) {
      aiResponse = "It looks like your battery might be dead or there's an alternator issue. Do you need emergency assistance?";
      _pendingAction = 'emergency';
      suggestions = ["Yes", "No"];
    } else if (lowerText.contains("ac") || lowerText.contains("cold") || lowerText.contains("air condition")) {
      aiResponse = "Your AC system might need a freon recharge or have a compressor issue. Want to check out some specialized service centers?";
      _pendingAction = 'booking';
      suggestions = ["Yes", "Maybe later"];
    } else if (lowerText.contains("steering") || lowerText.contains("shaking")) {
      aiResponse = "A shaking steering wheel usually indicates an alignment problem or unbalanced tires. Schedule an inspection soon. Open service centers?";
      _pendingAction = 'booking';
      suggestions = ["Yes", "No"];
    } else if (lowerText.contains("engine light")) {
      aiResponse = "A check engine light can mean many things. I strongly recommend booking a diagnostic scan immediately. Want to book now?";
      _pendingAction = 'booking';
      suggestions = ["Yes", "I'll do it later"];
    } else if (lowerText.contains("flat tire") || lowerText.contains("tire") || lowerText.contains("emergency assistance to help")) {
      aiResponse = "We can dispatch emergency assistance to help with your tire. Do you want me to open the Emergency screen?";
      _pendingAction = 'emergency';
      suggestions = ["Yes", "No"];
    }

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(aiResponse, false, suggestions: suggestions));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GearUp AI',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Smart Health Checks & Suggestions',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Chat View
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          
          // Input Area
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Describe vehicle issue (e.g. Car making noise)...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.black26,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _sendMessage,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Column(
      crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: msg.isUser ? AppTheme.primary : AppTheme.surface,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
                bottomLeft: !msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
              ),
              border: msg.isUser ? null : Border.all(color: Colors.white12),
            ),
            child: Text(
              msg.text,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
        if (msg.suggestions != null && msg.suggestions!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: msg.suggestions!.map((suggestion) {
                return GestureDetector(
                  onTap: () {
                    _controller.text = suggestion;
                    _sendMessage();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      suggestion,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
