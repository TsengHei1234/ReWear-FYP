import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';

/// App info, version, and FYP context (FE §37).
class HelpAboutPage extends StatelessWidget {
  const HelpAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Help / About',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
        children: [
          // ── App identity ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'RW',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ReWear',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
              ],
            ),
          ),
          // ── About ─────────────────────────────────────────────────────────
          const _Section(
            label: 'ABOUT',
            children: [
              _InfoTile(
                icon: Icons.checkroom_outlined,
                title: 'What is ReWear?',
                body: 'ReWear is a smart wardrobe management app that helps you '
                    'rediscover, organise, and wear your clothes more intentionally. '
                    'Track outfit freshness, manage your laundry cycle, and get '
                    'personalised outfit suggestions.',
              ),
              _Divider(),
              _InfoTile(
                icon: Icons.school_outlined,
                title: 'Final Year Project',
                body: 'ReWear was built as a Final Year Project (2025/2026). '
                    'It showcases Flutter, Supabase, and a custom outfit scoring '
                    'engine designed to encourage sustainable fashion habits.',
              ),
            ],
          ),
          // ── Getting started ───────────────────────────────────────────────
          const _Section(
            label: 'GETTING STARTED',
            children: [
              _InfoTile(
                icon: Icons.add_circle_outline_rounded,
                title: 'Add items to your wardrobe',
                body: 'Tap + in the Wardrobe tab to photograph and catalogue your '
                    'clothes. Each item is tracked for freshness and wear frequency.',
              ),
              _Divider(),
              _InfoTile(
                icon: Icons.style_outlined,
                title: 'Generate outfit suggestions',
                body: 'Visit the Outfit tab and tap Build Outfit to get smart '
                    'outfit combinations based on freshness, colour compatibility, '
                    'and your style preferences.',
              ),
              _Divider(),
              _InfoTile(
                icon: Icons.local_laundry_service_outlined,
                title: 'Track laundry',
                body: 'Mark items as dirty after wearing. ReWear automatically '
                    'returns them to your wardrobe after your configured laundry cycle.',
              ),
            ],
          ),
          // ── App info ──────────────────────────────────────────────────────
          const _Section(
            label: 'APP INFO',
            children: [
              _KeyValueTile(label: 'Version', value: '1.0.0'),
              _Divider(),
              _KeyValueTile(label: 'Platform', value: 'Flutter 3.41'),
              _Divider(),
              _KeyValueTile(label: 'Backend', value: 'Supabase'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
                letterSpacing: 1.1),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border, width: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: c.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                      fontSize: 13, color: c.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueTile extends StatelessWidget {
  const _KeyValueTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c.textPrimary),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 0.5, thickness: 0.5, color: context.colors.border);
  }
}
