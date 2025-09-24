import 'package:flutter/material.dart';
import 'card_front.dart';
import 'card_back.dart';
import 'myth_busting_card.dart';
import 'fun_fact_card.dart';
import 'card_category.dart';
import 'myth_fun_service.dart';

class MythFunCardsPage extends StatefulWidget {
  @override
  _MythFunCardsPageState createState() => _MythFunCardsPageState();
}

class _MythFunCardsPageState extends State<MythFunCardsPage> {
  bool showBack = false;
  int currentIndex = 0;
  bool isMythMode = true; // Use a TabBar for this in production

  @override
  Widget build(BuildContext context) {
    var cards = isMythMode
        ? MythFunService.instance.mythCards
        : MythFunService.instance.funFactCards;

    var card = cards.isNotEmpty ? cards[currentIndex % cards.length] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMythMode ? "Myth Busting" : "Fun Facts"),
        actions: [
          IconButton(
            icon: Icon(isMythMode ? Icons.lightbulb : Icons.celebration),
            onPressed: () {
              setState(() {
                isMythMode = !isMythMode;
                showBack = false;
                currentIndex = 0;
              });
            },
          ),
        ],
      ),
      body: Center(
        child: card == null
            ? Text("No cards available.")
            : GestureDetector(
                onTap: () => setState(() => showBack = !showBack),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 250),
                  child: showBack
                      ? CardBack(card: card, isMyth: isMythMode)
                      : CardFront(card: card, isMyth: isMythMode),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {
          currentIndex = (currentIndex + 1) % cards.length;
          showBack = false;
        }),
        child: Icon(Icons.navigate_next),
      ),
    );
  }
}
