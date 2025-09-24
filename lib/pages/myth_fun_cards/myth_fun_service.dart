import 'myth_busting_card.dart';
import 'fun_fact_card.dart';
import 'card_category.dart';
import 'card_reaction.dart';

class MythFunService {
  static final MythFunService instance = MythFunService._internal();
  MythFunService._internal();

  List<MythBustingCard> mythCards = [
    MythBustingCard(
      id: '1',
      myth: 'Crying is a sign of weakness.',
      truth:
          'Crying is a natural way your body processes emotions — it actually reduces stress.',
      category: CardCategory.MentalHealth,
    ),
    MythBustingCard(
      id: '2',
      myth: 'Menstruation makes you dirty.',
      truth:
          'Periods are natural biological functions — there\'s nothing unhygienic or shameful about them.',
      category: CardCategory.Periods,
    ),
    MythBustingCard(
      id: '3',
      myth: 'If you’re anxious, you just need to calm down',
      truth:
          'Anxiety is not something you can just ‘shut off.’ It needs tools, support, and patience.',
      category: CardCategory.BrainEmotions,
    ),
    MythBustingCard(
      id: '4',
      myth: 'Talking to a therapist means you’re crazy.',
      truth:
          'Therapy is for anyone who wants to feel better or understand themselves — just like a gym is for your body, therapy is for your mind.',
      category: CardCategory.BrainEmotions,
    ),
    MythBustingCard(
      id: '5',
      myth: 'Only girls get eating disorders',
      truth:
          'Anyone of any gender can struggle with body image and food-related anxiety.',
      category: CardCategory.GenderIdentity,
    ),
    MythBustingCard(
      id: '6',
      myth: 'Being sad for a few days means you have depression.',
      truth:
          'Occasional sadness is normal. Depression is deeper, longer-lasting, and diagnosable.',
      category: CardCategory.BrainEmotions,
    ),
  ];

  List<FunFactCard> funFactCards = [
    FunFactCard(
      id: '1',
      question: 'Did you know your heart can literally ‘sync’ with a friend’s?',
      fact:
          'When you sit with someone and feel emotionally connected, your heartbeats can align. That’s human magic.',
      category: CardCategory.BrainEmotions,
    ),
    FunFactCard(
      id: '2',
      question: 'Cuddling can reduce pain?',
      fact:
          'Yup. Physical touch releases oxytocin — a hormone that fights stress and eases physical pain.',
      category: CardCategory.BodyAwesome,
    ),
    FunFactCard(
      id: '3',
      question: 'Laughter boosts immunity!',
      fact:
          'Laughing activates immune cells and reduces stress hormones. It’s your body’s free medicine.',
      category: CardCategory.FunScienceFeelings,
    ),
    FunFactCard(
      id: '4',
      question: 'Your brain rewires when you learn something new.',
      fact:
          'Every time you try a new hobby or reflect deeply, your brain forms new neural connections. You’re always growing.',
      category: CardCategory.BodyAwesome,
    ),
    FunFactCard(
      id: '5',
      question: 'There are more neurons in your gut than in a cat’s brain.',
      fact:
          'That’s why your gut feelings are often right — your body has its own ‘second brain.’',
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
}
