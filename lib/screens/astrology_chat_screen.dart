import 'dart:math' as math;
import 'dart:typed_data';

import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/services/ai_astrology_service.dart';
import 'package:avara_astrology_trial/telugu_kundali.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sweph/sweph.dart' show AssetLoader;

// ---------------------------------------------------------------------------
// Data model for a single message in the thread
// ---------------------------------------------------------------------------

enum _MessageSender { user, ai }

class _ChatMessage {
  _ChatMessage({
    required this.text,
    required this.sender,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String text;
  final _MessageSender sender;
  final DateTime timestamp;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// AVARA's chat-first Jyotisha interface.
///
/// **Chat-first** (standalone): Launch with no [chartJson]. AVARA will ask for
/// birth details when needed and compute the chart automatically via Gemini
/// function calling + the local sweph math engine.
///
/// **Chart-first** (from Birth Profile): Pass [chartJson]. AVARA silently
/// pre-loads it and answers personal questions immediately.
class AstrologyChatScreen extends StatefulWidget {
  const AstrologyChatScreen({
    super.key,
    this.chartJson, // now optional — null means chat-first mode
    this.apiKey = '',
  });

  /// Optional pre-computed kundali from the Birth Profile screen.
  /// When null, AVARA requests birth details conversationally.
  final Map<String, dynamic>? chartJson;

  /// Google AI Studio API key. Pass this securely from your app config.
  final String apiKey;

  @override
  State<AstrologyChatScreen> createState() => _AstrologyChatScreenState();
}

class _AstrologyChatScreenState extends State<AstrologyChatScreen>
    with TickerProviderStateMixin {
  // Service & state
  late final AIAstrologyService _service;
  final List<_ChatMessage> _messages = [];
  bool _isThinking = false;
  String? _errorMessage;

  // Input controller
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  // Suggestion chips shown before the first message
  static const List<String> _suggestions = [
    'What does my Moon sign say about my emotions?',
    'Describe my Lagna and its effect on my personality.',
    'Which planets are in kendras in my chart?',
    'What career path suits my Janma Nakshatra?',
  ];

  @override
  void initState() {
    super.initState();
    _service = AIAstrologyService(
      apiKey: widget.apiKey,
      chartGenerator: _generateChart, // inject the sweph engine callback
    );

    // If a chart was passed (chart-first mode), pre-load it so AVARA can
    // answer personal questions immediately without asking for birth details.
    if (widget.chartJson != null) {
      _service.preloadChart(widget.chartJson!);
    }

    // Dynamic greeting based on whether a chart is already available.
    final greeting = widget.chartJson != null
        ? 'Namaste 🙏  I am AVARA, your Jyotisha Intelligence engine.\n\n'
          'Your Janma Kundali has been loaded. Ask me anything — '
          'planetary positions, Nakshatra qualities, Dasha periods, or life guidance.'
        : 'Namaste 🙏  I am AVARA, your Vedic Astrology guide.\n\n'
          'Ask me any astrology question directly. For a personalised reading, '
          'just share your Date, Time, and City of birth.';
    _messages.add(_ChatMessage(text: greeting, sender: _MessageSender.ai));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Core send logic
  // ---------------------------------------------------------------------------

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isThinking) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, sender: _MessageSender.user));
      _isThinking = true;
      _errorMessage = null;
    });
    _scrollToBottom();

    try {
      // sendMessage() handles pre-loaded chart injection and the full
      // function-calling loop (geocoding → sweph → model response) internally.
      final response = await _service.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: response, sender: _MessageSender.ai));
        _isThinking = false;
      });
    } on AIAstrologyException catch (e) {
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _errorMessage = 'Unexpected error: $e';
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// Platform implementation of [ChartGeneratorCallback].
  ///
  /// Called by [AIAstrologyService] after it geocodes the birth city.
  /// Runs [TeluguKundaliCalculator] with the bundled Swiss Ephemeris assets
  /// and returns the full kundali map.
  Future<Map<String, dynamic>> _generateChart({
    required int year,
    required int month,
    required int day,
    required double hourUtc,
    required double lat,
    required double lon,
  }) {
    final calculator = TeluguKundaliCalculator(
      ayanamsa: 1, // Lahiri — matches Birth Profile screen default
      epheAssets: _kChatEpheAssets,
      assetLoader: _ChatBundleAssetLoader(),
      epheFilesPath: 'ephe_files',
    );
    return calculator.calculateFullKundali(
      year, month, day, hourUtc, lat, lon,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_errorMessage != null) _buildErrorBanner(),
          _buildInputRow(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.deepNavy,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          const _AvaraOrb(size: 36),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AVARA Jyotisha',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Powered by Gemini • Vedic Astrology',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: AppColors.deepNavy.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    final showSuggestions =
        _messages.length == 1 && !_isThinking; // only greeting visible

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length +
          (showSuggestions ? 1 : 0) +
          (_isThinking ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator at the end when AI is thinking
        if (_isThinking &&
            index == _messages.length + (showSuggestions ? 1 : 0)) {
          return const _TypingIndicatorBubble();
        }
        // Suggestion chips just after the greeting
        if (showSuggestions && index == 1) {
          return _buildSuggestionChips();
        }
        final msgIndex =
            (showSuggestions && index >= 1) ? index - 1 : index;
        return _buildMessageBubble(_messages[msgIndex]);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.sender == _MessageSender.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _AvaraOrb(size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF2E71DB), Color(0xFF1A4FAF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF141B3B), Color(0xFF0E1530)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: AppColors.blue.withValues(alpha: 0.3),
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? AppColors.blue : AppColors.deepNavy)
                        .withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        'AVARA Jyotisha',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue.withValues(alpha: 0.8),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.92),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.blue.withValues(alpha: 0.25),
              child:
                  const Icon(Icons.person, size: 16, color: AppColors.blue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 36),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions
            .map(
              (s) => GestureDetector(
                onTap: () {
                  _inputController.text = s;
                  _inputFocusNode.requestFocus();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.deepNavy.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.blue.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1212),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: const TextStyle(color: Color(0xFFFF9090), fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child:
                const Icon(Icons.close, color: Color(0xFFFF6B6B), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  enabled: !_isThinking,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(
                    color: AppColors.deepNavy,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask about your chart…',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(
              isThinking: _isThinking,
              onTap: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ---------------------------------------------------------------------------
// Ephemeris assets & loader (mirrors birth_profile_screen.dart setup)
// ---------------------------------------------------------------------------

/// Bundled Swiss Ephemeris assets required by [TeluguKundaliCalculator].
const List<String> _kChatEpheAssets = [
  'packages/sweph/assets/ephe/sepl_18.se1',
  'packages/sweph/assets/ephe/semo_18.se1',
  'packages/sweph/assets/ephe/seas_18.se1',
  'packages/sweph/assets/ephe/sefstars.txt',
  'packages/sweph/assets/ephe/seleapsec.txt',
  'packages/sweph/assets/ephe/seasnam.txt',
  'packages/sweph/assets/ephe/seorbel.txt',
];

/// Loads ephemeris assets via Flutter's [rootBundle] for the sweph plugin.
class _ChatBundleAssetLoader implements AssetLoader {
  @override
  Future<Uint8List> load(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    return byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// Animated AVARA "orb" avatar used in the AppBar and AI bubbles.
class _AvaraOrb extends StatefulWidget {
  const _AvaraOrb({required this.size});
  final double size;

  @override
  State<_AvaraOrb> createState() => _AvaraOrbState();
}

class _AvaraOrbState extends State<_AvaraOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Color.lerp(
                  const Color(0xFF2E71DB),
                  const Color(0xFF7B3FE4),
                  _ctrl.value,
                )!,
                const Color(0xFF080B1A),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(
                  const Color(0xFF2E71DB),
                  const Color(0xFF7B3FE4),
                  _ctrl.value,
                )!
                    .withValues(alpha: 0.5),
                blurRadius: widget.size * 0.6,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.auto_awesome,
              size: widget.size * 0.5,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

/// Animated three-dot typing indicator shown while Gemini is responding.
class _TypingIndicatorBubble extends StatefulWidget {
  const _TypingIndicatorBubble();

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _AvaraOrb(size: 28),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF141B3B),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: AppColors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final offset =
                        math.sin(_ctrl.value * 2 * math.pi + i * 1.2);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.blue.withValues(
                          alpha: (0.4 + offset * 0.6).clamp(0.0, 1.0),
                        ),
                      ),
                      transform:
                          Matrix4.translationValues(0, -offset * 4, 0),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Send button with a loading spinner overlay.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.isThinking, required this.onTap});
  final bool isThinking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isThinking ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isThinking
              ? const LinearGradient(
                  colors: [Color(0xFF1E2A52), Color(0xFF1E2A52)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF2E71DB), Color(0xFF7B3FE4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: isThinking
              ? []
              : [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Center(
          child: isThinking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.blue,
                  ),
                )
              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
