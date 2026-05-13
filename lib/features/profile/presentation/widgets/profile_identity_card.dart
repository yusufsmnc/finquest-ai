import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/avatar_data.dart';
import '../../profile_providers.dart';
import '../../../dashboard/dashboard_providers.dart';
import '../../../gamification/gamification_providers.dart';
import '../../../achievements/achievements_providers.dart';
import '../../../scenarios/scenario_providers.dart';
import 'avatar_picker_modal.dart';

class ProfileIdentityCard extends ConsumerWidget {
  const ProfileIdentityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileNotifierProvider);
    final dashboard = ref.watch(dashboardNotifierProvider);
    final unlockedCount = ref.watch(
      achievementsNotifierProvider.select((s) => s.unlockedCount),
    );
    final totalDecisions = ref.watch(
      scenarioNotifierProvider.select((s) => s.totalDecisions),
    );

    final totalXp =
        ref.watch(gamificationOverlayProvider.select((s) => s.trackedXp));
    final avatar = AvatarData.options[profile.avatarIndex];
    final level = dashboard.currentLevel;
    final tierLabel = _tierLabel(level);
    final tierColor = _tierColor(level);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _AvatarBubble(avatar: avatar, onTap: () => AvatarPickerModal.show(context)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EditableName(
                      name: profile.displayName,
                      onSave: (v) => ref.read(profileNotifierProvider.notifier).setDisplayName(v),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tierColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        tierLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tierColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      avatar.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              _LevelBadge(level: level, color: tierColor),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                icon: Icons.star_rounded,
                label: 'XP',
                value: '$totalXp',
                color: const Color(0xFFF59E0B),
              ),
              _StatChip(
                icon: Icons.emoji_events_rounded,
                label: 'Badges',
                value: '$unlockedCount',
                color: const Color(0xFF7C3AED),
              ),
              _StatChip(
                icon: Icons.psychology_rounded,
                label: 'Decisions',
                value: '$totalDecisions',
                color: const Color(0xFF0EA5E9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _tierLabel(int level) {
    if (level >= 10) return 'ELITE INVESTOR';
    if (level >= 7) return 'SENIOR ANALYST';
    if (level >= 5) return 'RISING STAR';
    if (level >= 3) return 'APPRENTICE';
    return 'NOVICE';
  }

  Color _tierColor(int level) {
    if (level >= 10) return const Color(0xFFF59E0B);
    if (level >= 7) return const Color(0xFF7C3AED);
    if (level >= 5) return const Color(0xFF2563EB);
    if (level >= 3) return const Color(0xFF0EA5E9);
    return const Color(0xFF64748B);
  }
}

class _AvatarBubble extends StatelessWidget {
  final AvatarOption avatar;
  final VoidCallback onTap;

  const _AvatarBubble({required this.avatar, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [avatar.primary, avatar.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Icon(avatar.icon, color: Colors.white, size: 32),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0F172A), width: 2),
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableName extends StatefulWidget {
  final String name;
  final ValueChanged<String> onSave;

  const _EditableName({required this.name, required this.onSave});

  @override
  State<_EditableName> createState() => _EditableNameState();
}

class _EditableNameState extends State<_EditableName> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.name);
  }

  @override
  void didUpdateWidget(_EditableName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.name != widget.name) {
      _ctrl.text = widget.name;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return SizedBox(
        height: 32,
        child: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 4),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38),
            ),
          ),
          onSubmitted: (v) {
            widget.onSave(v);
            setState(() => _editing = false);
          },
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _editing = true),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.edit_rounded, size: 13, color: Colors.white38),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final Color color;

  const _LevelBadge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        color: color.withValues(alpha: 0.12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'LVL',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            '$level',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}