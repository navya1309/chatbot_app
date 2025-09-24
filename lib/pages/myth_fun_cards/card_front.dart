import 'package:flutter/material.dart';
import 'myth_busting_card.dart';
import 'fun_fact_card.dart';

class CardFront extends StatelessWidget {
  final dynamic card;
  final bool isMyth;
  CardFront({required this.card, required this.isMyth});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('front'),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.blue[50],
      ),
      child: Center(
        child: Text(
          isMyth ? card.myth : card.question,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
