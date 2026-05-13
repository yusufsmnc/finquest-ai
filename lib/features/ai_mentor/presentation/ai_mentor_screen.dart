import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai_mentor_providers.dart';
import '../data/mentor_repository.dart';
import '../domain/mentor_message.dart';
import 'widgets/mentor_avatar.dart';
import 'widgets/mentor_insight_card.dart';
import 'widgets/mentor_next_step_card.dart';

class AiMentorScreen extends ConsumerStatefulWidget {
  const AiMentorScreen({super.key});

  @override
  ConsumerState<AiMentorScreen> createState() => _AiMentorScreenState();
}

class _AiMentorScreenState extends ConsumerState<AiMentorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final reduced = MediaQuery.of(context).disableAnimations;
        if (reduced) {
          _entryController.value = 1;
        } else {
          _entryController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mentorState = ref.watch(aiMentorProvider);
    final history = mentorState.messageHistory;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeIn,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _MentorAppBar(mood: mentorState.currentMood),
            SliverToBoxAdapter(
              child: _MentorHeroSection(
                mood: mentorState.currentMood,
                currentMessage: mentorState.currentMessage,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _CategoryInsightsSection(
                selectIndex: mentorState.messageSelectIndex,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            if (history.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _SectionHeader(title: 'Recent Insights')),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MentorInsightCard(message: history[i]),
                    ),
                    childCount: history.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
            const SliverToBoxAdapter(child: _SectionHeader(title: 'Next Steps')),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 40),
              sliver: SliverToBoxAdapter(child: MentorNextStepCard()),
            ),
          ],
        ),
      ),
    );
  }
}

class _MentorAppBar extends StatelessWidget {
  final MentorMood mood;

  const _MentorAppBar({required this.mood});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: true,
      leading: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Color(0xFF0F172A),
          size: 22,
        ),
      ),
      title: Row(
        children: [
          const Text(
            'AI Mentor',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 10),
          MentorMoodChip(mood: mood),
        ],
      ),
    );
  }
}

class _MentorHeroSection extends StatelessWidget {
  final MentorMood mood;
  final MentorMessage? currentMessage;

  const _MentorHeroSection({required this.mood, this.currentMessage});

  @override
  Widget build(BuildContext context) {
    final gradients = mood.gradient;
    final text = currentMessage?.text ??
        MentorRepository.pickMessage(MentorContext.idle, 0);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradients.first, gradients.last],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          MentorAvatar(mood: mood, size: 72, animate: true),
          const SizedBox(height: 16),
          const Text(
            'Your AI Mentor',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Supportive · Insightful · Always here',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote_rounded,
                    color: Colors.white.withValues(alpha: 0.7), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      text,
                      key: ValueKey(text),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.6,
                      ),
                    ),
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

class _CategoryInsightsSection extends StatelessWidget {
  final int selectIndex;

  const _CategoryInsightsSection({required this.selectIndex});

  @override
  Widget build(BuildContext context) {
    final categories = [
      (MentorContext.categoryInvesting, const Color(0xFF2563EB),
          Icons.trending_up_rounded, 'Investing'),
      (MentorContext.categoryBudgeting, const Color(0xFF059669),
          Icons.account_balance_wallet_rounded, 'Budgeting'),
      (MentorContext.categorySavings, const Color(0xFF0EA5E9),
          Icons.savings_rounded, 'Savings'),
      (MentorContext.categoryRisk, const Color(0xFFF59E0B),
          Icons.shield_rounded, 'Risk'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Category Insights',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final (ctx, color, icon, label) = categories[i];
              final text =
                  MentorRepository.pickMessage(ctx, selectIndex + i);
              return _CategoryInsightCard(
                color: color,
                icon: icon,
                label: label,
                text: text,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryInsightCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String text;

  const _CategoryInsightCard({
    required this.color,
    required this.icon,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Color(0xFF334155),
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}