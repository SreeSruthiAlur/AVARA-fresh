import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Explanatory model for astrological & self-help terms in common people's language.
class GlossaryTerm {
  const GlossaryTerm({
    required this.term,
    required this.teluguTerm,
    required this.tanglishTerm,
    required this.simpleEnglishExplanation,
    required this.simpleTeluguExplanation,
    required this.simpleTanglishExplanation,
    required this.everydayAnalogy,
    required this.category,
    this.icon = Icons.help_outline_rounded,
  });

  final String term;
  final String teluguTerm;
  final String tanglishTerm;
  final String simpleEnglishExplanation;
  final String simpleTeluguExplanation;
  final String simpleTanglishExplanation;
  final String everydayAnalogy;
  final String category;
  final IconData icon;
}

/// Comprehensive tap-to-explain glossary providing crystal-clear explanations
/// for common people without technical jargon.
class KeywordGlossaryModal {
  static const List<GlossaryTerm> terms = [
    GlossaryTerm(
      term: 'Lagna',
      teluguTerm: 'లగ్నం (Lagnam)',
      tanglishTerm: 'Lagnam',
      simpleEnglishExplanation:
          'Your Ascendant or Rising Sign. It represents the exact zodiac constellation rising on the eastern horizon the minute you were born. It shapes your physical vitality, personality mask, and the lens through which you see the world.',
      simpleTeluguExplanation:
          'మీరు జన్మించిన సమయంలో తూర్పు దిక్కున ఉదయించే రాశిని లగ్నం అంటారు. ఇది మీ శరీర శక్తిని, వ్యక్తిత్వాన్ని మరియు సమాజం మిమ్మల్ని ఎలా చూస్తుందో తెలియజేస్తుంది.',
      simpleTanglishExplanation:
          'Meeru puttina time lo east side unna raasi ni Lagnam antaru. Idi mee personality, physical health and society mimmalni ela chusthundi anedi chepthru.',
      everydayAnalogy:
          'Think of the Sun sign as your inner engine, and your Lagna as the steering wheel and outer design of your car.',
      category: 'Chart Basics',
      icon: Icons.wb_sunny_outlined,
    ),
    GlossaryTerm(
      term: 'Nakshatra',
      teluguTerm: 'నక్షత్రం (Nakshatram)',
      tanglishTerm: 'Nakshatram',
      simpleEnglishExplanation:
          'Your Birth Star. In Vedic wisdom, the zodiac is divided into 27 lunar constellations. Your Janma Nakshatra reveals your subconscious thinking patterns, innate habits, and natural emotional gifts.',
      simpleTeluguExplanation:
          'వేద జ్యోతిషంలో రాశిచక్రాన్ని 27 నక్షత్రాలుగా విభజించారు. మీ జన్మ నక్షత్రం మీ సహజ ప్రవర్తనను, ఆలోచనా విధానాన్ని మరియు అంతర్గత అలవాట్లను ప్రతిబింబిస్తుంది.',
      simpleTanglishExplanation:
          'Vedic astrology lo 27 Nakshatralu untayi. Mee Janma Nakshatram mee nature, subconscious habits and mental instincts ni explain chesthundi.',
      everydayAnalogy:
          'Like your psychological DNA or default factory settings that guide how your mind reacts under pressure.',
      category: 'Mind & Nature',
      icon: Icons.auto_awesome,
    ),
    GlossaryTerm(
      term: 'Moon Sign',
      teluguTerm: 'చంద్ర రాశి (Rasi)',
      tanglishTerm: 'Chandra Rasi',
      simpleEnglishExplanation:
          'The zodiac sign where the Moon was positioned at your birth. While Western astrology emphasizes the Sun, Vedic wisdom centers on the Moon Sign because it directly governs your mind, emotions, peace, and intuition.',
      simpleTeluguExplanation:
          'మీరు పుట్టినప్పుడు చంద్రుడు ఉన్న రాశి. వేద జ్యోతిషంలో మనస్సు, ఆలోచనలు మరియు భావోద్వేగాలకు చంద్ర రాశి అత్యంత ప్రధానమైనది.',
      simpleTanglishExplanation:
          'Puttinappudu Moon unna sign. Manasuku, emotions ki and mental peace ki idi chaala mukhyam.',
      everydayAnalogy:
          'Your emotional weather report — how you process joy, sorrow, stress, and empathy.',
      category: 'Chart Basics',
      icon: Icons.nightlight_round,
    ),
    GlossaryTerm(
      term: 'Mahadasha',
      teluguTerm: 'మహాదశ (Life Period)',
      tanglishTerm: 'Mahadasha Period',
      simpleEnglishExplanation:
          'A major multi-year chapter of your life ruled by a specific planet (e.g. Jupiter, Saturn, Mercury). During this period, that planet’s themes take center stage in your career, relationships, or personal growth.',
      simpleTeluguExplanation:
          'మీ జీవితంలో ఒక నిర్దిష్ట గ్రహం పాలించే ముఖ్యమైన కాలం (ఉదాహరణకు గురు దశ, శని దశ). ఆ సమయంలో ఆ గ్రహానికి సంబంధించిన విషయాలు మీ జీవితాన్ని ప్రభావితం చేస్తాయి.',
      simpleTanglishExplanation:
          'Mee life lo oka planet rule chese main chapter. Aa time lo aa planet themes (career, health, studies) meeda main focus untundi.',
      everydayAnalogy:
          'Like seasons of life: winter demands patience, spring brings growth, and harvest rewards past efforts.',
      category: 'Life Timing',
      icon: Icons.hourglass_top_rounded,
    ),
    GlossaryTerm(
      term: 'Kendra',
      teluguTerm: 'కేంద్ర స్థానాలు (Pillars)',
      tanglishTerm: 'Kendra Houses',
      simpleEnglishExplanation:
          'The 4 main pillar houses in your birth chart (1st, 4th, 7th, and 10th houses). They represent the 4 pillars of human life: Self & Vitality (1st), Home & Happiness (4th), Partnership & Marriage (7th), and Career & Duty (10th).',
      simpleTeluguExplanation:
          'జాతక చక్రంలోని 1, 4, 7, 10 స్థానాలను కేంద్రాలు అంటారు. ఇవి జీవితపు నాలుగు ముఖ్య స్తంభాలు: వ్యక్తిత్వం, గృహ సుఖం, వివాహం/భాగస్వామ్యం, మరియు వృత్తి.',
      simpleTanglishExplanation:
          'Chart lo 1st, 4th, 7th, 10th houses. Self, Home happiness, Marriage/Relationships, and Career - ee 4 pillars ni Kendra antaru.',
      everydayAnalogy:
          'The 4 corner pillars supporting a building. When planets sit here, they give strength and stability to your life.',
      category: 'Chart Basics',
      icon: Icons.foundation_rounded,
    ),
    GlossaryTerm(
      term: 'Saturn / Shani',
      teluguTerm: 'శని భగవానుడు (Discipline Teacher)',
      tanglishTerm: 'Shani Planet',
      simpleEnglishExplanation:
          'Often misunderstood as harsh, Saturn in self-help Vedic astrology is actually the great master of discipline, patience, resilience, and genuine hard work. It rewards honest effort and weeds out illusions.',
      simpleTeluguExplanation:
          'శని క్రమశిక్షణ, సహనం మరియు నిరంతర శ్రమకు ప్రతీక. నిజాయితీగా శ్రమించే వారికి దీర్ఘకాలిక విజయాన్ని మరియు స్థిరత్వాన్ని ప్రసాదిస్తుంది.',
      simpleTanglishExplanation:
          'Shani ante hard work, discipline and patience. Shortcuts lekunda kashtapade variki great permanent success isthundi.',
      everydayAnalogy:
          'Like a strict personal fitness trainer: doesn’t let you cheat on pushups, but guarantees you build unbreakable muscle.',
      category: 'Planetary Energies',
      icon: Icons.shield_rounded,
    ),
    GlossaryTerm(
      term: 'Jupiter / Guru',
      teluguTerm: 'గురుడు / బృహస్పతి (Wisdom & Grace)',
      tanglishTerm: 'Guru Planet',
      simpleEnglishExplanation:
          'The planet of wisdom, higher learning, expansion, ethical values, and good fortune. Represents guidance from mentors and inner moral compass.',
      simpleTeluguExplanation:
          'జ్ఞానం, ఉన్నత చదువు, సద్గుణాలు మరియు అదృష్టాన్ని అందించే దైవిక గ్రహం. అంతర్గత వివేకాన్ని మరియు సన్మార్గాన్ని సూచిస్తుంది.',
      simpleTanglishExplanation:
          'Wisdom, education, moral values and good luck ki karakudu. Life lo right decisions theesukovadaniki guide chesthundi.',
      everydayAnalogy:
          'A wise, compassionate professor who illuminates your path and opens doors to new opportunities.',
      category: 'Planetary Energies',
      icon: Icons.school_rounded,
    ),
  ];

  /// Opens a dedicated explanation card for a specific tapped keyword.
  static void showTerm(BuildContext context, String query) {
    final lower = query.toLowerCase();
    final match = terms.firstWhere(
      (t) =>
          t.term.toLowerCase().contains(lower) ||
          lower.contains(t.term.toLowerCase()) ||
          t.teluguTerm.contains(query) ||
          t.tanglishTerm.toLowerCase().contains(lower),
      orElse: () => terms.first,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GlossaryCardSheet(term: match),
    );
  }

  /// Opens the full searchable glossary of common terms.
  static void showFullGlossary(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FullGlossarySheet(),
    );
  }
}

class _GlossaryCardSheet extends StatelessWidget {
  const _GlossaryCardSheet({required this.term});

  final GlossaryTerm term;

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguageService.instance.currentLanguage;

    String explanation;
    switch (lang) {
      case AppLanguage.telugu:
        explanation = term.simpleTeluguExplanation;
        break;
      case AppLanguage.tanglish:
        explanation = term.simpleTanglishExplanation;
        break;
      case AppLanguage.malayalam:
      case AppLanguage.manglish:
      case AppLanguage.english:
        explanation = term.simpleEnglishExplanation;
        break;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(term.icon, color: AppColors.blue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      term.term,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    Text(
                      '${term.teluguTerm} • ${term.category}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.secondaryText),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Everyday Explanation
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Simple Explanation for Everyone:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  explanation,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.deepNavy,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Everyday Life Analogy
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF57F17), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Everyday Analogy:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF57F17),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        term.everydayAnalogy,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.deepNavy,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Understand! Back to Chat', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _FullGlossarySheet extends StatefulWidget {
  const _FullGlossarySheet();

  @override
  State<_FullGlossarySheet> createState() => _FullGlossarySheetState();
}

class _FullGlossarySheetState extends State<_FullGlossarySheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filtered = KeywordGlossaryModal.terms.where((t) {
      if (_filter.isEmpty) return true;
      final q = _filter.toLowerCase();
      return t.term.toLowerCase().contains(q) ||
          t.teluguTerm.contains(q) ||
          t.tanglishTerm.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: AppColors.blue, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Everyday Vedic Terms Glossary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepNavy,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search any word (e.g. Lagna, Shani, Kendra)...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) => setState(() => _filter = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final term = filtered[index];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  tileColor: AppColors.background,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.blue.withValues(alpha: 0.1),
                    child: Icon(term.icon, color: AppColors.blue, size: 20),
                  ),
                  title: Text(term.term, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${term.teluguTerm} • ${term.category}', style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText),
                  onTap: () {
                    Navigator.of(context).pop();
                    KeywordGlossaryModal.showTerm(context, term.term);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
