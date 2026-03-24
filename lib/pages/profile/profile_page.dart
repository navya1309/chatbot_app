import 'package:chatbot_app_1/pages/auth/provider/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthenticationProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view your profile.'),
        ),
      );
    }

    final userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDocStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load profile details.'),
            );
          }
          final data = snapshot.data?.data() ?? {};
          final fullName =
              (data['fullName'] as String?) ?? user.displayName ?? 'Friend';
          final email = (data['email'] as String?) ?? user.email ?? 'Not set';
          final memberSince = _formatDate(data['createdAt']);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeader(fullName, email),
              const SizedBox(height: 20),
              _buildSectionTitle('Account Information'),
              _buildInfoCard(
                children: [
                  _buildInfoRow('User ID', user.uid),
                  _buildInfoRow('Email', email),
                  if (memberSince != null)
                    _buildInfoRow('Member Since', memberSince),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('How to Use PillowTalk'),
              _buildInfoCard(
                children: const [
                  _GuideRow(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat',
                    description:
                        'Start conversations to reflect and get supportive guidance.',
                  ),
                  _GuideRow(
                    icon: Icons.book_outlined,
                    title: 'Journal',
                    description:
                        'Log daily thoughts, moods, and insights to track progress.',
                  ),
                  _GuideRow(
                    icon: Icons.calendar_today_outlined,
                    title: 'Wellness',
                    description:
                        'Track cycle details and explore self-care suggestions.',
                  ),
                  _GuideRow(
                    icon: Icons.lightbulb_outline,
                    title: 'Learn',
                    description:
                        'Browse myths and fun facts to stay informed.',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Actions'),
              _buildInfoCard(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      'Log out',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle:
                        const Text('Sign out and return to the onboarding page.'),
                    onTap: authProvider.signOut,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(String name, String email) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6366F1),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}-$month-$day';
    }
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }
}

class _GuideRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _GuideRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
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
