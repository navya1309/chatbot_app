import 'package:flutter/material.dart';

class CardBack extends StatelessWidget {
  final dynamic card;
  final bool isMyth;
  CardBack({required this.card, required this.isMyth});

  @override
  Widget build(BuildContext context) {
    String mainText = isMyth ? card.truth : card.fact;

    return Container(
      key: ValueKey('back'),
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isMyth
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isMyth
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6366F1))
                      .withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isMyth ? Icons.check_circle_rounded : Icons.star_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isMyth ? 'The Truth' : 'Did You Know?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            mainText,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            'How did you feel?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildReactionButton('😲', 'Surprised'),
              const SizedBox(width: 16),
              _buildReactionButton('🤔', 'Thoughtful'),
              const SizedBox(width: 16),
              _buildReactionButton('💡', 'Learned'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(String emoji, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
