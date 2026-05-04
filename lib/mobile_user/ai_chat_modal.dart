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
  bool _isTyping = false;

  void _sendMessage() {
    if (_controller.text.trim().isEmpty || _isTyping) return;

    final userText = _controller.text.trim();
    setState(() {
      _messages.add(ChatMessage(userText, true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Simulate AI response processing
    Future.delayed(const Duration(milliseconds: 1500), () {
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
      aiResponse = "No problem at all! I'll be right here if you need anything else.";
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(aiResponse, false));
      });
      _scrollToBottom();
      return;
    }

    // Reset pending action by default
    _pendingAction = null;
    
    if (lowerText.contains("making noise") || lowerText.contains("weird sound") || lowerText.contains("noise") || lowerText.contains("rattling")) {
      aiResponse = "I understand how concerning strange noises can be. It could be anything from a loose belt to a suspension issue or even engine trouble. It's usually best to get these checked out by a professional. Would you like me to help you book an inspection with one of our certified centers?";
      suggestions = ["Book Service", "Emergency Request", "No thanks"];
      _pendingAction = 'booking';
    } else if (lowerText.contains("brakes") || lowerText.contains("squeak") || lowerText.contains("grinding")) {
      aiResponse = "Brake issues are a serious safety concern. Squeaking or grinding often means your brake pads are worn down or your rotors need attention. For your safety, I strongly recommend getting this looked at immediately. Do you need emergency assistance or would you prefer to book a service appointment?";
      suggestions = ["Book Service", "Emergency Request", "I'm okay"];
      _pendingAction = 'booking';
    } else if (lowerText.contains("oil") || lowerText.contains("change") || lowerText.contains("service due")) {
      aiResponse = "Regular oil changes are vital for keeping your engine running smoothly! Generally, it's recommended every 5,000 to 7,500 miles depending on your vehicle and oil type. Would you like me to find a convenient service center to get this sorted out?";
      suggestions = ["Book Service", "Emergency Request"];
      _pendingAction = 'booking';
    } else if (lowerText.contains("battery") || lowerText.contains("won't start") || lowerText.contains("dead")) {
      aiResponse = "Oh no, a dead battery is incredibly frustrating! This could also be an issue with your alternator or starter. Since you might be stranded, would you like me to send emergency assistance your way, or just book a service appointment for a replacement?";
      suggestions = ["Emergency Request", "Book Service"];
      _pendingAction = 'emergency';
    } else if (lowerText.contains("ac") || lowerText.contains("cold") || lowerText.contains("air condition") || lowerText.contains("hot")) {
      aiResponse = "Driving without AC is definitely uncomfortable! This might just be a refrigerant leak or a faulty compressor. Our service centers can run an AC diagnostic and recharge it if necessary. Shall we book an appointment for that?";
      suggestions = ["Book Service", "No thanks"];
      _pendingAction = 'booking';
    } else if (lowerText.contains("steering") || lowerText.contains("shaking") || lowerText.contains("vibrating") || lowerText.contains("alignment")) {
      aiResponse = "A shaking steering wheel can be quite unsettling and is usually related to wheel alignment, tire balance, or suspension components. It's a critical safety issue, especially at higher speeds. Should we schedule a check-up right away?";
      suggestions = ["Book Service", "Emergency Request"];
      _pendingAction = 'booking';
    } else if (lowerText.contains("engine light") || lowerText.contains("check engine")) {
      aiResponse = "The check engine light can mean many things, from a loose gas cap to a serious engine misfire. It's best not to ignore it. A quick diagnostic scan can pinpoint the exact cause. Can I help you book a diagnostic appointment?";
      suggestions = ["Book Service", "Emergency Request", "No thanks"];
      _pendingAction = 'booking';
    } else if (lowerText.contains("flat tire") || lowerText.contains("tire") || lowerText.contains("puncture")) {
      aiResponse = "Dealing with a flat tire is never fun. If you're currently stranded, I can dispatch an emergency roadside team to assist you immediately. Or, if you're safe, we can look into booking a tire repair or replacement. What do you need right now?";
      suggestions = ["Emergency Request", "Book Service"];
      _pendingAction = 'emergency';
    } else if (lowerText.contains("hello") || lowerText.contains("hi") || lowerText.contains("hey")) {
      aiResponse = "Hello! I'm GearUp AI, your personal virtual mechanic assistant. You can tell me about any issues you're experiencing with your vehicle, or ask me to help you book a service or request emergency assistance. How can I help you today?";
      suggestions = ["Book Service", "Emergency Request"];
    }

    if (!mounted) return;
    setState(() {
      _isTyping = false;
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
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
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

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(0),
          ),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "GearUp AI is typing...",
              style: GoogleFonts.manrope(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
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
