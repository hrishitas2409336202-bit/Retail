import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/ai_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:math';

class AIAdvisorChat extends StatefulWidget {
  const AIAdvisorChat({super.key});

  @override
  State<AIAdvisorChat> createState() => _AIAdvisorChatState();
}

class _AIAdvisorChatState extends State<AIAdvisorChat>
    with TickerProviderStateMixin {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSpeaking = false;
  String? _speakingMsgId; // which message is being read aloud
  late FlutterTts _tts;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  double _voiceLevel = 0.0;
  late AnimationController _typingController;
  late Animation<double> _typingAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final List<Map<String, String>> _quickSuggestions = [
    {'text': 'What should I restock today?', 'icon': '📦'},
    {'text': "Show today's sales summary", 'icon': '💰'},
    {'text': 'Which products are expiring soon?', 'icon': '⏰'},
    {'text': 'What are the top selling items?', 'icon': '🏆'},
    {'text': 'Predict demand for next week', 'icon': '📊'},
    {'text': 'Give me business tips', 'icon': '💡'},
  ];

  @override
  void initState() {
    super.initState();
    _typingController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
          ..repeat();
    _typingAnim = Tween<double>(begin: 0, end: 1).animate(_typingController);

    _pulseController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
          ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initTts();
    _initSpeech();
    _loadInitialInsights();
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') setState(() => _isListening = false);
      },
      onError: (val) => setState(() => _isListening = false),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          setState(() {
            _controller.text = val.recognizedWords;
          });
        },
      );
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() { _isSpeaking = false; _speakingMsgId = null; });
    });
    _tts.setErrorHandler((msg) {
      if (mounted) setState(() { _isSpeaking = false; _speakingMsgId = null; });
    });
  }

  Future<void> _speak(String text, String msgId) async {
    final plain = text
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'\*'), '')
        .replaceAll('•', '');

    if (_isSpeaking && _speakingMsgId == msgId) {
      await _tts.stop();
      if (mounted) setState(() { _isSpeaking = false; _speakingMsgId = null; });
      return;
    }
    if (_isSpeaking) await _tts.stop();
    setState(() { _isSpeaking = true; _speakingMsgId = msgId; });
    await _tts.speak(plain);
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    if (mounted) setState(() { _isSpeaking = false; _speakingMsgId = null; });
  }

  @override
  void dispose() {
    _tts.stop();
    _typingController.dispose();
    _pulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialInsights() async {
    if (!mounted) return;
    final state = context.read<AppState>();
    final lowStockCount = state.lowStockCount;
    final revenue = state.todayRevenue;
    final bills = state.todayBillsCount;
    final inventoryCount = state.inventory.length;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final welcomeMsg =
        "👋 $greeting! I'm **RetailIQ**, your smart store assistant.\n\n"
        "Here's your store snapshot:\n"
        "• 💰 Revenue today: ${state.currency}${revenue.toInt()}\n"
        "• 🧾 Bills processed: $bills\n"
        "• 📦 Products: $inventoryCount\n"
        "${lowStockCount > 0 ? '• ⚠️ $lowStockCount products need restocking!\n' : '• ✅ All stocks look healthy!\n'}"
        "\nWhat can I help you with today?";

    final msgId = 'msg_0';
    setState(() {
      _messages.add({'role': 'ai', 'id': msgId, 'text': ''});
      _isLoading = false;
    });
    await _simulateStreaming(welcomeMsg, msgId);

    if (lowStockCount > 0) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      final lowProducts = state.lowStockProducts
          .take(3)
          .map((p) => "${p.emoji} **${p.name}** (${p.stock} left)")
          .join('\n');
      
      final alertId = 'msg_alert';
      setState(() {
        _messages.add({
          'role': 'ai',
          'id': alertId,
          'text': '',
        });
      });
      await _simulateStreaming('🚨 **Urgent Restock Alert!**\n\n$lowProducts\n\nShould I draft purchase orders for these items?', alertId);
    }
  }

  Future<void> _simulateStreaming(String fullText, String msgId) async {
    final words = fullText.split(' ');
    String currentText = "";
    for (var word in words) {
      if (!mounted) return;
      currentText += "$word ";
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == msgId);
        if (idx != -1) {
          _messages[idx] = {..._messages[idx], 'text': currentText.trim()};
        }
      });
      _scrollToBottom();
      await Future.delayed(Duration(milliseconds: 30 + Random().nextInt(40)));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final query = (quickText ?? _controller.text).trim();
    if (query.isEmpty) return;
    HapticFeedback.lightImpact();
    final state = context.read<AppState>();
    final lang = state.currentLanguage;
    final msgId = 'user_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _messages.add({'role': 'user', 'id': msgId, 'text': query});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final history = _messages.length > 8
        ? _messages.sublist(_messages.length - 8)
        : _messages;

    final answer = await AIService.getAIAdvice(
        query, "Smart Analysis", state.inventory, state.sales, lang, history);

    if (mounted) {
      final aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _isLoading = false;
        _messages.add({'role': 'ai', 'id': aiMsgId, 'text': ''});
      });
      await _simulateStreaming(answer, aiMsgId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: const Color(0xFF060B18),
      appBar: _buildAppBar(state),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) return _buildTypingIndicator();
                final msg = _messages[index];
                return _buildMessage(msg['role']!, msg['text']!, msg['id']!);
              },
            ),
          ),
          if (!_isLoading && _messages.length <= 2) _buildQuickSuggestions(),
          _buildChatInput(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppState state) {
    return AppBar(
      backgroundColor: const Color(0xFF060B18),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
        onPressed: () {
          _stopSpeaking();
          Navigator.pop(context);
        },
      ),
      title: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(LucideIcons.bot, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('RetailIQ Advisor',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: Color(0xFF10B981), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  const Text('AI Powered · Smart Advisor',
                      style: TextStyle(fontSize: 10, color: Color(0xFF10B981))),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_isSpeaking)
          IconButton(
            icon: const Icon(LucideIcons.volumeX, color: Colors.redAccent, size: 20),
            onPressed: _stopSpeaking,
            tooltip: 'Stop speaking',
          ),
        IconButton(
          icon: const Icon(LucideIcons.rotateCcw, color: Colors.white38, size: 18),
          onPressed: () {
            _stopSpeaking();
            setState(() => _messages.clear());
            _loadInitialInsights();
          },
          tooltip: 'Clear chat',
        ),
      ],
    );
  }

  Widget _buildQuickSuggestions() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickSuggestions.length,
        itemBuilder: (context, i) {
          final s = _quickSuggestions[i];
          return GestureDetector(
            onTap: () => _sendMessage(s['text']),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F35),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s['icon']!, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(s['text']!,
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F35),
          borderRadius:
              BorderRadius.circular(20).copyWith(bottomLeft: Radius.zero),
        ),
        child: AnimatedBuilder(
          animation: _typingAnim,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.bot, color: Color(0xFF6C63FF), size: 14),
              const SizedBox(width: 8),
              ...List.generate(3, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(
                    alpha: (sin((_typingAnim.value * 2 * pi) + (i * 1.1)) + 1) / 2,
                  ),
                  shape: BoxShape.circle,
                ),
              )),
              const SizedBox(width: 8),
              const Text('Thinking…',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(String role, String text, String msgId) {
    final isAI = role == 'ai';
    final isSpeakingThis = _speakingMsgId == msgId && _isSpeaking;

    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.83),
        child: Column(
          crossAxisAlignment:
              isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isAI
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: isAI ? const Color(0xFF1A1F35) : null,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft:
                      isAI ? Radius.zero : const Radius.circular(20),
                  bottomRight:
                      !isAI ? Radius.zero : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isAI
                        ? Colors.transparent
                        : const Color(0xFF6C63FF).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAI)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.bot,
                              color: Color(0xFF6C63FF), size: 12),
                          const SizedBox(width: 4),
                          const Text('RetailIQ',
                              style: TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  _buildFormattedText(text, isAI),
                ],
              ),
            ),
            if (isAI)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: GestureDetector(
                  onTap: () => _speak(text, msgId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSpeakingThis
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSpeakingThis
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSpeakingThis
                              ? LucideIcons.volumeX
                              : LucideIcons.volume2,
                          size: 12,
                          color: isSpeakingThis
                              ? const Color(0xFF10B981)
                              : Colors.white30,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSpeakingThis ? 'Stop' : 'Listen',
                          style: TextStyle(
                              color: isSpeakingThis
                                  ? const Color(0xFF10B981)
                                  : Colors.white30,
                              fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isAI) {
    final spans = <TextSpan>[];
    final parts = text.split(RegExp(r'\*\*'));
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          color: isAI ? Colors.white.withValues(alpha: 0.88) : Colors.white,
          fontSize: 13.5,
          fontWeight: i % 2 == 0 ? FontWeight.normal : FontWeight.bold,
          height: 1.5,
        ),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildChatInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1323),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F35),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask about stock, sales, business advice…',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isListening ? Colors.redAccent.withOpacity(0.15) : const Color(0xFF1A1F35),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isListening ? Colors.redAccent : const Color(0xFF6C63FF).withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                _isListening ? LucideIcons.mic : LucideIcons.micOff,
                color: _isListening ? Colors.redAccent : Colors.white30,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

