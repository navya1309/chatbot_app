import 'package:flutter/material.dart';
import 'card_front.dart';
import 'card_back.dart';
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isMythMode ? "Myth Busting" : "Fun Facts",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isMythMode
                      ? [const Color(0xFFEF4444), const Color(0xFFF59E0B)]
                      : [const Color(0xFF10B981), const Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  isMythMode ? Icons.lightbulb : Icons.auto_awesome,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    isMythMode = !isMythMode;
                    showBack = false;
                    currentIndex = 0;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: card == null
            ? const Text(
                "No cards available.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              )
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: GestureDetector(
                  onTap: () => setState(() => showBack = !showBack),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: showBack
                        ? CardBack(card: card, isMyth: isMythMode)
                        : CardFront(card: card, isMyth: isMythMode),
                  ),
                ),
              ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => setState(() {
            currentIndex = (currentIndex + 1) % cards.length;
            showBack = false;
          }),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
        ),
      ),
    );
  }
}
