import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'card_front.dart';
import 'card_back.dart';
import 'myth_fun_service.dart';

class MythFunCardsPage extends StatefulWidget {
  const MythFunCardsPage({super.key});

  @override
  _MythFunCardsPageState createState() => _MythFunCardsPageState();
}

class _MythFunCardsPageState extends State<MythFunCardsPage>
    with SingleTickerProviderStateMixin {
  bool showBack = false;
  int currentIndex = 0;
  bool isMythMode = true;
  late AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    setState(() => showBack = !showBack);
    if (showBack) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _nextCard(List cards) {
    setState(() {
      final wrapped = currentIndex + 1 >= cards.length;
      if (wrapped) {
        // We've cycled through the whole deck — reshuffle so the next pass
        // feels like new content.
        MythFunService.instance.reshuffle();
        currentIndex = 0;
      } else {
        currentIndex = currentIndex + 1;
      }
      showBack = false;
    });
    _flipController.reverse();
  }

  void _shuffleDeck() {
    setState(() {
      MythFunService.instance.reshuffle();
      currentIndex = 0;
      showBack = false;
    });
    _flipController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    var cards = isMythMode
        ? MythFunService.instance.mythCards
        : MythFunService.instance.funFactCards;

    var card = cards.isNotEmpty ? cards[currentIndex % cards.length] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Learn & Discover',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Shuffle deck',
                        onPressed: _shuffleDeck,
                        icon: const Icon(Icons.shuffle_rounded,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap a card to reveal the truth',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.82),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Segmented toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _toggleTab('Myth Busting', true, isMythMode),
                        _toggleTab('Fun Facts', false, isMythMode),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Card area
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  // Counter
                  if (cards.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentIndex + 1} / ${cards.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Flip card
                  Expanded(
                    child: card == null
                        ? Center(
                            child: Text(
                              'No cards available.',
                              style: GoogleFonts.inter(
                                  fontSize: 16, color: Colors.grey[500]),
                            ),
                          )
                        : GestureDetector(
                            onTap: _toggleCard,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(
                                            begin: 0.92, end: 1.0)
                                        .animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: showBack
                                  ? CardBack(
                                      card: card,
                                      isMyth: isMythMode)
                                  : CardFront(
                                      card: card,
                                      isMyth: isMythMode),
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Hint text
                  Text(
                    showBack ? 'Tap to flip back' : 'Tap card to reveal',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Next Card button
                  if (cards.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => _nextCard(cards),
                        icon: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 20),
                        label: Text(
                          'Next Card',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, bool isMyth, bool currentMode) {
    final isActive = isMyth == currentMode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isMythMode = isMyth;
            showBack = false;
            currentIndex = 0;
          });
          _flipController.reverse();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? const Color(0xFF6366F1)
                  : Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }
}
