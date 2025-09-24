import 'card_category.dart';

class MythBustingCard {
  final String id;
  final String myth;
  final String truth;
  final CardCategory category;

  MythBustingCard(
      {required this.id,
      required this.myth,
      required this.truth,
      required this.category});
}
