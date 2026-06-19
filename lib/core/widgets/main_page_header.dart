import 'package:flutter/material.dart';

import '../theme/app_color_scheme.dart';
import 'profile_avatar.dart';

/// Shared top-bar for the 5 main tab pages (Home, Wardrobe, Outfit, Donate,
/// Insights). Locks the profile avatar to an identical top-right position on
/// every tab via a single consistent outer padding and CrossAxisAlignment.start.
///
/// With CrossAxisAlignment.start:
/// - Single-line pages: Row height == avatar height (36px), avatar sits at
///   padding-top (8px from SafeArea inner edge).
/// - Two-line pages (Wardrobe): Row height grows with the subtitle column, but
///   the avatar stays pinned at row-top — still 8px from SafeArea inner edge.
/// - Pages with an [action] widget: action height does not push the avatar down
///   because the avatar is always start-aligned, not centered.
class MainPageHeader extends StatelessWidget {
  const MainPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleBadge,
    this.action,
    required this.avatarSource,
  });

  /// Main page title (22pt / w700).
  final String title;

  /// Optional second line below the title, e.g. "16 items" on Wardrobe.
  final String? subtitle;

  /// Optional small widget rendered inline after the title text,
  /// e.g. the red donation-count pill on Donate.
  final Widget? titleBadge;

  /// Optional widget placed between the spacer and the avatar,
  /// e.g. the history icon on Outfit. May be any height — the Row's
  /// start-alignment means it will not shift the avatar downward.
  final Widget? action;

  /// Forwarded to [ProfileAvatarButton] (display name or email).
  final String? avatarSource;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      // Identical outer padding on every tab — this is the contract.
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        // start-alignment locks the avatar top to padding-top regardless of
        // whether a subtitle or tall action widget is present.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: title (+ optional inline badge) + optional subtitle ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    if (titleBadge != null) ...[
                      const SizedBox(width: 8),
                      titleBadge!,
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: c.textTertiary),
                  ),
              ],
            ),
            ),
          ),
          // ── Right: optional action + avatar ──
          if (action != null) ...[
            action!,
            const SizedBox(width: 8),
          ],
          ProfileAvatarButton(source: avatarSource),
        ],
      ),
    );
  }
}
