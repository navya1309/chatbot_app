import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'provider/profile_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _primary = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        final user = provider.currentUser;

        // User is null → signed out; blank screen while navigation resolves
        if (user == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F7FF),
            body: SizedBox.shrink(),
          );
        }

        final profileStream = provider.profileStream;
        if (profileStream == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F7FF),
            body: Center(
                child: CircularProgressIndicator(color: _primary)),
          );
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: profileStream,
          builder: (context, snapshot) {
            String fullName = 'Friend';
            String email = user.email ?? 'Not set';
            String? memberSince;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data()!;
              fullName = (data['fullName'] as String?)?.trim().isNotEmpty == true
                  ? data['fullName'] as String
                  : user.displayName ?? 'Friend';
              email = (data['email'] as String?) ?? user.email ?? 'Not set';
              final createdAt = data['createdAt'];
              if (createdAt is Timestamp) {
                memberSince = _formatDate(createdAt.toDate());
              }
            }

            final initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P';

            return Scaffold(
              backgroundColor: const Color(0xFFF8F7FF),
              body: CustomScrollView(
                slivers: [
                  // Gradient header
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 72, 24, 36),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.25),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 3),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            fullName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                          if (memberSince != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Member since $memberSince',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _sectionTitle('How to Use PillowTalk'),
                        const SizedBox(height: 10),
                        _card(children: const [
                          _GuideRow(
                            icon: Icons.chat_bubble_rounded,
                            iconColor: Color(0xFF6366F1),
                            title: 'Chat',
                            description:
                                'Talk, reflect, and get supportive guidance anytime.',
                          ),
                          _GuideRow(
                            icon: Icons.book_rounded,
                            iconColor: Color(0xFF10B981),
                            title: 'Journal',
                            description:
                                'Log daily thoughts, moods, and insights.',
                          ),
                          _GuideRow(
                            icon: Icons.favorite_rounded,
                            iconColor: Color(0xFFF472B6),
                            title: 'Wellness',
                            description:
                                'Track your cycle and explore self-care.',
                          ),
                          _GuideRow(
                            icon: Icons.lightbulb_rounded,
                            iconColor: Color(0xFFF59E0B),
                            title: 'Learn',
                            description:
                                'Browse myths and fun facts to stay informed.',
                          ),
                        ]),

                        const SizedBox(height: 20),
                        _sectionTitle('Account'),
                        const SizedBox(height: 10),
                        _card(children: [
                          _infoRow('User ID', user.uid),
                          _infoRow('Email', email),
                        ]),

                        const SizedBox(height: 20),
                        _sectionTitle('Actions'),
                        const SizedBox(height: 10),

                        // Log Out
                        GestureDetector(
                          onTap: () => provider.signOut(context),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.logout_rounded,
                                      color: Color(0xFFEF4444), size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Log Out',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFEF4444),
                                        ),
                                      ),
                                      Text(
                                        'Sign out of your account',
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 14, color: Color(0xFFEF4444)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
      );

  static Widget _card({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: children),
      );

  static Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _GuideRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _GuideRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[500],
                    height: 1.4,
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
