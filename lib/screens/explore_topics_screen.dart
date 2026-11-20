import 'package:avara_astrology_trial/services/age_profile_service.dart';
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
  List<TopicBubbleItem> get topics {
    final group = AgeProfileService.instance.ageGroup;
    switch (group) {
      case AgeGroup.youth:
        return const [
          TopicBubbleItem(
            id: 'education',
            title: 'Exams & Study Mastery',
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
            title: 'Dream Careers & Passions',
            subtitle: 'Finding courses, early jobs & planetary strengths',
            icon: Icons.rocket_launch_rounded,
            accentColor: Color(0xFF6C5CE7),
            bgGradient: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
            vedicPrinciple:
                'The 10th house (Karma Bhava) in Vedic astrology represents your duty (Dharma) to society. When your daily work serves others with integrity, career prosperity naturally follows.',
            scientificFact:
                'High performers are defined by "Grit" (Penn University) — sustained passion and perseverance over long periods, beating raw IQ by 3.5x.',
            dailySelfHelpActions: [
              'Identify your natural talents and explore fields where your curiosity thrives.',
              'Build a "Wins & Learnings" journal to track weekly milestones.',
              'Seek advice from mentors to sharpen your confidence and skills.',
            ],
            affirmation: 'I act with purpose, diligence, and integrity, building an inspiring future.',
          ),
          TopicBubbleItem(
            id: 'love',
            title: 'Friendships & Social Calm',
            subtitle: 'Confidence, true friends & beating peer comparison',
            icon: Icons.people_rounded,
            accentColor: Color(0xFFE84393),
            bgGradient: [Color(0xFFFD79A8), Color(0xFFE84393)],
            vedicPrinciple:
                'In Vedic wisdom, Venus (Shukra) rules harmony, mutual respect, and empathy. Surround yourself with Sattvic friendships that uplift your spirit.',
            scientificFact:
                'Psychology research confirms that authentic peer connections release oxytocin, lowering adolescent social anxiety by 38%.',
            dailySelfHelpActions: [
              'Practice non-judgmental listening with friends.',
              'Avoid comparing your behind-the-scenes life to others\' social media highlights.',
              'Express genuine appreciation to 1 close friend today.',
            ],
            affirmation: 'I am confident, kind, and surround myself with genuine, uplifting friendships.',
          ),
          TopicBubbleItem(
            id: 'health',
            title: 'Energy & Athletic Vitality',
            subtitle: 'Beating screen fatigue, sports & natural stamina',
            icon: Icons.directions_run_rounded,
            accentColor: Color(0xFF00B894),
            bgGradient: [Color(0xFF55EFC4), Color(0xFF00B894)],
            vedicPrinciple:
                'Ayurveda teaches that physical movement (Vyayama) enhances internal fire (Agni), clearing sluggishness (Tamas).',
            scientificFact:
                'Physical exercise stimulates Brain-Derived Neurotrophic Factor (BDNF), literally growing new neurons in the memory center.',
            dailySelfHelpActions: [
              'Spend at least 30 minutes outdoors in natural sunlight and movement.',
              'Drink a tall glass of water before looking at your morning phone.',
              'Avoid screens during meals to protect metabolic digestion.',
            ],
            affirmation: 'My body is energized, strong, and bursting with vibrant health.',
          ),
          TopicBubbleItem(
            id: 'wealth',
            title: 'Smart Pocket Money & Savings',
            subtitle: 'Early financial habits & beating impulse peer spending',
            icon: Icons.savings_rounded,
            accentColor: Color(0xFFE17055),
            bgGradient: [Color(0xFFFAB1A0), Color(0xFFE17055)],
            vedicPrinciple:
                'Lakshmi principles teach that financial abundance starts with respect for resources and avoidance of wasteful cravings (Preyas).',
            scientificFact:
                'Compound interest math reveals that saving just \$50/month starting at age 19 yields 4x more wealth by age 40 than starting at age 30.',
            dailySelfHelpActions: [
              'Follow the 24-hour pause before buying trendy non-essential items.',
              'Save 20% of every gift or allowance in a dedicated piggy bank or account.',
              'Learn 1 financial concept (like compounding or index funds) this week.',
            ],
            affirmation: 'I treat money with wisdom and build disciplined abundance early.',
          ),
          TopicBubbleItem(
            id: 'peace',
            title: 'Confidence & Mental Peace',
            subtitle: 'Silencing overthinking & building quiet inner power',
            icon: Icons.self_improvement_rounded,
            accentColor: Color(0xFF00CEC9),
            bgGradient: [Color(0xFF81ECEC), Color(0xFF00CEC9)],
            vedicPrinciple:
                'Patanjali declares "Yoga is the stilling of the fluctuations of the mind". Inner peace is your natural birthright.',
            scientificFact:
                '5 minutes of slow vagus-nerve exhalations lowers amygdala threat responses, restoring executive calm instantly.',
            dailySelfHelpActions: [
              'Start your morning with 5 minutes of mindful silence before checking notifications.',
              'When feeling anxious, do 3 slow deep breaths counting 4 in, 7 hold, 8 out.',
              'Write down 3 things you love about yourself before bed.',
            ],
            affirmation: 'I am rooted in quiet confidence, clarity, and inner peace.',
          ),
        ];

      case AgeGroup.adult:
        return const [
          TopicBubbleItem(
            id: 'career',
            title: 'Career & Executive Growth',
            subtitle: 'Right livelihood, promotions, leadership & grit',
            icon: Icons.rocket_launch_rounded,
            accentColor: Color(0xFF6C5CE7),
            bgGradient: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
            vedicPrinciple:
                'The 10th house (Karma Bhava) represents societal duty. When work aligns with integrity and service, career prosperity naturally follows.',
            scientificFact:
                'High performers exhibit sustained focus and emotional resilience, beating pure technical skill by 3.5x in senior leadership.',
            dailySelfHelpActions: [
              'Identify your #1 high-leverage task each morning and finish it before noon.',
              'Build a "Wins & Learnings" journal to track quarterly milestones.',
              'Proactively seek feedback from mentors to sharpen executive leadership.',
            ],
            affirmation: 'I lead with purpose, diligence, and clarity, building lasting excellence.',
          ),
          TopicBubbleItem(
            id: 'wealth',
            title: 'Mindful Wealth & Assets',
            subtitle: 'Investment discipline, Lakshmi principles & freedom',
            icon: Icons.account_balance_wallet_rounded,
            accentColor: Color(0xFFE17055),
            bgGradient: [Color(0xFFFAB1A0), Color(0xFFE17055)],
            vedicPrinciple:
                'Lakshmi stays where there is order, gratitude, and purpose. Vedic economics honors disciplined savings (Shreyas).',
            scientificFact:
                'Automated investing ("paying yourself first") increases lifetime net worth by 310% compared to saving residual income.',
            dailySelfHelpActions: [
              'Follow the 24-hour cooling window before any major discretionary expense.',
              'Log all expenses daily using AVARA\'s voice logger.',
              'Automate 20% of your earnings into diversified investments on payday.',
            ],
            affirmation: 'I manage my finances with wisdom, gratitude, and disciplined abundance.',
          ),
          TopicBubbleItem(
            id: 'love',
            title: 'Marriage & Relationship Peace',
            subtitle: 'Mutual empathy, partner harmony & deep bonding',
            icon: Icons.favorite_rounded,
            accentColor: Color(0xFFE84393),
            bgGradient: [Color(0xFFFD79A8), Color(0xFFE84393)],
            vedicPrinciple:
                'In Vedic tradition, Venus (Shukra) and Jupiter govern marital harmony and mutual respect. Relationships are mirrors for spiritual growth.',
            scientificFact:
                'Practicing active non-defensive listening releases oxytocin and reduces partner cortisol levels by 42%.',
            dailySelfHelpActions: [
              'Practice non-judgmental listening: let your partner speak without interrupting.',
              'Express 1 specific appreciation out loud every morning.',
              'Maintain the 5:1 positive-to-critical interaction ratio.',
            ],
            affirmation: 'I bring patience, understanding, and warm empathy to my home.',
          ),
          TopicBubbleItem(
            id: 'health',
            title: 'Work-Life Vitality & Health',
            subtitle: 'Circadian rhythm, stress mitigation & stamina',
            icon: Icons.spa_rounded,
            accentColor: Color(0xFF00B894),
            bgGradient: [Color(0xFF55EFC4), Color(0xFF00B894)],
            vedicPrinciple:
                'Swastha (health) is established when digestion (Agni) is steady and the mind is serene amidst demanding life responsibilities.',
            scientificFact:
                '90% of serotonin is synthesized in the gut; mindful nutrition directly protects against corporate burnout and mood swings.',
            dailySelfHelpActions: [
              'Eat lunch away from work screens, chewing thoroughly.',
              'Take a 10-minute fresh air walk between work meetings.',
              'Establish a firm 10:30 PM digital wind-down routine.',
            ],
            affirmation: 'My body is resilient, balanced, and energized for life.',
          ),
          TopicBubbleItem(
            id: 'peace',
            title: 'Inner Peace & Grounding',
            subtitle: 'Stillness, mental equilibrium & emotional freedom',
            icon: Icons.self_improvement_rounded,
            accentColor: Color(0xFF00CEC9),
            bgGradient: [Color(0xFF81ECEC), Color(0xFF00CEC9)],
            vedicPrinciple:
                'Patanjali declares inner peace is the steady anchor within life\'s storms. Still the mind\'s turbulent waves.',
            scientificFact:
                '10 minutes of daily mindfulness practice physically shrinks the stress-reactive amygdala within 8 weeks.',
            dailySelfHelpActions: [
              'Take 5 minutes of mindful silence upon waking before touching work email.',
              'Perform a 3-minute breath decompression when transitioning from office to home.',
              'Write down 3 gratitudes every night.',
            ],
            affirmation: 'I am anchored in quiet strength, deep calm, and unwavering clarity.',
          ),
          TopicBubbleItem(
            id: 'education',
            title: 'Continuous Wisdom & Skills',
            subtitle: 'Strategic learning, mental sharpness & innovation',
            icon: Icons.school_rounded,
            accentColor: Color(0xFF0984E3),
            bgGradient: [Color(0xFF74B9FF), Color(0xFF0984E3)],
            vedicPrinciple:
                'Mercury (Budha) represents discernment (Viveka). True professionals stay forever curious and mentally agile.',
            scientificFact:
                'Lifelong learning builds cognitive reserve, insulating against age-related executive decline.',
            dailySelfHelpActions: [
              'Read 15 minutes of thought-leadership or philosophical literature daily.',
              'Learn 1 new industry tool or framework every month.',
              'Reflect on weekly lessons learned in a dedicated journal.',
            ],
            affirmation: 'My intellect is sharp, adaptable, and expanding with timeless wisdom.',
          ),
        ];

      case AgeGroup.senior:
        return const [
          TopicBubbleItem(
            id: 'peace',
            title: 'Inner Peace & Sadhana',
            subtitle: 'Meditation, sacred mantra & spiritual tranquility',
            icon: Icons.self_improvement_rounded,
            accentColor: Color(0xFF00CEC9),
            bgGradient: [Color(0xFF81ECEC), Color(0xFF00CEC9)],
            vedicPrinciple:
                'Patanjali declares that stillness reveals the true Self (Atman). Sadhana brings timeless joy untouched by worldly changes.',
            scientificFact:
                'Mindful meditation in seniors preserves gray matter density in the hippocampus and drastically improves sleep architecture.',
            dailySelfHelpActions: [
              'Dedicate 20 minutes every morning to silent meditation or gentle chanting.',
              'Practice slow abdominal breathing during sunrise (Brahma Muhurtha).',
              'End the day with peaceful reflection and gratitude.',
            ],
            affirmation: 'I am resting in sacred tranquility, deep peace, and divine contentment.',
          ),
          TopicBubbleItem(
            id: 'health',
            title: 'Ayurvedic Health & Longevity',
            subtitle: 'Joint mobility, warm nutrition & restorative rest',
            icon: Icons.spa_rounded,
            accentColor: Color(0xFF00B894),
            bgGradient: [Color(0xFF55EFC4), Color(0xFF00B894)],
            vedicPrinciple:
                'Ayurveda guides the senior years (Vanaprastha) with vata-soothing warm herbal oils, nourishing soups, and gentle mobility.',
            scientificFact:
                'Gentle daily walking and joint mobilization preserve synovial fluid, reducing stiffness by up to 55%.',
            dailySelfHelpActions: [
              'Drink a glass of warm water upon waking while seated.',
              'Enjoy a pleasant 20-minute morning walk in fresh air and mild sunlight.',
              'Consume warm, freshly prepared meals with digestive spices like ginger and cumin.',
            ],
            affirmation: 'My body is flexible, healthy, and nurtured by nature\'s wisdom.',
          ),
          TopicBubbleItem(
            id: 'love',
            title: 'Family Blessings & Well-being',
            subtitle: 'Lineage protection, harmony & unconditional love',
            icon: Icons.diversity_1_rounded,
            accentColor: Color(0xFFE84393),
            bgGradient: [Color(0xFFFD79A8), Color(0xFFE84393)],
            vedicPrinciple:
                'Elders in Vedic culture are the pillars of family grace. Your loving blessings (Ashirwad) shield children and grandchildren.',
            scientificFact:
                'Sending warm, compassionate intentions activates the brain\'s reward and empathy circuits, reducing loneliness and inflammation.',
            dailySelfHelpActions: [
              'Send silent mental blessings of peace to children and family members daily.',
              'Share stories of values, courage, and family roots with younger generations.',
              'Release family worries to divine protection, trusting life\'s natural unfolding.',
            ],
            affirmation: 'I shower my family with unconditional love, peace, and sacred blessings.',
          ),
          TopicBubbleItem(
            id: 'wealth',
            title: 'Contentment (Santosha)',
            subtitle: 'Freedom from desire, gratitude & spiritual abundance',
            icon: Icons.account_balance_wallet_rounded,
            accentColor: Color(0xFFE17055),
            bgGradient: [Color(0xFFFAB1A0), Color(0xFFE17055)],
            vedicPrinciple:
                'Santosha (supreme contentment) is described as the highest wealth. True richness is being complete within oneself.',
            scientificFact:
                'Contentment and gratitude trigger sustained parasympathetic tone, optimizing heart rate variability and immune function.',
            dailySelfHelpActions: [
              'Express thankfulness for the simple gifts of health, breath, and companionship.',
              'Practice generosity through kind words, guidance, or quiet charity.',
              'Recognize that your true security comes from inner peace.',
            ],
            affirmation: 'I am richly blessed, complete, and content in every moment.',
          ),
          TopicBubbleItem(
            id: 'education',
            title: 'Spiritual Wisdom & Scripture',
            subtitle: 'Bhagavad Gita, Upanishadic insight & Self-knowledge',
            icon: Icons.menu_book_rounded,
            accentColor: Color(0xFF0984E3),
            bgGradient: [Color(0xFF74B9FF), Color(0xFF0984E3)],
            vedicPrinciple:
                'Jnana Yoga (the path of knowledge) reveals our eternal nature. Reflecting on sacred verses brings radiant clarity.',
            scientificFact:
                'Philosophical reflection engages high-level neurocognitive integration, promoting psychological wholeness and peace.',
            dailySelfHelpActions: [
              'Read or listen to 1 chapter or commentary of spiritual philosophy daily.',
              'Contemplate the deeper meaning of life and eternal truth.',
              'Discuss wisdom and timeless life lessons with like-minded companions.',
            ],
            affirmation: 'My mind is illuminated with divine wisdom, understanding, and grace.',
          ),
          TopicBubbleItem(
            id: 'career',
            title: 'Mentorship & Selfless Service',
            subtitle: 'Sharing life experience & guiding the next generation',
            icon: Icons.handshake_rounded,
            accentColor: Color(0xFF6C5CE7),
            bgGradient: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
            vedicPrinciple:
                'Seva (selfless service) is the highest culmination of life. Sharing accumulated wisdom purifies the heart.',
            scientificFact:
                'Mentoring younger generations boosts social connectivity and releases neuroprotective dopamine and oxytocin.',
            dailySelfHelpActions: [
              'Offer encouragement and patience to someone facing life struggles.',
              'Provide calm perspective when younger family members feel hurried or stressed.',
              'Perform 1 small act of selfless kindness with no expectation in return.',
            ],
            affirmation: 'I share my life wisdom with patience, warmth, and generous service.',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AgeProfileService.instance,
      builder: (context, _) {
        final ageGroup = AgeProfileService.instance.ageGroup;
        final bgColor = switch (ageGroup) {
          AgeGroup.youth => const Color(0xFFFAF9FF),
          AgeGroup.adult => const Color(0xFFF8FAFC),
          AgeGroup.senior => const Color(0xFFFFFDF5),
        };

        return Scaffold(
          backgroundColor: bgColor,
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
                // Age Cohort Mode Switcher
                const AgeCohortSelectorBar(),
                const SizedBox(height: 14),
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
      },
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
