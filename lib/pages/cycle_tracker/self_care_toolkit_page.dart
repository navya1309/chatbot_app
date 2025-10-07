import 'package:flutter/material.dart';

class SelfCareToolkitPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Self-Care Toolkit',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Take care of yourself during your cycle',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        _buildSelfCareCard(
          context,
          icon: Icons.thermostat_outlined,
          title: "Heat Pad Therapy",
          description:
              "Place it on your lower belly for 15-20 minutes to help relieve cramps.",
          gradient: const [Color(0xFFEF4444), Color(0xFFF59E0B)],
        ),
        const SizedBox(height: 16),
        _buildSelfCareCard(
          context,
          icon: Icons.self_improvement_outlined,
          title: "Gentle Stretching",
          description:
              "Try child's pose, cat-cow stretch, or supine twist to ease discomfort.",
          gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        const SizedBox(height: 16),
        _buildSelfCareCard(
          context,
          icon: Icons.local_drink_outlined,
          title: "Stay Hydrated",
          description:
              "Drink plenty of water to reduce bloating and stay energized.",
          gradient: const [Color(0xFF10B981), Color(0xFF059669)],
        ),
        const SizedBox(height: 16),
        _buildSelfCareCard(
          context,
          icon: Icons.bedtime_outlined,
          title: "Rest & Sleep",
          description:
              "Get 7-9 hours of quality sleep to help your body recover.",
          gradient: const [Color(0xFF8B5CF6), Color(0xFFA855F7)],
        ),
        const SizedBox(height: 16),
        _buildSelfCareCard(
          context,
          icon: Icons.spa_outlined,
          title: "Relaxation",
          description:
              "Try meditation, deep breathing, or a warm bath to reduce stress.",
          gradient: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
        ),
        const SizedBox(height: 16),
        _buildSelfCareCard(
          context,
          icon: Icons.restaurant_outlined,
          title: "Healthy Nutrition",
          description:
              "Eat foods rich in iron, magnesium, and vitamins to support your cycle.",
          gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
      ],
    );
  }

  Widget _buildSelfCareCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
