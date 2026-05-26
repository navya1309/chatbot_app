import 'dart:math';

import 'myth_busting_card.dart';
import 'fun_fact_card.dart';
import 'card_category.dart';
import 'card_reaction.dart';

class MythFunService {
  static final MythFunService instance = MythFunService._internal();
  MythFunService._internal() {
    // Shuffle once per session so each app launch feels like a fresh deck.
    final seed = DateTime.now().millisecondsSinceEpoch;
    mythCards.shuffle(Random(seed));
    funFactCards.shuffle(Random(seed + 1));
  }

  List<MythBustingCard> mythCards = [
    MythBustingCard(
      id: 'm1',
      myth: 'Crying is a sign of weakness.',
      truth:
          'Crying is a natural way your body processes emotions — it actually reduces stress.',
      category: CardCategory.MentalHealth,
    ),
    MythBustingCard(
      id: 'm2',
      myth: 'Menstruation makes you dirty.',
      truth:
          'Periods are natural biological functions — there\'s nothing unhygienic or shameful about them.',
      category: CardCategory.Periods,
    ),
    MythBustingCard(
      id: 'm3',
      myth: "If you're anxious, you just need to calm down.",
      truth:
          "Anxiety is not something you can just 'shut off.' It needs tools, support, and patience.",
      category: CardCategory.BrainEmotions,
    ),
    MythBustingCard(
      id: 'm4',
      myth: "Talking to a therapist means you're crazy.",
      truth:
          "Therapy is for anyone who wants to feel better or understand themselves — like the gym, but for your mind.",
      category: CardCategory.BrainEmotions,
    ),
    MythBustingCard(
      id: 'm5',
      myth: 'Only girls get eating disorders.',
      truth:
          'Anyone of any gender can struggle with body image and food-related anxiety.',
      category: CardCategory.GenderIdentity,
    ),
    MythBustingCard(
      id: 'm6',
      myth: 'Being sad for a few days means you have depression.',
      truth:
          'Occasional sadness is normal. Depression is deeper, longer-lasting, and diagnosable.',
      category: CardCategory.BrainEmotions,
    ),
    MythBustingCard(
      id: 'm7',
      myth: 'You shouldn\'t exercise during your period.',
      truth:
          'Light to moderate exercise can actually ease cramps and improve mood by releasing endorphins.',
      category: CardCategory.Periods,
    ),
    MythBustingCard(
      id: 'm8',
      myth: 'PMS is "all in your head".',
      truth:
          'PMS involves real hormonal shifts that affect mood, energy, sleep, and appetite. It\'s biology, not drama.',
      category: CardCategory.Periods,
    ),
    MythBustingCard(
      id: 'm9',
      myth: 'Men shouldn\'t cry.',
      truth:
          'Emotional expression is human, not gendered. Suppressing feelings is linked to worse mental health outcomes for everyone.',
      category: CardCategory.GenderIdentity,
    ),
    MythBustingCard(
      id: 'm10',
      myth: 'Mental health issues are rare.',
      truth:
          'One in four people will experience a mental health condition in their lifetime. You\'re far from alone.',
      category: CardCategory.MentalHealth,
    ),
    MythBustingCard(
      id: 'm11',
      myth: 'You can "snap out of" depression.',
      truth:
          'Depression is a medical condition, not a choice. Recovery usually involves support, therapy, and sometimes medication.',
      category: CardCategory.MentalHealth,
    ),
    MythBustingCard(
      id: 'm12',
      myth: 'Self-care is selfish.',
      truth:
          'You can\'t pour from an empty cup. Taking care of yourself lets you show up better for everyone else.',
      category: CardCategory.MentalHealth,
    ),
    MythBustingCard(
      id: 'm13',
      myth: 'A "normal" cycle is exactly 28 days.',
      truth:
          'Anywhere from 21 to 35 days is considered healthy. Your normal is yours.',
      category: CardCategory.Periods,
    ),
    MythBustingCard(
      id: 'm14',
      myth: 'Period pain that stops your day is normal.',
      truth:
          'Pain that disrupts daily life can be a sign of conditions like endometriosis — it\'s worth talking to a doctor.',
      category: CardCategory.Periods,
    ),
    MythBustingCard(
      id: 'm15',
      myth: 'You shouldn\'t talk about feelings — it makes them worse.',
      truth:
          'Naming an emotion actually lowers its intensity in the brain. Talking helps you process, not amplify.',
      category: CardCategory.BrainEmotions,
    ),
    MythBustingCard(
      id: 'm16',
      myth: 'Anxiety means there\'s really something to worry about.',
      truth:
          'Anxiety is a false alarm system that fires even when you\'re safe. It\'s a signal to check in, not always a verdict.',
      category: CardCategory.BrainEmotions,
    ),
    MythBustingCard(
      id: 'm17',
      myth: 'Sleep is a luxury.',
      truth:
          'Sleep is when your brain consolidates memory and regulates mood. Skipping it tanks both.',
      category: CardCategory.BodyAwesome,
    ),
    MythBustingCard(
      id: 'm18',
      myth: 'You have to "earn" rest.',
      truth:
          'Rest isn\'t a reward — it\'s a biological need. You deserve it just for being alive.',
      category: CardCategory.MentalHealth,
    ),
    MythBustingCard(
      id: 'm19',
      myth: 'Strong people don\'t ask for help.',
      truth:
          'Asking for help takes courage and self-awareness. It\'s one of the strongest things you can do.',
      category: CardCategory.MentalHealth,
    ),
    MythBustingCard(
      id: 'm20',
      myth: 'If you\'re successful, you shouldn\'t feel anxious or sad.',
      truth:
          'Mental health doesn\'t check your résumé. Anyone can struggle, regardless of how their life looks from outside.',
      category: CardCategory.MentalHealth,
    ),
    MythBustingCard(
      id: 'm21',
      myth: 'Gender is just biology.',
      truth:
          'Gender includes identity, expression, and how someone relates to the world. It\'s richer than chromosomes alone.',
      category: CardCategory.GenderIdentity,
    ),
    MythBustingCard(
      id: 'm22',
      myth: 'Meditation requires emptying your mind.',
      truth:
          'Meditation is about noticing thoughts, not eliminating them. Thoughts wandering is part of the practice.',
      category: CardCategory.MentalHealth,
    ),
    MythBustingCard(
      id: 'm23',
      myth: 'You should be over a hard event by now.',
      truth:
          'Healing has no timeline. Grief, trauma, and big changes take as long as they take.',
      category: CardCategory.BrainEmotions,
    ),
    MythBustingCard(
      id: 'm24',
      myth: 'Boys mature later, that\'s why they\'re emotionally distant.',
      truth:
          'Emotional skills are learned, not just developed by age. Boys are often taught to suppress, not "behind".',
      category: CardCategory.GenderIdentity,
    ),
    MythBustingCard(
      id: 'm25',
      myth: 'If you can function, you\'re fine.',
      truth:
          'High-functioning struggle is still struggle. Many people quietly carry a lot while looking "okay".',
      category: CardCategory.MentalHealth,
    ),
  ];

  List<FunFactCard> funFactCards = [
    FunFactCard(
      id: 'f1',
      question: "Did you know your heart can literally 'sync' with a friend's?",
      fact:
          "When you sit with someone and feel emotionally connected, your heartbeats can align. That's human magic.",
      category: CardCategory.BrainEmotions,
    ),
    FunFactCard(
      id: 'f2',
      question: 'Cuddling can reduce pain?',
      fact:
          'Yes — physical touch releases oxytocin, a hormone that fights stress and eases physical pain.',
      category: CardCategory.BodyAwesome,
    ),
    FunFactCard(
      id: 'f3',
      question: 'Laughter boosts immunity!',
      fact:
          "Laughing activates immune cells and reduces stress hormones. It's your body's free medicine.",
      category: CardCategory.FunScienceFeelings,
    ),
    FunFactCard(
      id: 'f4',
      question: 'Your brain rewires when you learn something new.',
      fact:
          "Every time you try a new hobby or reflect deeply, your brain forms new neural connections. You're always growing.",
      category: CardCategory.BodyAwesome,
    ),
    FunFactCard(
      id: 'f5',
      question: "There are more neurons in your gut than in a cat's brain.",
      fact:
          "That's why your gut feelings are often right — your body has its own 'second brain'.",
      category: CardCategory.BodyAwesome,
    ),
    FunFactCard(
      id: 'f6',
      question: 'Crying releases stress hormones?',
      fact:
          'Emotional tears actually contain cortisol and other stress chemicals — crying literally flushes some stress out of your body.',
      category: CardCategory.FunScienceFeelings,
    ),
    FunFactCard(
      id: 'f7',
      question: 'Music can change your heart rate.',
      fact:
          'Slow songs can lower your heart rate; upbeat ones lift it. Your favorite playlist is basically biofeedback.',
      category: CardCategory.FunScienceFeelings,
    ),
    FunFactCard(
      id: 'f8',
      question: 'Sunlight is a natural antidepressant.',
      fact:
          'Just 10–15 minutes of morning sunlight helps regulate serotonin and your sleep–wake cycle.',
      category: CardCategory.BodyAwesome,
    ),
    FunFactCard(
      id: 'f9',
      question: 'Writing by hand calms anxious thoughts.',
      fact:
          'Putting feelings into handwriting activates parts of the brain that reduce emotional intensity.',
      category: CardCategory.BrainEmotions,
    ),
    FunFactCard(
      id: 'f10',
      question: 'Plants can lift your mood.',
      fact:
          'Just being around greenery has been shown to reduce cortisol and increase feelings of calm.',
      category: CardCategory.FunScienceFeelings,
    ),
    FunFactCard(
      id: 'f11',
      question: 'You can\'t tickle yourself.',
      fact:
          'Your brain predicts your own touch, so it cancels the surprise. Tickling needs unpredictability.',
      category: CardCategory.BodyAwesome,
    ),
    FunFactCard(
      id: 'f12',
      question: 'Your skin is your largest organ.',
      fact:
          'It spans about 2 square meters and is constantly renewing itself — about every 27 days.',
      category: CardCategory.BodyAwesome,
    ),
    FunFactCard(
      id: 'f13',
      question: 'Smiling can actually make you feel happier.',
      fact:
          'Even a forced smile sends signals to your brain that nudge your mood upward, just a little.',
      category: CardCategory.BrainEmotions,
    ),
    FunFactCard(
      id: 'f14',
      question: 'Hugs for 20 seconds release oxytocin.',
      fact:
          'A long hug genuinely shifts your hormones toward calm and trust. Quality over quantity.',
      category: CardCategory.BrainEmotions,
    ),
    FunFactCard(
      id: 'f15',
      question: 'Cold water on your face calms panic.',
      fact:
          'It triggers the "dive reflex", slowing your heart rate. A real hack for spiraling moments.',
      category: CardCategory.BrainEmotions,
    ),
    FunFactCard(
      id: 'f16',
      question: 'Boredom is good for your brain.',
      fact:
          'Idle time is when the brain\'s default network sparks creativity and self-reflection.',
      category: CardCategory.BrainEmotions,
    ),
    FunFactCard(
      id: 'f17',
      question: 'Your body literally regenerates daily.',
      fact:
          'You replace about 330 billion cells a day. You are not the same person, physically, as you were last month.',
      category: CardCategory.BodyAwesome,
    ),
    FunFactCard(
      id: 'f18',
      question: 'Periods shed roughly 30–80 ml of fluid.',
      fact:
          'It often feels like more — but it\'s usually only a few tablespoons across the whole cycle.',
      category: CardCategory.Periods,
    ),
    FunFactCard(
      id: 'f19',
      question: 'Your cycle has four distinct phases.',
      fact:
          'Menstrual, follicular, ovulation, and luteal — each affects mood, energy, and focus differently.',
      category: CardCategory.Periods,
    ),
    FunFactCard(
      id: 'f20',
      question: 'Naming emotions reduces their power.',
      fact:
          'Brain scans show that labeling a feeling literally calms the amygdala. Try it: "I feel ___."',
      category: CardCategory.BrainEmotions,
    ),
    FunFactCard(
      id: 'f21',
      question: 'Walking sparks creativity.',
      fact:
          'Studies show creative thinking jumps up to 60% during and right after a walk.',
      category: CardCategory.FunScienceFeelings,
    ),
    FunFactCard(
      id: 'f22',
      question: 'Pets lower blood pressure.',
      fact:
          'Just petting an animal can release oxytocin and lower stress markers within minutes.',
      category: CardCategory.FunScienceFeelings,
    ),
    FunFactCard(
      id: 'f23',
      question: 'Your brain is mostly fat.',
      fact:
          'About 60%. Healthy fats (like omega-3s) genuinely help mood and cognition.',
      category: CardCategory.BodyAwesome,
    ),
    FunFactCard(
      id: 'f24',
      question: 'Deep breathing changes your nervous system.',
      fact:
          'Long exhales activate the vagus nerve, which physically shifts you into calm mode.',
      category: CardCategory.BodyAwesome,
    ),
    FunFactCard(
      id: 'f25',
      question: 'Your mood follows your gut microbiome.',
      fact:
          'Roughly 90% of serotonin is made in the gut. What you eat literally affects how you feel.',
      category: CardCategory.BodyAwesome,
    ),
  ];

  Map<String, CardReaction> cardReactions = {};

  Future<void> recordReaction(
      String cardId, bool believedBefore, String emoji) async {
    cardReactions.putIfAbsent(
        cardId,
        () => CardReaction(
            cardId: cardId, believedBefore: believedBefore, emojiCounts: {}));
    cardReactions[cardId]!
        .emojiCounts
        .update(emoji, (v) => v + 1, ifAbsent: () => 1);
  }

  List<String> favoriteCardIds = [];
  Future<void> toggleFavorite(String cardId) async {
    if (favoriteCardIds.contains(cardId)) {
      favoriteCardIds.remove(cardId);
    } else {
      favoriteCardIds.add(cardId);
    }
  }

  Future<MythBustingCard> getMythOfTheDay() async {
    return mythCards[(DateTime.now().day) % mythCards.length];
  }

  Future<FunFactCard> getFunFactOfTheDay() async {
    return funFactCards[(DateTime.now().day) % funFactCards.length];
  }

  Future<List<MythBustingCard>> getMythCards({CardCategory? category}) async {
    return category == null
        ? List.from(mythCards)
        : mythCards.where((c) => c.category == category).toList();
  }

  Future<List<FunFactCard>> getFunFactCards({CardCategory? category}) async {
    return category == null
        ? List.from(funFactCards)
        : funFactCards.where((c) => c.category == category).toList();
  }

  // Reshuffle the active decks. Call when the user wants fresh content
  // without restarting the app.
  void reshuffle() {
    final seed = DateTime.now().microsecondsSinceEpoch;
    mythCards.shuffle(Random(seed));
    funFactCards.shuffle(Random(seed + 1));
  }
}
