import '../../core/constants/enums.dart';
import '../../data/models/item.dart';
import '../filters/layer1_filters.dart';
import '../scoring/frs.dart';
import 'outfit.dart';
import 'outfit_assembler.dart';

/// Outfit Generator — pure deterministic core (RE "Outfit Generator — Full
/// Behaviour", Steps 1–10 + T/B uniqueness + skip cascade). Pure Dart.
/// UI orchestration (loading, snackbars, Supabase sync) lives in Phase 6.

/// Item category for an outfit slot (RE "Outfit layer to item category mapping").
ItemCategory categoryForSlot(OutfitSlot slot) => switch (slot) {
      OutfitSlot.top => ItemCategory.top,
      OutfitSlot.bottom => ItemCategory.bottom,
      OutfitSlot.outerwear => ItemCategory.outerwear,
      OutfitSlot.shoes => ItemCategory.footwear,
    };

/// Generation inputs for a single Generate / skip pass.
class GeneratorConfig {
  const GeneratorConfig({
    this.occasion,
    this.requireOuterwear = false,
    this.requireShoes = false,
    this.pinnedItem,
    this.mode = RecommendationMode.pureRotation,
    this.preferredColours = const {},
    this.dislikedColours = const {},
    this.selectedTypes = const {},
    required this.now,
  });

  final Occasion? occasion;
  final bool requireOuterwear;
  final bool requireShoes;
  final Item? pinnedItem;
  final RecommendationMode mode;
  final Set<String> preferredColours;
  final Set<String> dislikedColours;

  /// Candidate Pool Type Filter (one storedValue per active category, or absent
  /// key = no filter). Applied inside poolFor before take(8).
  final Map<ItemCategory, String> selectedTypes;

  final DateTime now;
}

/// An outfit plus its computed scores (ranking + display).
class ScoredOutfit {
  const ScoredOutfit({
    required this.outfit,
    required this.score,
    required this.displayScore,
    required this.formality,
    required this.colourScore,
  });

  final Outfit outfit;
  final double score; // internal OutfitScore (uncapped)
  final int displayScore;
  final FormalityResult formality;
  final double colourScore;

  /// Canonical identity for excludedCombinations (order-independent).
  String get comboKey => (outfit.itemIds.toList()..sort()).join('|');
}

/// Result of a generation/skip pass.
class GenerationResult {
  const GenerationResult.success(this.outfits) : failureMessage = null;
  const GenerationResult.failure(this.failureMessage) : outfits = const [];

  final List<ScoredOutfit> outfits;
  final String? failureMessage;

  bool get ok => failureMessage == null;
}

/// Mutable session state for the Outfit Generator.
class GeneratorSession {
  final Set<String> excludedItems = {};
  final Set<String> excludedCombinations = {};
  final Set<String> shownTops = {};
  final Set<String> shownBottoms = {};
  bool initialGenerationDone = false;
  bool? useTbUniqueness;
  List<ScoredOutfit> currentOutfits = [];

  void clear() {
    excludedItems.clear();
    excludedCombinations.clear();
    shownTops.clear();
    shownBottoms.clear();
    initialGenerationDone = false;
    useTbUniqueness = null;
    currentOutfits = [];
  }

  /// Steps 1–10. Initial generation (and a no-op re-display if already done).
  GenerationResult generate(List<Item> wardrobe, GeneratorConfig cfg) {
    if (initialGenerationDone) {
      return GenerationResult.success(currentOutfits);
    }

    final built = _buildRanked(wardrobe, cfg);
    if (built.failureMessage != null) {
      return GenerationResult.failure(built.failureMessage);
    }

    final ranked = built.ranked;
    final selected = <ScoredOutfit>[];

    // Step 9 — T/B uniqueness only on initial generation.
    useTbUniqueness = built.topPoolSize >= 3 && built.bottomPoolSize >= 3;
    if (useTbUniqueness!) {
      for (final so in ranked) {
        if (selected.length == 3) break;
        final t = so.outfit.top.id;
        final b = so.outfit.bottom.id;
        if (shownTops.contains(t) || shownBottoms.contains(b)) continue;
        selected.add(so);
        shownTops.add(t);
        shownBottoms.add(b);
      }
      // Backfill ignoring uniqueness.
      if (selected.length < 3) {
        for (final so in ranked) {
          if (selected.length == 3) break;
          if (selected.contains(so)) continue;
          if (excludedCombinations.contains(so.comboKey)) continue;
          selected.add(so);
        }
      }
    } else {
      selected.addAll(ranked.take(3));
    }

    _commit(selected);
    initialGenerationDone = true;
    useTbUniqueness = false;
    return GenerationResult.success(selected);
  }

  /// Skip cascade + replacement (RE "Skip behaviour — outfit card replacement").
  GenerationResult skip(
    List<Item> wardrobe,
    GeneratorConfig cfg,
    Set<String> skippedItemIds,
  ) {
    // Cascade removal — drop every card containing any excluded item.
    excludedItems.addAll(skippedItemIds);
    final surviving = <ScoredOutfit>[];
    for (final so in currentOutfits) {
      final hit = so.outfit.itemIds.any(excludedItems.contains);
      if (hit) {
        excludedCombinations.remove(so.comboKey);
      } else {
        surviving.add(so);
      }
    }
    currentOutfits = surviving;

    // Replacement generation — refill up to 3, uniqueness off.
    final built = _buildRanked(wardrobe, cfg);
    if (built.failureMessage == null) {
      for (final so in built.ranked) {
        if (currentOutfits.length == 3) break;
        if (excludedCombinations.contains(so.comboKey)) continue;
        currentOutfits.add(so);
        excludedCombinations.add(so.comboKey);
      }
    }

    // After replacement, re-sort all displayed cards by OutfitScore descending
    // (RE "After replacement generation").
    currentOutfits.sort((a, b) => b.score.compareTo(a.score));
    return GenerationResult.success(currentOutfits);
  }

  // ── internal ──────────────────────────────────────────────────────────────

  void _commit(List<ScoredOutfit> selected) {
    currentOutfits = selected;
    for (final so in selected) {
      excludedCombinations.add(so.comboKey);
    }
  }

  _BuildResult _buildRanked(List<Item> wardrobe, GeneratorConfig cfg) {
    // Step 0 — pinned safety (F3/F4). Auto-unpin if unusable.
    var pinned = cfg.pinnedItem;
    if (pinned != null &&
        (pinned.condition == 1 || pinned.status != ItemStatus.inWardrobe)) {
      pinned = null;
    }

    // Step 1 — Layer 1 filters (incl. F5 worn-today via cfg.now).
    final filtered =
        applyLayer1Filters(wardrobe, occasion: cfg.occasion, now: cfg.now);
    if (filtered.isEmpty) {
      return _BuildResult.failure(filtered.message ?? 'No items available');
    }
    final pool = filtered.pool;

    // Step 2 — FRS per passing item.
    final frsById = <String, double>{};
    for (final item in pool) {
      final activeCount = _categoryActiveCount(wardrobe, item.category);
      frsById[item.id] = scoreItem(
        item,
        categoryActiveCount: activeCount,
        now: cfg.now,
        mode: cfg.mode,
        preferredColours: cfg.preferredColours,
        dislikedColours: cfg.dislikedColours,
      ).frs;
    }

    // Step 3 — candidate pools per layer (≤8, FRS desc, minus excluded).
    List<Item> poolFor(OutfitSlot slot) {
      final cat = categoryForSlot(slot);
      if (pinned != null && pinned.category == cat) {
        return [pinned];
      }
      var candidates = pool
          .where((i) => i.category == cat && !excludedItems.contains(i.id))
          .toList()
        ..sort((a, b) => (frsById[b.id] ?? 0).compareTo(frsById[a.id] ?? 0));
      // Step 0e — pinned formality pre-filter on other layers.
      if (pinned != null && pinned.category != cat) {
        candidates = candidates
            .where((i) =>
                (i.formalityLevel - pinned!.formalityLevel).abs() <= 1)
            .toList();
      }
      // Candidate Pool Type Filter — applied before take(8) so the cap doesn't
      // hide the filtered type when the unfiltered type is more numerous.
      final typeFilter = cfg.selectedTypes[cat];
      if (typeFilter != null) {
        candidates = candidates.where((i) => i.type == typeFilter).toList();
      }
      return candidates.take(8).toList();
    }

    final tops = poolFor(OutfitSlot.top);
    final bottoms = poolFor(OutfitSlot.bottom);
    final outerwear =
        cfg.requireOuterwear ? poolFor(OutfitSlot.outerwear) : const <Item>[];
    final shoes = cfg.requireShoes ? poolFor(OutfitSlot.shoes) : const <Item>[];

    // Candidate Pool Type Filter failure — if a type filter emptied a required
    // slot that otherwise had candidates, surface the filter-specific message
    // before the generic P1a message (and before the pinned formality message,
    // since the user explicitly set a filter and that is the most actionable hint).
    if (cfg.selectedTypes.isNotEmpty) {
      final slotsToCheck = [
        OutfitSlot.top,
        OutfitSlot.bottom,
        if (cfg.requireOuterwear) OutfitSlot.outerwear,
        if (cfg.requireShoes) OutfitSlot.shoes,
      ];
      final slotPools = {
        OutfitSlot.top: tops,
        OutfitSlot.bottom: bottoms,
        OutfitSlot.outerwear: outerwear,
        OutfitSlot.shoes: shoes,
      };
      for (final slot in slotsToCheck) {
        final cat = categoryForSlot(slot);
        if (!cfg.selectedTypes.containsKey(cat)) continue;
        if (slotPools[slot]!.isNotEmpty) continue;
        // Slot is empty AND has an active type filter.
        // Confirm raw candidates exist (i.e., filter — not Layer 1 — emptied it).
        final hasRaw = pool
            .any((i) => i.category == cat && !excludedItems.contains(i.id));
        if (hasRaw) {
          return _BuildResult.failure(
            'No items match your type filter. '
            'Try changing or clearing your filters.',
          );
        }
      }
    }

    // Step 0e failure — if the pinned formality pre-filter emptied a required
    // non-pinned layer that otherwise had candidates, surface the specific
    // pinned-formality message (before the generic P1a message).
    if (pinned != null) {
      final requiredSlots = [
        OutfitSlot.top,
        OutfitSlot.bottom,
        if (cfg.requireOuterwear) OutfitSlot.outerwear,
        if (cfg.requireShoes) OutfitSlot.shoes,
      ];
      final filteredBySlot = {
        OutfitSlot.top: tops,
        OutfitSlot.bottom: bottoms,
        OutfitSlot.outerwear: outerwear,
        OutfitSlot.shoes: shoes,
      };
      for (final slot in requiredSlots) {
        final cat = categoryForSlot(slot);
        if (cat == pinned.category) continue;
        final rawCandidates = pool.any(
            (i) => i.category == cat && !excludedItems.contains(i.id));
        if (rawCandidates && filteredBySlot[slot]!.isEmpty) {
          return _BuildResult.failure(
              "Cannot find items matching ${pinned.name}'s formality");
        }
      }
    }

    // Step 5 — P1a completeness pre-check.
    final check = canAssemble(
      tops: tops,
      bottoms: bottoms,
      outerwear: outerwear,
      shoes: shoes,
      requireOuterwear: cfg.requireOuterwear,
      requireShoes: cfg.requireShoes,
    );
    if (!check.ok) return _BuildResult.failure(check.message!);

    // Step 4 — generate valid unique combinations.
    final candidatesBySlot = <OutfitSlot, List<Item>>{
      OutfitSlot.top: tops,
      OutfitSlot.bottom: bottoms,
      if (cfg.requireOuterwear) OutfitSlot.outerwear: outerwear,
      if (cfg.requireShoes) OutfitSlot.shoes: shoes,
    };

    final outerOptions = cfg.requireOuterwear ? outerwear : <Item?>[null];
    final shoesOptions = cfg.requireShoes ? shoes : <Item?>[null];

    final scored = <ScoredOutfit>[];
    for (final t in tops) {
      for (final b in bottoms) {
        for (final o in outerOptions) {
          for (final s in shoesOptions) {
            final outfit = Outfit(top: t, bottom: b, outerwear: o, shoes: s);
            final ids = outfit.itemIds;
            // self-pairing guard.
            if (ids.toSet().length != ids.length) continue;
            if (ids.any(excludedItems.contains)) continue;

            // Step 6 — P1b formality.
            final pinnedSlot = pinned == null
                ? null
                : _slotOf(pinned, cfg);
            final formality = resolveFormality(
              outfit,
              candidatesBySlot: candidatesBySlot,
              pinnedSlot: pinnedSlot,
            );
            final finalOutfit = formality.outfit;
            final key = (finalOutfit.itemIds.toList()..sort()).join('|');
            if (excludedCombinations.contains(key)) continue;

            // Steps 7–8 — colour + OutfitScore.
            final colour = colourCompatibilityScore(finalOutfit);
            final score = outfitScore(finalOutfit, frsById: frsById);
            scored.add(ScoredOutfit(
              outfit: finalOutfit,
              score: score,
              displayScore: outfitScoreDisplay(score),
              formality: formality,
              colourScore: colour,
            ));
          }
        }
      }
    }

    // Step 9 — sort by OutfitScore descending. De-dup identical combos keeping
    // the higher score (P1b can collapse different combos onto the same tuple).
    scored.sort((a, b) => b.score.compareTo(a.score));
    final seen = <String>{};
    final ranked = <ScoredOutfit>[];
    for (final so in scored) {
      if (seen.add(so.comboKey)) ranked.add(so);
    }

    // P1c colour reject / low-colour-score fallback (RE "P1c Behaviour
    // thresholds"). normal = colourScore >= 0.40, clash = < 0.40. If there are
    // >=3 normal combinations, reject all clashes; otherwise allow the best
    // clashes (already score-ordered) to fill remaining slots. Both lists keep
    // their OutfitScore order.
    final normal = ranked.where((s) => s.colourScore >= 0.40).toList();
    final clash = ranked.where((s) => s.colourScore < 0.40).toList();
    final colourFiltered =
        normal.length >= 3 ? normal : [...normal, ...clash];

    return _BuildResult.success(
      colourFiltered,
      topPoolSize: tops.length,
      bottomPoolSize: bottoms.length,
    );
  }

  OutfitSlot? _slotOf(Item pinned, GeneratorConfig cfg) => switch (pinned.category) {
        ItemCategory.top => OutfitSlot.top,
        ItemCategory.bottom => OutfitSlot.bottom,
        ItemCategory.outerwear => OutfitSlot.outerwear,
        ItemCategory.footwear => OutfitSlot.shoes,
        ItemCategory.others => null,
      };

  int _categoryActiveCount(List<Item> wardrobe, ItemCategory category) =>
      wardrobe
          .where((i) =>
              i.category == category && i.status == ItemStatus.inWardrobe)
          .length;
}

class _BuildResult {
  _BuildResult.success(this.ranked,
      {this.topPoolSize = 0, this.bottomPoolSize = 0})
      : failureMessage = null;
  _BuildResult.failure(this.failureMessage)
      : ranked = const [],
        topPoolSize = 0,
        bottomPoolSize = 0;

  final List<ScoredOutfit> ranked;
  final String? failureMessage;
  final int topPoolSize;
  final int bottomPoolSize;
}
