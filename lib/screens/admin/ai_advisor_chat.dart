import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/ai_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
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
  late AnimationController _typingController;
  late Animation<double> _typingAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  late stt.SpeechToText _speech;
  bool _isListening = false;

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

    _speech = stt.SpeechToText();
    _initTts();
    _loadInitialInsights();
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
    _speech.stop();
    _typingController.dispose();
    _pulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      // 1. Explicitly ask for mic permission first
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }

      if (status.isGranted) {
        // 2. Initialize and start listening
        bool available = await _speech.initialize(
          onStatus: (val) {
            if (val == 'done' || val == 'notListening') {
              if (mounted) setState(() => _isListening = false);
            }
          },
          onError: (val) {
            if (mounted) setState(() => _isListening = false);
          },
        );
        if (available) {
          if (mounted) setState(() => _isListening = true);
          _speech.listen(
            onResult: (val) {
              if (mounted) {
                setState(() {
                  _controller.text = val.recognizedWords;
                });
              }
            },
          );
        }
      } else {
        // User denied permission
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required to use voice input.')),
          );
        }
      }
    } else {
      if (mounted) setState(() => _isListening = false);
      _speech.stop();
      if (_controller.text.trim().isNotEmpty) {
        _sendMessage();
      }
    }
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
        "\nLet me walk you through today's key insights... 👇";

    setState(() {
      _messages.add({'role': 'ai', 'id': 'msg_0', 'text': welcomeMsg});
      _isLoading = true;
    });
    _scrollToBottom();

    // --- Insight 1: Low Stock Alert ---
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (lowStockCount > 0) {
      final lowProducts = state.lowStockProducts
          .take(3)
          .map((p) => "${p.emoji} **${p.name}** — only ${p.stock} left")
          .join('\n');
      setState(() {
        _messages.add({
          'role': 'ai',
          'id': 'msg_stock',
          'text': '🚨 **Urgent Restock Alert!**\n\n$lowProducts\n\nShould I draft purchase orders for these items?',
        });
        _isLoading = true;
      });
      _scrollToBottom();
    }

    // --- Insight 2: Revenue & Sales Summary ---
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final avgBill = bills > 0 ? (revenue / bills).toInt() : 0;
    final revenueMsg = revenue > 0
        ? '💰 **Today\'s Sales Summary**\n\n'
          '• Total Revenue: **${state.currency}${revenue.toInt()}**\n'
          '• Bills Completed: **$bills**\n'
          '• Avg Bill Value: **${state.currency}$avgBill**\n\n'
          '${avgBill >= 500 ? "🎯 Great job! Avg bill is above ₹500 target." : "📈 Tip: Upsell combos to push avg bill above ₹500."}'
        : '💡 **No sales recorded yet today.**\n\nMake your first sale — the dashboard updates instantly after every checkout!';
    setState(() {
      _messages.add({'role': 'ai', 'id': 'msg_revenue', 'text': revenueMsg});
      _isLoading = true;
    });
    _scrollToBottom();

    // --- Insight 3: Expiry Alert ---
    final expiringProducts = state.inventory.where((p) {
      if (p.expires == null || p.expires!.isEmpty) return false;
      final date = DateTime.tryParse(p.expires!);
      if (date == null) return false;
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final expDay = DateTime(date.year, date.month, date.day);
      return expDay.difference(today).inDays <= 3;
    }).toList();

    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (expiringProducts.isNotEmpty) {
      final expList = expiringProducts.take(3).map((p) {
        final date = DateTime.tryParse(p.expires!)!;
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final days = DateTime(date.year, date.month, date.day).difference(today).inDays;
        final label = days < 0 ? '🔴 EXPIRED' : days == 0 ? '🔴 TODAY' : days == 1 ? '🟠 TOMORROW' : '🟡 $days days left';
        return "${p.emoji} **${p.name}** — $label";
      }).join('\n');
      setState(() {
        _messages.add({
          'role': 'ai',
          'id': 'msg_expiry',
          'text': '⚠️ **Expiry Alert!**\n\n$expList\n\nConsider a quick discount to clear these before they expire.',
        });
        _isLoading = true;
      });
      _scrollToBottom();
    }

    // --- Insight 4: Top Sellers ---
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final leaderboard = state.getLeaderboard();
    final topMsg = leaderboard.isNotEmpty
        ? '🏆 **Today\'s Top Sellers**\n\n'
          '${leaderboard.take(3).map((e) => "${e['emoji']} **${e['name']}** — ${e['sold']} units sold").join('\n')}\n\n'
          'These are flying off shelves — make sure stock is ready!'
        : '📊 **No top sellers yet today.**\n\nCheck back after a few sales — I\'ll rank your best performers here!';
    setState(() {
      _messages.add({'role': 'ai', 'id': 'msg_top', 'text': topMsg});
      _isLoading = false;
    });
    _scrollToBottom();
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
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
    final msgId = 'msg_${_messages.length}';

    setState(() {
      _messages.add({'role': 'user', 'id': msgId, 'text': query});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final enrichedQuery = '''
Store: ${state.storeName}
Revenue Today: ${state.currency}${state.todayRevenue.toInt()}
Bills Today: ${state.todayBillsCount}
Low Stock: ${state.lowStockCount} items
User asked: $query
    ''';

    final history = _messages.toList(); // Simplified history as AIService handles take()

    final answer = await AIService.getAIAdvice(
        query, state.storeName, state.inventory, state.sales, lang, history, state.githubToken);

    if (mounted) {
      final aiMsgId = 'msg_${_messages.length}';
      setState(() {
        _messages.add({'role': 'ai', 'id': aiMsgId, 'text': answer});
        _isLoading = false;
      });
      _scrollToBottom();
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
                decoration: InputDecoration(
                  hintText: _isListening ? 'Listening...' : 'Ask about stock, sales, business advice…',
                  hintStyle: TextStyle(
                    color: _isListening ? Colors.redAccent.withValues(alpha: 0.8) : Colors.white24, 
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _listen,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isListening ? Colors.redAccent.withValues(alpha: 0.2) : const Color(0xFF1E293B),
                border: Border.all(color: _isListening ? Colors.redAccent : Colors.white12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                _isListening ? LucideIcons.mic : LucideIcons.micOff, 
                color: _isListening ? Colors.redAccent : Colors.white60, 
                size: 18
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
               if (_isListening) {
                 _speech.stop();
                 setState(() => _isListening = false);
               }
               _sendMessage();
            },
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
        ],
      ),
    );
  }
}
