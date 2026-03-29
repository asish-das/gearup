import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gearup/theme/app_theme.dart';

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

    // Check for direct navigation requests
    if (lowerText.contains("book service") || lowerText.contains("book appointment") || lowerText.contains("book now")) {
      Navigator.pop(context, 2); // Return index 2 (Centers) to MainNavigation
      return;
    } else if (lowerText.contains("emergency request") || lowerText.contains("emergency assistance") || lowerText.contains("emergency help")) {
      Navigator.pop(context, 'emergency'); // Return action to MainNavigation
      return;
    }

    // Check if the user is confirming a pending action
    if (lowerText == "yes" || lowerText == "sure" || lowerText == "ok" || lowerText == "yeah" || lowerText == "yep" || lowerText == "please") {
      if (_pendingAction == 'booking') {
        _pendingAction = null;
        Navigator.pop(context, 2);
        return;
      } else if (_pendingAction == 'emergency') {
        _pendingAction = null;
        Navigator.pop(context, 'emergency');
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
      aiResponse = "A noise could indicate an engine or suspension issue. What type of service would you like to take?";
      suggestions = ["Book Service", "Emergency Request", "No thanks"];
    } else if (lowerText.contains("brakes") || lowerText.contains("squeak")) {
      aiResponse = "Brake issues can be serious. What type of assistance do you need?";
      suggestions = ["Book Service", "Emergency Request", "I'm okay"];
    } else if (lowerText.contains("oil") || lowerText.contains("change")) {
      aiResponse = "I recommend an oil change every 5,000 miles. Would you like to schedule one or do you need roadside help?";
      suggestions = ["Book Service", "Emergency Request"];
    } else if (lowerText.contains("battery") || lowerText.contains("won't start")) {
      aiResponse = "Battery issues usually need immediate help. What would you like to do?";
      suggestions = ["Book Service", "Emergency Request"];
    } else if (lowerText.contains("ac") || lowerText.contains("cold") || lowerText.contains("air condition")) {
      aiResponse = "Hot weather is tough without AC! How would you like to proceed?";
      suggestions = ["Book Service", "Emergency Request"];
    } else if (lowerText.contains("steering") || lowerText.contains("shaking")) {
      aiResponse = "Steering issues can be dangerous. What type of assistance would you like?";
      suggestions = ["Book Service", "Emergency Request"];
    } else if (lowerText.contains("engine light")) {
      aiResponse = "The engine light needs a specialized diagnostic scan. Would you like to book a scan or need emergency towing?";
      suggestions = ["Book Service", "Emergency Request"];
    } else if (lowerText.contains("flat tire") || lowerText.contains("tire")) {
      aiResponse = "A flat tire is annoying! I can help you find a center or send emergency help right now.";
      suggestions = ["Book Service", "Emergency Request"];
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
