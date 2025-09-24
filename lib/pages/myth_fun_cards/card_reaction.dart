class CardReaction {
  final String cardId;
  final bool believedBefore;
  final Map<String, int> emojiCounts;
  CardReaction(
      {required this.cardId,
      required this.believedBefore,
      required this.emojiCounts});
}
