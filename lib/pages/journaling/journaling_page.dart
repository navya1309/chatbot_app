import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:scribble/scribble.dart';

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
      final provider = context.read<JournalingProvider>();
      provider.loadAll();
      provider.loadAiInsightHistory();
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

    if (entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.loadAll,
        color: _primary,
        child: _emptyState(
          icon: Icons.auto_stories_rounded,
          title: 'Nothing here yet',
          subtitle:
              'Your journal entries will appear here.\nTap the ✏️ button to start writing.',
        ),
      );
    }

    // Group entries by their day so the timeline reads like a calendar.
    // Entries are already sorted descending by timestamp; keep that order.
    final byDay = <String, List<JournalEntry>>{};
    final dayOrder = <String>[];
    for (final e in entries) {
      final key = _dayKey(e.timestamp);
      if (!byDay.containsKey(key)) {
        byDay[key] = [];
        dayOrder.add(key);
      }
      byDay[key]!.add(e);
    }

    return RefreshIndicator(
      onRefresh: provider.loadAll,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: dayOrder.length,
        itemBuilder: (ctx, i) {
          final key = dayOrder[i];
          final dayEntries = byDay[key]!;
          final headerDate = dayEntries.first.timestamp;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayHeader(date: headerDate, count: dayEntries.length),
              const SizedBox(height: 8),
              ...dayEntries.map((e) => _EntryCard(
                    entry: e,
                    onDelete: () => _confirmDelete(ctx, provider, e.id),
                    onEdit: () => _openEditor(ctx, provider, entry: e),
                  )),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';

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

        // Mood summary (AI-generated single-line headline of the week's mood).
        if ((insight.moodSummary ?? '').isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🌈', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insight.moodSummary!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1B4B),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // AI reflection card.
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _primary.withValues(alpha: 0.18),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI Reflection',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Regenerate reflection',
                    onPressed: provider.refreshingAi
                        ? null
                        : provider.refreshAiInsight,
                    icon: provider.refreshingAi
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _primary),
                          )
                        : const Icon(Icons.refresh_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                (insight.aiReflection ?? '').isNotEmpty
                    ? insight.aiReflection!
                    : 'Tap refresh to get a personalized reflection from AI based on your moods and journal entries this week.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.6,
                  color: const Color(0xFF374151),
                ),
              ),
              if (insight.aiGuidance.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'What might help',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                ...insight.aiGuidance.map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✦  ',
                            style: TextStyle(color: Color(0xFF6366F1))),
                        Expanded(
                          child: Text(
                            g,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.5,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

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

        // AI Insights History — a chronological list of past AI reflections.
        if (provider.aiInsightHistory.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Past Reflections',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
              ),
              Text(
                '${provider.aiInsightHistory.length}',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
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
              children: [
                for (var i = 0;
                    i < provider.aiInsightHistory.length && i < 10;
                    i++) ...[
                  _AiHistoryTile(snapshot: provider.aiInsightHistory[i]),
                  if (i < provider.aiInsightHistory.length - 1 && i < 9)
                    Divider(height: 1, color: Colors.grey[100]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

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
    final resolvedType = entry?.type ?? type;
    // Voice and doodle entries get their own purpose-built sheets so the
    // generic text editor doesn't have to know about recording / drawing.
    if (resolvedType == JournalEntryType.voice_note) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _VoiceNoteSheet(
          provider: provider,
          existingEntry: entry,
        ),
      );
      return;
    }
    if (resolvedType == JournalEntryType.doodle) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DoodleSheet(
          provider: provider,
          existingEntry: entry,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JournalEditorSheet(
        provider: provider,
        existingEntry: entry,
        prefillTitle: entry?.title ?? prefillTitle,
        prefillContent: entry?.content ?? prefillContent,
        entryType: resolvedType,
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
              if (entry.content.trim().isNotEmpty)
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
              if (entry.type == JournalEntryType.voice_note &&
                  entry.mediaUrl != null)
                _VoiceNotePreview(
                  url: entry.mediaUrl!,
                  durationMs: entry.mediaDurationMs,
                ),
              if (entry.type == JournalEntryType.doodle &&
                  entry.mediaUrl != null)
                _DoodlePreview(url: entry.mediaUrl!),
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

// ─────────────────────────────────────────
//  Voice Note Sheet
// ─────────────────────────────────────────

class _VoiceNoteSheet extends StatefulWidget {
  final JournalingProvider provider;
  final JournalEntry? existingEntry;

  const _VoiceNoteSheet({required this.provider, this.existingEntry});

  @override
  State<_VoiceNoteSheet> createState() => _VoiceNoteSheetState();
}

class _VoiceNoteSheetState extends State<_VoiceNoteSheet> {
  static const _primary = Color(0xFF6366F1);

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  String? _localPath;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.existingEntry?.title.isNotEmpty == true
        ? widget.existingEntry!.title
        : 'Voice Note';
    _notesCtrl.text = widget.existingEntry?.content ?? '';
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    _player.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() => _error = null);
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      setState(() => _error = 'Microphone permission denied.');
      return;
    }
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      setState(() => _error = 'Microphone permission denied.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    setState(() {
      _localPath = path;
      _isRecording = true;
      _elapsed = Duration.zero;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _ticker?.cancel();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      if (path != null) _localPath = path;
    });
  }

  Future<void> _togglePlayback() async {
    if (_localPath == null && widget.existingEntry?.mediaUrl == null) return;
    if (_isPlaying) {
      await _player.pause();
      return;
    }
    if (_localPath != null) {
      await _player.play(DeviceFileSource(_localPath!));
    } else if (widget.existingEntry?.mediaUrl != null) {
      await _player.play(UrlSource(widget.existingEntry!.mediaUrl!));
    }
  }

  Future<void> _save() async {
    if (_localPath == null && widget.existingEntry?.mediaUrl == null) {
      setState(() => _error = 'Record something first.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      JournalEntry savedEntry;
      if (widget.existingEntry == null) {
        // Create the entry first to obtain its id, then upload + attach.
        final draft = JournalEntry(
          id: '',
          title: _titleCtrl.text.trim().isEmpty
              ? 'Voice Note'
              : _titleCtrl.text.trim(),
          content: _notesCtrl.text.trim(),
          timestamp: DateTime.now(),
          tags: const [],
          moods: const [],
          type: JournalEntryType.voice_note,
        );
        savedEntry = await widget.provider.createEntry(draft);
      } else {
        savedEntry = widget.existingEntry!;
      }

      if (_localPath != null) {
        final uploaded = await widget.provider.uploadVoiceNote(
          entryId: savedEntry.id,
          file: File(_localPath!),
        );
        await widget.provider.attachMedia(
          savedEntry.id,
          mediaUrl: uploaded.url,
          mediaPath: uploaded.path,
          mediaDurationMs: _elapsed.inMilliseconds,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not save voice note: $e';
          _saving = false;
        });
      }
    }
  }

  String _fmtElapsed(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text('Voice Note',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E1B4B))),
              const SizedBox(height: 4),
              Text(
                _isRecording
                    ? 'Recording…'
                    : (_localPath != null ||
                            widget.existingEntry?.mediaUrl != null)
                        ? 'Tap play to review, or save when ready.'
                        : 'Tap the mic to start recording.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isRecording
                                ? const [Color(0xFFEF4444), Color(0xFFF97316)]
                                : const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording
                                      ? const Color(0xFFEF4444)
                                      : _primary)
                                  .withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _fmtElapsed(_elapsed),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_localPath != null || widget.existingEntry?.mediaUrl != null)
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _togglePlayback,
                    icon: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 18),
                    label: Text(_isPlaying ? 'Pause' : 'Play back'),
                  ),
                ),
              const SizedBox(height: 24),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFFDC2626))),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save voice note'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Doodle Sheet
// ─────────────────────────────────────────

class _DoodleSheet extends StatefulWidget {
  final JournalingProvider provider;
  final JournalEntry? existingEntry;

  const _DoodleSheet({required this.provider, this.existingEntry});

  @override
  State<_DoodleSheet> createState() => _DoodleSheetState();
}

class _DoodleSheetState extends State<_DoodleSheet> {
  late final ScribbleNotifier _scribbleNotifier;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  static const _palette = [
    Color(0xFF1E1B4B),
    Color(0xFF6366F1),
    Color(0xFFF472B6),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF0EA5E9),
  ];

  static const _strokeWidths = [2.0, 4.0, 8.0, 14.0];

  @override
  void initState() {
    super.initState();
    _scribbleNotifier = ScribbleNotifier();
    _titleCtrl.text = widget.existingEntry?.title.isNotEmpty == true
        ? widget.existingEntry!.title
        : 'Doodle Entry';
    _notesCtrl.text = widget.existingEntry?.content ?? '';
  }

  @override
  void dispose() {
    _scribbleNotifier.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Render the scribble canvas to a PNG byte buffer.
      final image = await _scribbleNotifier.renderImage();
      final Uint8List bytes = image.buffer.asUint8List();

      JournalEntry savedEntry;
      if (widget.existingEntry == null) {
        final draft = JournalEntry(
          id: '',
          title: _titleCtrl.text.trim().isEmpty
              ? 'Doodle Entry'
              : _titleCtrl.text.trim(),
          content: _notesCtrl.text.trim(),
          timestamp: DateTime.now(),
          tags: const [],
          moods: const [],
          type: JournalEntryType.doodle,
        );
        savedEntry = await widget.provider.createEntry(draft);
      } else {
        savedEntry = widget.existingEntry!;
      }

      final uploaded = await widget.provider.uploadDoodle(
        entryId: savedEntry.id,
        bytes: bytes,
      );
      await widget.provider.attachMedia(
        savedEntry.id,
        mediaUrl: uploaded.url,
        mediaPath: uploaded.path,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not save doodle: $e';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text('Doodle',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E1B4B))),
                  ),
                  IconButton(
                    tooltip: 'Undo',
                    onPressed: _scribbleNotifier.undo,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  IconButton(
                    tooltip: 'Redo',
                    onPressed: _scribbleNotifier.redo,
                    icon: const Icon(Icons.redo_rounded),
                  ),
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: _scribbleNotifier.clear,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: const Color(0xFFF3F4F6),
                    child: Scribble(notifier: _scribbleNotifier),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final color in _palette)
                    GestureDetector(
                      onTap: () => _scribbleNotifier.setColor(color),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Eraser',
                    onPressed: _scribbleNotifier.setEraser,
                    icon: const Icon(Icons.cleaning_services_rounded,
                        size: 20),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Brush',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(width: 8),
                  for (final w in _strokeWidths)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () =>
                            _scribbleNotifier.setStrokeWidth(w),
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          child: Container(
                            width: w * 1.4,
                            height: w * 1.4,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E1B4B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFFDC2626))),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save doodle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Media preview widgets (used inside entry cards)
// ─────────────────────────────────────────

class _VoiceNotePreview extends StatefulWidget {
  final String url;
  final int? durationMs;
  const _VoiceNotePreview({required this.url, this.durationMs});

  @override
  State<_VoiceNotePreview> createState() => _VoiceNotePreviewState();
}

class _VoiceNotePreviewState extends State<_VoiceNotePreview> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final secs = (widget.durationMs ?? 0) ~/ 1000;
    final label = secs > 0
        ? '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}'
        : 'Voice note';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoodlePreview extends StatelessWidget {
  final String url;
  const _DoodlePreview({required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: url,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (ctx, _) => Container(
            height: 160,
            color: const Color(0xFFF3F4F6),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (ctx, _, __) => Container(
            height: 160,
            color: const Color(0xFFF3F4F6),
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final int count;

  const _DayHeader({required this.date, required this.count});

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'
  ];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return _weekdays[date.weekday - 1];
    return '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _label(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count == 1 ? '1 entry' : '$count entries',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiHistoryTile extends StatelessWidget {
  final AiInsightSnapshot snapshot;

  const _AiHistoryTile({required this.snapshot});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _fmtDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  @override
  Widget build(BuildContext context) {
    final preview = (snapshot.reflection ?? snapshot.moodSummary ?? '').trim();
    return InkWell(
      onTap: () => _openDetail(context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF6366F1), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmtDate(snapshot.generatedAt),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1B4B),
                    ),
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF), size: 20),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                _fmtDate(snapshot.generatedAt),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Week of ${_fmtDate(snapshot.weekStart)} – ${_fmtDate(snapshot.weekEnd)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 18),
              if ((snapshot.moodSummary ?? '').isNotEmpty) ...[
                Text(
                  snapshot.moodSummary!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1B4B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if ((snapshot.reflection ?? '').isNotEmpty) ...[
                Text(
                  snapshot.reflection!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF374151),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (snapshot.guidance.isNotEmpty) ...[
                Text(
                  'What might help',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                ...snapshot.guidance.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✦  ',
                              style: TextStyle(color: Color(0xFF6366F1))),
                          Expanded(
                            child: Text(
                              g,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.5,
                                color: const Color(0xFF374151),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],
              if (snapshot.topTopics.isNotEmpty) ...[
                Text(
                  'Top topics',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  snapshot.topTopics.join(', '),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
