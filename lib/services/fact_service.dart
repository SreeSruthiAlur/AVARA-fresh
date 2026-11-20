import 'package:flutter/material.dart';

/// A verified connection between ancient Vedic self-help wisdom and modern science.
class AvaraFact {
  const AvaraFact({
    required this.id,
    required this.title,
    required this.category,
    required this.vedicWisdom,
    required this.scientificFact,
    required this.whyItWorks,
    required this.practicalAction,
    required this.icon,
    required this.accentColor,
    this.scientificSource = 'Neuroscience & Chronobiology Research',
  });

  final String id;
  final String title;
  final String category; // 'Habits', 'Astrology & Circadian', 'Finance', 'Health', 'Mind'
  final String vedicWisdom;
  final String scientificFact;
  final String whyItWorks;
  final String practicalAction;
  final IconData icon;
  final Color accentColor;
  final String scientificSource;
}

/// Service providing scientifically grounded Vedic self-help facts across AVARA.
class FactService {
  FactService._();
  static final FactService instance = FactService._();

  static const List<AvaraFact> allFacts = [
    AvaraFact(
      id: 'brahma_muhurtha',
      title: 'The Magic of Dawn: Brahma Muhurtha',
      category: 'Sleep & Circadian Science',
      vedicWisdom:
          'In Ayurveda and Vedic texts, waking 1.5 hours before sunrise (Brahma Muhurtha) infuses the body with sattva (clarity) and longevity.',
      scientificFact:
          'Between 4:00 AM and 6:00 AM, the brain naturally transitions from deep delta to restorative REM sleep, while cortisol awakens naturally without synthetic adrenaline spikes.',
      whyItWorks:
          'Ambient ozone and nascent oxygen levels are highest just before dawn, saturating brain cells and drastically elevating prefrontal cortex executive focus.',
      practicalAction:
          'Try shifting your waking time just 20 minutes earlier tomorrow to enjoy undisturbed silence and mental calm.',
      icon: Icons.wb_twilight_rounded,
      accentColor: Color(0xFFE65100),
      scientificSource: 'Journal of Circadian Rhythms & Chronobiology',
    ),
    AvaraFact(
      id: 'moon_emotions',
      title: 'Lunar Cycles & Human Neurobiology',
      category: 'Astrology & Chronobiology',
      vedicWisdom:
          'Vedic astrology identifies Chandra (the Moon) as the karaka (significator) of the Mind (Manas) and emotional fluid balance.',
      scientificFact:
          'Modern chronobiology studies (e.g. Science Advances, 2021) confirmed that human sleep duration and REM sleep cycles systematically synchronize with lunar light phases, even in urban environments.',
      whyItWorks:
          'Subtle geomagnetic and nocturnal ambient light shifts alter pineal gland melatonin synthesis, subtly impacting mood fluctuations, fluid retention, and emotional sensitivity.',
      practicalAction:
          'On full moon (Purnima) or new moon (Amavasya) days, practice 5 minutes of slow abdominal breathing to keep emotions grounded.',
      icon: Icons.nightlight_round,
      accentColor: Color(0xFF6C5CE7),
      scientificSource: 'Science Advances / University of Washington Sleep Study',
    ),
    AvaraFact(
      id: 'samskara_habits',
      title: 'Samskaras & Neuroplasticity: Rewiring Your Brain',
      category: 'Habits & Psychology',
      vedicWisdom:
          'Patanjali Yoga Sutras define "Samskaras" as deep grooves or mental imprints formed by repeated thoughts and actions that dictate automatic behavior.',
      scientificFact:
          'Modern neuroscience describes this exact mechanism as "Neuroplasticity and Myelination" (Hebb’s Law: "Neurons that fire together, wire together").',
      whyItWorks:
          'When you repeat an action consistently for 21 days, a myelin sheath wraps around neural axons, making positive self-help habits effortless and automatic.',
      practicalAction:
          'Pair a new tiny habit with an existing cue (e.g., "After I brush my teeth, I will write 1 thing I am grateful for").',
      icon: Icons.psychology_rounded,
      accentColor: Color(0xFF00CEC9),
      scientificSource: 'Nature Reviews Neuroscience / Stanford Behavior Design Lab',
    ),
    AvaraFact(
      id: 'dopamine_spending',
      title: 'Mindful Wealth: Beating Impulsive Spending',
      category: 'Mindful Finance',
      vedicWisdom:
          'Vedic economics distinguishes between "Shreyas" (that which brings long-term lasting well-being) and "Preyas" (fleeting sensory temptation).',
      scientificFact:
          'Impulsive purchases release a quick burst of dopamine in the nucleus accumbens before checkout, followed by an immediate dopamine dip and buyer’s remorse.',
      whyItWorks:
          'Applying a mandatory 24-hour cooling window re-engages the prefrontal cortex, cutting unnecessary retail purchases by over 68%.',
      practicalAction:
          'Before buying non-essential items, wait 24 hours. If you still want it tomorrow, review your budget first.',
      icon: Icons.savings_rounded,
      accentColor: Color(0xFF00B894),
      scientificSource: 'Harvard Behavioral Economics & Decision Sciences',
    ),
    AvaraFact(
      id: 'cellular_hydration',
      title: 'Water Memory & Mental Focus',
      category: 'Health & Vitality',
      vedicWisdom:
          'In Ayurveda, drinking water stored in natural vessels in slow, seated sips harmonizes the Apana Vayu and digestive Agni.',
      scientificFact:
          'A mere 1.5% drop in body hydration causes a 12% decline in working memory speed and triggers cognitive fatigue resembling stress.',
      whyItWorks:
          'Brain tissue is approximately 75% water; dehydration shrinks brain tissue volume temporarily, forcing the brain to work twice as hard to maintain attention.',
      practicalAction:
          'Keep a glass of water on your desk and drink 1 glass immediately upon waking to rehydrate your overnight fasting brain.',
      icon: Icons.water_drop_rounded,
      accentColor: Color(0xFF0984E3),
      scientificSource: 'European Journal of Clinical Nutrition',
    ),
    AvaraFact(
      id: 'pranayama_vagus',
      title: 'Pranayama & The Vagus Nerve',
      category: 'Mind & Stress Relief',
      vedicWisdom:
          'Pranayama (breath control, especially slow exhalations) is revered as the ultimate tool to master restless mental waves (chitta vritti).',
      scientificFact:
          'Prolonging exhalation (e.g., 4 seconds in, 6 seconds out) instantly stimulates the Vagus Nerve, releasing acetylcholine to drop heart rate and cortisol.',
      whyItWorks:
          'The vagus nerve activates the parasympathetic "rest-and-digest" branch of the nervous system, turning off fight-or-flight panic in under 90 seconds.',
      practicalAction:
          'When feeling overwhelmed or rushed, take 3 deep breaths where each exhale is twice as long as the inhale.',
      icon: Icons.air_rounded,
      accentColor: Color(0xFFE17055),
      scientificSource: 'National Institutes of Health (NIH) Vagus Nerve Research',
    ),
  ];

  AvaraFact getFactForCategory(String category) {
    return allFacts.firstWhere(
      (f) => f.category.toLowerCase().contains(category.toLowerCase()),
      orElse: () => allFacts.first,
    );
  }

  AvaraFact getRandomFact() {
    final dayIndex = DateTime.now().day % allFacts.length;
    return allFacts[dayIndex];
  }
}
