import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'provider/journaling_provider.dart';

class JournalingPage extends StatefulWidget {
  const JournalingPage({super.key});

  @override
  State<JournalingPage> createState() => _JournalingPageState();
}

class _JournalingPageState extends State<JournalingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _primary = Color(0xFF6366F1);

  static const _moods = [
    ('😊', 'Happy'),
    ('😰', 'Anxious'),
    ('😴', 'Tired'),
    ('🤔', 'Thoughtful'),
    ('🤩', 'Excited'),
    ('😌', 'Peaceful'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalingProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [_buildSliverAppBar()],
        body: Consumer<JournalingProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: _primary));
            }
            return TabBarView(
              controller: _tabController,
              children: [
                _buildTimelineTab(provider),
                _buildWriteTab(provider),
                _buildInsightsTab(provider),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ─────────────────────────────────────────
  //  App Bar
  // ─────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverToBoxAdapter(
      child: Consumer<JournalingProvider>(
        builder: (ctx, provider, _) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Journal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _todayLabel(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => provider.loadAll(),
                        icon: const Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Mood row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildMoodRow(provider),
                ),

                const SizedBox(height: 20),

                // Tab bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelPadding: EdgeInsets.zero,
                      labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      labelColor: _primary,
                      unselectedLabelColor:
                          Colors.white.withValues(alpha: 0.8),
                      tabs: const [
                        Tab(text: 'Timeline'),
                        Tab(text: 'Write'),
                        Tab(text: 'Insights'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodRow(JournalingProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling?',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _moods.map((m) {
              final isSelected = provider.currentMood == m.$2;
              return GestureDetector(
                onTap: () => provider.updateMood(m.$2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.$1,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 5),
                      Text(
                        m.$2,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? _primary : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  //  Timeline Tab
  // ─────────────────────────────────────────

  Widget _buildTimelineTab(JournalingProvider provider) {
    final entries = provider.allEntries;

    return RefreshIndicator(
      onRefresh: provider.loadAll,
      color: _primary,
      child: entries.isEmpty
          ? _emptyState(
              icon: Icons.auto_stories_rounded,
              title: 'Nothing here yet',
              subtitle:
                  'Your journal entries will appear here.\nTap the ✏️ button to start writing.',
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: entries.length,
              itemBuilder: (ctx, i) =>
                  _EntryCard(
                    entry: entries[i],
                    onDelete: () =>
                        _confirmDelete(ctx, provider, entries[i].id),
                    onEdit: () =>
                        _openEditor(ctx, provider, entry: entries[i]),
                  ),
            ),
    );
  }

  // ─────────────────────────────────────────
  //  Write Tab
  // ─────────────────────────────────────────

  Widget _buildWriteTab(JournalingProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.loadAll,
      color: _primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Daily Prompt card
          if (provider.dailyPrompt.isNotEmpty) ...[
            _PromptCard(
              prompt: provider.dailyPrompt,
              onTap: () => _openEditor(
                context,
                provider,
                prefillTitle: 'Daily Reflection',
                prefillContent: '',
                type: JournalEntryType.daily_prompt,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Quick action grid
          Text(
            'What would you like to do?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _QuickActionTile(
                emoji: '✍️',
                label: 'Free Write',
                description: 'Express freely',
                color: const Color(0xFF6366F1),
                onTap: () => _openEditor(
                  context,
                  provider,
                  prefillTitle: 'Free Writing',
                  type: JournalEntryType.free_write,
                ),
              ),
              _QuickActionTile(
                emoji: '🙏',
                label: 'Gratitude',
                description: '3 things I\'m thankful for',
                color: const Color(0xFF10B981),
                onTap: () => _openEditor(
                  context,
                  provider,
                  prefillTitle: 'Gratitude Journal',
                  prefillContent:
                      '1. \n2. \n3. ',
                  type: JournalEntryType.gratitude,
                ),
              ),
              _QuickActionTile(
                emoji: '🎤',
                label: 'Voice Note',
                description: 'Speak your mind',
                color: const Color(0xFFF59E0B),
                onTap: () => _openEditor(
                  context,
                  provider,
                  prefillTitle: 'Voice Note',
                  type: JournalEntryType.voice_note,
                ),
              ),
              _QuickActionTile(
                emoji: '🎨',
                label: 'Doodle',
                description: 'Draw your feelings',
                color: const Color(0xFFF472B6),
                onTap: () => _openEditor(
                  context,
                  provider,
                  prefillTitle: 'Doodle Entry',
                  type: JournalEntryType.doodle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent active entries
          if (provider.activeEntries.isNotEmpty) ...[
            Text(
              'Your Entries',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 12),
            ...provider.activeEntries.take(5).map(
                  (e) => _EntryCard(
                    entry: e,
                    onDelete: () => _confirmDelete(context, provider, e.id),
                    onEdit: () =>
                        _openEditor(context, provider, entry: e),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Insights Tab
  // ─────────────────────────────────────────

  Widget _buildInsightsTab(JournalingProvider provider) {
    final insight = provider.weeklyInsight;
    if (insight == null) {
      return const Center(
          child: CircularProgressIndicator(color: _primary));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Weekly card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'This Week',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_fmtDate(insight.weekStart)} – ${_fmtDate(insight.weekEnd)}',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _weekStat('${insight.totalEntries}', 'Entries'),
                  _weekStat(
                      '${insight.moodPercentages['Happy']?.round() ?? 0}%',
                      'Happy'),
                  _weekStat(
                      '${insight.moodPercentages['Anxious']?.round() ?? 0}%',
                      'Anxious'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Affirmation
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💜', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '"${insight.affirmation}"',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF9D174D),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Suggestions
        _insightSection(
          '💡 Personalized Tips',
          insight.suggestions
              .map((s) => '• $s')
              .join('\n'),
        ),

        const SizedBox(height: 12),

        // Top topics
        if (insight.topTopics.isNotEmpty)
          _insightSection(
            '🔖 Top Topics',
            insight.topTopics
                .asMap()
                .entries
                .map((e) => '${e.key + 1}. ${e.value}')
                .join('\n'),
          ),

        const SizedBox(height: 20),

        // Auto-reflection settings
        Text(
          'Auto-Reflection',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Consumer<JournalingProvider>(
            builder: (ctx, prov, _) => Column(
              children: [
                _settingTile(
                  'Conversation Summaries',
                  'Auto-save chat summaries',
                  prov.settings.autoConversationSummary,
                  (v) => prov.toggleSetting('autoConversationSummary', v),
                ),
                _settingTile(
                  'Mood Auto-Tagging',
                  'Detect mood from your writing',
                  prov.settings.moodAutoTagging,
                  (v) => prov.toggleSetting('moodAutoTagging', v),
                ),
                _settingTile(
                  'Trigger-Based Entries',
                  'Auto-create entries from events',
                  prov.settings.triggerBasedEntries,
                  (v) => prov.toggleSetting('triggerBasedEntries', v),
                ),
                _settingTile(
                  'Weekly Digest',
                  'Get a summary every week',
                  prov.settings.weeklyDigest,
                  (v) => prov.toggleSetting('weeklyDigest', v),
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────

  Widget _buildFab() {
    return Consumer<JournalingProvider>(
      builder: (ctx, provider, _) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _openEditor(ctx, provider),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          label: Text(
            'New Entry',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: _primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75)),
        ),
      ],
    );
  }

  Widget _insightSection(String title, String body) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.inter(
                fontSize: 14, color: Colors.grey[600], height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _settingTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: _primary,
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey[100]),
      ],
    );
  }

  // Dialogs
  void _openEditor(
    BuildContext context,
    JournalingProvider provider, {
    JournalEntry? entry,
    String prefillTitle = '',
    String prefillContent = '',
    JournalEntryType type = JournalEntryType.free_write,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JournalEditorSheet(
        provider: provider,
        existingEntry: entry,
        prefillTitle: entry?.title ?? prefillTitle,
        prefillContent: entry?.content ?? prefillContent,
        entryType: entry?.type ?? type,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    JournalingProvider provider,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Entry?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('This cannot be undone.',
            style: GoogleFonts.inter(color: Colors.grey[600])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteEntry(id);
            },
            child: Text('Delete',
                style:
                    GoogleFonts.inter(color: const Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  // Utility
  String _todayLabel() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

// ─────────────────────────────────────────
//  Entry Card
// ─────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _EntryCard({
    required this.entry,
    required this.onDelete,
    required this.onEdit,
  });

  static const _typeColors = {
    JournalEntryType.daily_prompt: Color(0xFF6366F1),
    JournalEntryType.free_write: Color(0xFF0EA5E9),
    JournalEntryType.gratitude: Color(0xFF10B981),
    JournalEntryType.voice_note: Color(0xFFF59E0B),
    JournalEntryType.doodle: Color(0xFFF472B6),
    JournalEntryType.auto_reflection: Color(0xFF8B5CF6),
    JournalEntryType.conversation_summary: Color(0xFF8B5CF6),
  };

  @override
  Widget build(BuildContext context) {
    final color =
        _typeColors[entry.type] ?? const Color(0xFF6366F1);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  if (entry.isPassive) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.auto_awesome_rounded,
                        size: 14, color: Colors.grey[400]),
                  ],
                  const Spacer(),
                  Text(
                    _fmtTimestamp(entry.timestamp),
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                entry.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF374151),
                  height: 1.55,
                ),
              ),
              if (entry.moods.isNotEmpty || entry.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    ...entry.moods.take(3).map((m) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(m,
                              style: const TextStyle(fontSize: 15)),
                        )),
                    const Spacer(),
                    ...entry.tags.take(2).map((tag) => Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w600),
                          ),
                        )),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.edit_outlined,
                          size: 18, color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.grey[400]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

// ─────────────────────────────────────────
//  Daily Prompt Card
// ─────────────────────────────────────────

class _PromptCard extends StatelessWidget {
  final String prompt;
  final VoidCallback onTap;

  const _PromptCard({required this.prompt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✨', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Prompt",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB45309),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prompt,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF92400E),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to write →',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFB45309),
                      fontWeight: FontWeight.w600,
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

// ─────────────────────────────────────────
//  Quick Action Tile
// ─────────────────────────────────────────

class _QuickActionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.emoji,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Journal Editor Bottom Sheet
// ─────────────────────────────────────────

class _JournalEditorSheet extends StatefulWidget {
  final JournalingProvider provider;
  final JournalEntry? existingEntry;
  final String prefillTitle;
  final String prefillContent;
  final JournalEntryType entryType;

  const _JournalEditorSheet({
    required this.provider,
    this.existingEntry,
    required this.prefillTitle,
    required this.prefillContent,
    required this.entryType,
  });

  @override
  State<_JournalEditorSheet> createState() => _JournalEditorSheetState();
}

class _JournalEditorSheetState extends State<_JournalEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _tagCtrl;
  late final List<String> _tags;
  bool _saving = false;

  static const _primary = Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    _titleCtrl =
        TextEditingController(text: widget.prefillTitle);
    _contentCtrl =
        TextEditingController(text: widget.prefillContent);
    _tagCtrl = TextEditingController();
    _tags = List<String>.from(widget.existingEntry?.tags ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    try {
      final entry = JournalEntry(
        id: widget.existingEntry?.id ?? '',
        title: _titleCtrl.text.trim().isEmpty
            ? widget.provider.labelForType(widget.entryType)
            : _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        timestamp: widget.existingEntry?.timestamp ?? DateTime.now(),
        tags: _tags,
        moods: widget.existingEntry?.moods ?? [],
        type: widget.entryType,
        isPassive: widget.existingEntry?.isPassive ?? false,
      );

      if (widget.existingEntry != null) {
        await widget.provider.updateEntry(entry);
      } else {
        await widget.provider.createEntry(entry);
      }

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existingEntry != null
                          ? 'Edit Entry'
                          : 'New Entry',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                  ),
                  if (_saving) ...[
                    const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _primary)),
                  ] else ...[
                    GestureDetector(
                      onTap: _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey[100]),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextField(
                      controller: _titleCtrl,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1B4B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title (optional)',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[300],
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        filled: false,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 12),

                    // Content
                    TextField(
                      controller: _contentCtrl,
                      maxLines: null,
                      minLines: 8,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF374151),
                        height: 1.65,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'What\'s on your mind? Start writing...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.grey[400],
                          height: 1.65,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        filled: false,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 20),
                    Divider(color: Colors.grey[100]),
                    const SizedBox(height: 12),

                    // Tags
                    Text(
                      'Tags',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ..._tags.map((tag) => GestureDetector(
                              onTap: () =>
                                  setState(() => _tags.remove(tag)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _primary.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('#$tag',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: _primary,
                                          fontWeight: FontWeight.w600,
                                        )),
                                    const SizedBox(width: 4),
                                    Icon(Icons.close_rounded,
                                        size: 12, color: _primary),
                                  ],
                                ),
                              ),
                            )),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _tagCtrl,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.grey[700]),
                            decoration: InputDecoration(
                              hintText: '+ add tag',
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[400]),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              filled: false,
                            ),
                            onSubmitted: (v) {
                              final trimmed = v.trim();
                              if (trimmed.isNotEmpty &&
                                  !_tags.contains(trimmed)) {
                                setState(() => _tags.add(trimmed));
                              }
                              _tagCtrl.clear();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
