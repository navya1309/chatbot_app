import 'card_category.dart';

class FunFactCard {
  final String id;
  final String question;
  final String fact;
  final CardCategory category;

  FunFactCard(
      {required this.id,
      required this.question,
      required this.fact,
      required this.category});
}
