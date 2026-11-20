import 'package:avara_astrology_trial/services/fact_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/widgets/creative_graphics.dart';
import 'package:avara_astrology_trial/widgets/fact_popup.dart';
import 'package:flutter/material.dart';

/// Data model for an Explore Topic bubble.
class TopicBubbleItem {
  const TopicBubbleItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bgGradient,
    required this.vedicPrinciple,
    required this.scientificFact,
    required this.dailySelfHelpActions,
    required this.affirmation,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<Color> bgGradient;
  final String vedicPrinciple;
  final String scientificFact;
  final List<String> dailySelfHelpActions;
  final String affirmation;
}

/// Dedicated Explore Topics screen with interactive bubbles for Love, Education, Career, etc.
/// Pure self-help and wisdom guidance — NO CHATBOT.
class ExploreTopicsScreen extends StatefulWidget {
  const ExploreTopicsScreen({super.key});

  @override
  State<ExploreTopicsScreen> createState() => _ExploreTopicsScreenState();
}

class _ExploreTopicsScreenState extends State<ExploreTopicsScreen> {
  static const List<TopicBubbleItem> topics = [
    TopicBubbleItem(
      id: 'love',
      title: 'Love & Relationships',
      subtitle: 'Harmony, emotional compatibility & heart chakra',
      icon: Icons.favorite_rounded,
      accentColor: Color(0xFFE84393),
      bgGradient: [Color(0xFFFD79A8), Color(0xFFE84393)],
      vedicPrinciple:
          'In Vedic wisdom, Venus (Shukra) rules harmony, mutual respect, and unconditional empathy. Relationships are viewed as mutual mirrors for spiritual and personal growth.',
      scientificFact:
          'Psychology research confirms that high emotional intelligence (EQ) and active listening release oxytocin, lowering relationship cortisol levels by 42%.',
      dailySelfHelpActions: [
        'Practice non-judgmental listening: Let your loved ones speak without interrupting.',
        'Express 1 specific appreciation out loud every morning.',
        'Apply the 5:1 ratio: Provide 5 positive interactions for every 1 constructive feedback.',
      ],
      affirmation: 'I bring patience, understanding, and warm empathy to every relationship in my life.',
    ),
    TopicBubbleItem(
      id: 'education',
      title: 'Education & Learning',
      subtitle: 'Exam calm, laser focus, memory & Mercury intellect',
      icon: Icons.school_rounded,
      accentColor: Color(0xFF0984E3),
      bgGradient: [Color(0xFF74B9FF), Color(0xFF0984E3)],
      vedicPrinciple:
          'Mercury (Budha) and Goddess Saraswati represent deep intellect (Buddhi) and discernment (Viveka). True learning harmonizes memory with calm mental absorption.',
      scientificFact:
          'Cognitive neuroscience reveals that 25-minute focused sprints (Pomodoro) followed by 5-minute visual resting periods accelerate synaptic consolidation in the hippocampus.',
      dailySelfHelpActions: [
        'Study in 25-minute distraction-free blocks with your phone outside the room.',
        'Review difficult concepts within 24 hours to defeat the Ebbinghaus forgetting curve.',
        'Take 5 deep abdominal breaths before exams to transition brainwaves to alpha state.',
      ],
      affirmation: 'My mind is clear, focused, and absorbs knowledge with effortless retention.',
    ),
    TopicBubbleItem(
      id: 'career',
      title: 'Career & Growth',
      subtitle: 'Right livelihood, 10th house purpose, leadership & grit',
      icon: Icons.rocket_launch_rounded,
      accentColor: Color(0xFF6C5CE7),
      bgGradient: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
      vedicPrinciple:
          'The 10th house (Karma Bhava) in Vedic astrology represents your duty (Dharma) to society. When your daily work serves others with integrity, career prosperity naturally follows.',
      scientificFact:
          'High performers are defined by "Grit" (Angela Duckworth, Penn University) — sustained passion and perseverance over long periods, beating raw IQ by 3.5x.',
      dailySelfHelpActions: [
        'Identify your single most important high-leverage task each morning and finish it first.',
        'Build a "Wins & Learnings" journal to track weekly milestones.',
        'Seek feedback proactively from peers and mentors to sharpen your professional craft.',
      ],
      affirmation: 'I act with purpose, diligence, and integrity, building lasting career excellence.',
    ),
    TopicBubbleItem(
      id: 'health',
      title: 'Health & Vitality',
      subtitle: 'Ayurvedic dosha balance, energy & restorative wellness',
      icon: Icons.spa_rounded,
      accentColor: Color(0xFF00B894),
      bgGradient: [Color(0xFF55EFC4), Color(0xFF00B894)],
      vedicPrinciple:
          'Ayurveda teaches that health (Swastha) is established when digestion (Agni) is strong, tissues are nourished, and the mind is serene.',
      scientificFact:
          'Over 90% of the body’s serotonin (the happy neurotransmitter) is produced in the gut microbiome, meaning mindful eating directly dictates emotional mood.',
      dailySelfHelpActions: [
        'Eat your meals seated, without digital screens, chewing thoroughly.',
        'Drink a glass of warm water upon waking to activate internal organ peristalsis.',
        'Aim for 15 minutes of natural morning sunlight to set your circadian clock.',
      ],
      affirmation: 'My body is healthy, energized, and vibrant with natural balance.',
    ),
    TopicBubbleItem(
      id: 'wealth',
      title: 'Mindful Wealth & Abundance',
      subtitle: 'Financial discipline, Lakshmi principles & mindful savings',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: Color(0xFFE17055),
      bgGradient: [Color(0xFFFAB1A0), Color(0xFFE17055)],
      vedicPrinciple:
          'Lakshmi symbolizes auspicious, clean wealth. Vedic tradition teaches that financial prosperity stays where there is order, gratitude, and purposeful planning.',
      scientificFact:
          'Behavioral economics shows that automated savings (paying yourself first) increases annual wealth accumulation by 310% compared to saving whatever is left over.',
      dailySelfHelpActions: [
        'Follow the 24-hour pause rule before any impulsive online purchase.',
        'Track every single rupee spent daily using AVARA’s voice finance logger.',
        'Automate 15% of your income into long-term savings on payday.',
      ],
      affirmation: 'I manage my finances with wisdom, gratitude, and disciplined abundance.',
    ),
    TopicBubbleItem(
      id: 'peace',
      title: 'Inner Peace & Grounding',
      subtitle: 'Mental equilibrium, meditation & emotional freedom',
      icon: Icons.self_improvement_rounded,
      accentColor: Color(0xFF00CEC9),
      bgGradient: [Color(0xFF81ECEC), Color(0xFF00CEC9)],
      vedicPrinciple:
          'Patanjali declares "Yoga is the stilling of the fluctuations of the mind". Inner peace is not the absence of storms, but the anchor within them.',
      scientificFact:
          'Daily 10-minute mindfulness practice physically shrinks the amygdala (fear center) and thickens the prefrontal cortex within 8 weeks.',
      dailySelfHelpActions: [
        'Start your day with 5 minutes of mindful silence before checking your phone.',
        'Do a 3-minute body scan when feeling rushed or stressed during the day.',
        'Write down 3 things you are deeply thankful for before going to bed.',
      ],
      affirmation: 'I am rooted in quiet strength, deep calm, and unwavering inner peace.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Explore Self-Help Pillars', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.blue),
            tooltip: 'Scientific Facts',
            onPressed: () => FactPopup.show(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Motivational header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pillars of Holistic Life',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap any bubble below to explore self-help remedies, behavioral science, and practical habits.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.bubble_chart_rounded, color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Interactive Topic Bubbles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 14),

            // Grid of interactive topic bubbles
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return _buildTopicBubble(topic);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicBubble(TopicBubbleItem topic) {
    return GestureDetector(
      onTap: () => _openTopicDetail(topic),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: topic.accentColor.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: topic.accentColor.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // Decorative background glowing watermarked sphere
            Positioned(
              right: -14,
              top: -14,
              child: SizedBox(
                width: 72,
                height: 72,
                child: CustomPaint(
                  painter: Spherical3DBubblePainter(
                    accentColor: topic.accentColor,
                    bgGradient: topic.bgGradient,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: topic.bgGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: topic.accentColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(topic.icon, color: Colors.white, size: 22),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: topic.accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: topic.accentColor),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      topic.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.secondaryText,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openTopicDetail(TopicBubbleItem topic) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _TopicDetailScreen(topic: topic),
      ),
    );
  }
}

class _TopicDetailScreen extends StatelessWidget {
  const _TopicDetailScreen({required this.topic});

  final TopicBubbleItem topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(topic.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_rounded, color: AppColors.blue),
            tooltip: 'Scientific Fact',
            onPressed: () => FactPopup.show(context, category: topic.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero card with Affirmation
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: topic.bgGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: topic.accentColor.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(topic.icon, size: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    topic.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '“${topic.affirmation}”',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Ancient Wisdom Card
            _detailCard(
              title: 'ANCIENT VEDIC WISDOM',
              content: topic.vedicPrinciple,
              icon: Icons.auto_awesome,
              accentColor: const Color(0xFF6C5CE7),
            ),
            const SizedBox(height: 14),

            // Modern Science Card
            _detailCard(
              title: 'MODERN PSYCHOLOGY & SCIENCE',
              content: topic.scientificFact,
              icon: Icons.science_rounded,
              accentColor: const Color(0xFF00B894),
            ),
            const SizedBox(height: 20),

            // Actionable Daily Steps
            const Text(
              'Daily Self-Help Action Blueprint',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 12),
            ...topic.dailySelfHelpActions.map((action) => _actionStepTile(action)),
            const SizedBox(height: 24),

            // Fact Pop-up Button
            OutlinedButton.icon(
              onPressed: () => FactPopup.show(context, category: topic.id),
              icon: const Icon(Icons.lightbulb_rounded, color: AppColors.blue),
              label: const Text('Read Verified Scientific Fact on this Pillar'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.blue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailCard({
    required String title,
    required String content,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.deepNavy,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionStepTile(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF00B894), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.deepNavy,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
