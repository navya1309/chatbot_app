import 'package:flutter/material.dart';

class CardFront extends StatelessWidget {
  final dynamic card;
  final bool isMyth;
  CardFront({required this.card, required this.isMyth});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('front'),
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isMyth
              ? [const Color(0xFFEF4444), const Color(0xFFF59E0B)]
              : [const Color(0xFF10B981), const Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isMyth ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMyth ? Icons.warning_amber_rounded : Icons.emoji_objects_rounded,
            size: 48,
            color: Colors.white70,
          ),
          const SizedBox(height: 24),
          Text(
            isMyth ? card.myth : card.question,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: Colors.white,
              height: 1.4,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Text(
                  'Tap to reveal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
