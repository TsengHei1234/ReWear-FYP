import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/enums.dart';
import '../data/models/item.dart';
import '../data/models/profile.dart';
import '../engine/outfit/generator_session.dart';
import 'profile_providers.dart';
import 'wardrobe_providers.dart';

/// Immutable UI state for the Outfit Generator (RE "Outfit Generator — Full
/// Behaviour"). The pure session logic lives in [GeneratorSession]; this state
/// only exposes the user-facing filters + the current display.
class OutfitGeneratorState {
  const OutfitGeneratorState({
    this.occasion,
    this.requireOuterwear = false,
    this.requireShoes = false,
    this.pinnedItem,
    this.outfits = const [],
    this.isGenerating = false,
    this.failureMessage,
    this.hasGenerated = false,
    this.generatedOccasion,
  });

  /// Selected (possibly staged) occasion filter for the chips (null = none yet).
  final Occasion? occasion;

  /// The occasion the currently-shown [outfits] were generated with. The cards
  /// + Outfit Detail display THIS, not [occasion], so a staged occasion change
  /// (pinned session) doesn't relabel the existing cards until Regenerate (G1).
  final Occasion? generatedOccasion;

  /// Layer toggles — include outerwear / shoes slots.
  final bool requireOuterwear;
  final bool requireShoes;

  /// Item locked into its layer (from "Build Outfit"), or null.
  final Item? pinnedItem;

  /// Currently displayed scored outfits (≤3).
  final List<ScoredOutfit> outfits;

  /// Blocking loading state (generate / skip in flight).
  final bool isGenerating;

  /// Engine failure message (empty pool / P1a / pinned formality), or null.
  final String? failureMessage;

  /// True once an initial generation has produced a result this session.
  final bool hasGenerated;

  static const Object _unset = Object();

  OutfitGeneratorState copyWith({
    Object? occasion = _unset,
    bool? requireOuterwear,
    bool? requireShoes,
    Object? pinnedItem = _unset,
    List<ScoredOutfit>? outfits,
    bool? isGenerating,
    Object? failureMessage = _unset,
    bool? hasGenerated,
    Object? generatedOccasion = _unset,
  }) =>
      OutfitGeneratorState(
        occasion: occasion == _unset ? this.occasion : occasion as Occasion?,
        requireOuterwear: requireOuterwear ?? this.requireOuterwear,
        requireShoes: requireShoes ?? this.requireShoes,
        pinnedItem: pinnedItem == _unset ? this.pinnedItem : pinnedItem as Item?,
        outfits: outfits ?? this.outfits,
        isGenerating: isGenerating ?? this.isGenerating,
        failureMessage: failureMessage == _unset
            ? this.failureMessage
            : failureMessage as String?,
        hasGenerated: hasGenerated ?? this.hasGenerated,
        generatedOccasion: generatedOccasion == _unset
            ? this.generatedOccasion
            : generatedOccasion as Occasion?,
      );
}

/// Which Outfit sub-tab is selected: 0 = Daily Rotation, 1 = Outfit Generator.
/// Lives in a provider (not OutfitPage local state) so "Build Outfit" from the
/// Wardrobe / Item Detail branches can open straight onto the Generator.
final outfitTabIndexProvider =
    NotifierProvider<OutfitTabIndexNotifier, int>(OutfitTabIndexNotifier.new);

class OutfitTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

/// Drives [GeneratorSession] from the UI. Watches [wardrobeProvider]: any
/// wardrobe mutation clears the session (RE "Session cleared"), EXCEPT the
/// generator's own skip, which preserves it (RE "Session preserved").
final outfitGeneratorProvider =
    NotifierProvider<OutfitGeneratorNotifier, OutfitGeneratorState>(
        OutfitGeneratorNotifier.new);

class OutfitGeneratorNotifier extends Notifier<OutfitGeneratorState> {
  final GeneratorSession _session = GeneratorSession();

  /// One-shot guard: the next wardrobe refresh was caused by our own skip, so
  /// the session must survive it.
  bool _preserveSessionOnce = false;

  /// The config the current cards were generated with. Skip/replacement reuse
  /// THIS (not the live filters) so staged occasion/layer changes don't leak in
  /// before Regenerate (DECISIONS G1).
  GeneratorConfig? _activeConfig;

  @override
  OutfitGeneratorState build() {
    // listen (not watch) so this notifier instance — and its session — survive
    // wardrobe refreshes instead of being rebuilt from scratch.
    ref.listen<AsyncValue<List<Item>>>(wardrobeProvider, _onWardrobeChanged);
    return const OutfitGeneratorState();
  }

  // ── Wardrobe lifecycle ──────────────────────────────────────────────────

  void _onWardrobeChanged(
    AsyncValue<List<Item>>? previous,
    AsyncValue<List<Item>> next,
  ) {
    // React only to the SETTLED refresh. A refresh emits a refreshing
    // AsyncData (isLoading == true) before the final one; acting on both would
    // consume the preserve guard early and still reset the session.
    if (!next.hasValue || next.isLoading || next.hasError) return;
    if (_preserveSessionOnce) {
      _preserveSessionOnce = false;
      return;
    }
    // A real wardrobe mutation (add/edit/delete/donate/status/logWorn/
    // Daily-Rotation skip) resets the session AND clears the pin (DECISIONS G1).
    _clearSession(clearPin: true);
  }

  /// Clears the session + displayed result. Keeps the pin and filters unless
  /// [clearPin] is set. Filters are never touched here.
  void _clearSession({bool clearPin = false}) {
    _session.clear();
    _activeConfig = null;
    // pinnedItem omitted from copyWith → kept (sentinel default); passed null
    // → cleared.
    state = clearPin
        ? state.copyWith(
            outfits: const [],
            hasGenerated: false,
            isGenerating: false,
            failureMessage: null,
            pinnedItem: null,
            generatedOccasion: null,
          )
        : state.copyWith(
            outfits: const [],
            hasGenerated: false,
            isGenerating: false,
            failureMessage: null,
            generatedOccasion: null,
          );
  }

  // ── Filters — DUMB field updates (DECISIONS G1). The session is NOT reset
  // here; the tab orchestrates reset/regenerate (pinned = staged until
  // Regenerate; no-pin = confirm-then-regenerate). ──────────────────────────

  void setOccasion(Occasion? occasion) =>
      state = state.copyWith(occasion: occasion);

  void setRequireOuterwear(bool value) =>
      state = state.copyWith(requireOuterwear: value);

  void setRequireShoes(bool value) =>
      state = state.copyWith(requireShoes: value);

  /// Public "clear generated cards" — keeps the pin + filters, wipes the
  /// session/results so the button returns to "Generate Outfit". Used by the
  /// no-pin filter-change confirm (DECISIONS G1) — does NOT auto-generate.
  void clearGenerated() => _clearSession();

  // ── Pin — set/clear both reset the session (fresh context, DECISIONS G1) ──

  /// Pin [item] (or clear with null). Setting a pin also applies its
  /// constraints (DECISIONS G1): the occasion snaps to one the pin supports,
  /// and the pin's own optional layer (outerwear/shoes) is forced on.
  void setPinnedItem(Item? item) {
    _session.clear();
    _activeConfig = null;
    if (item == null) {
      state = state.copyWith(
        pinnedItem: null,
        outfits: const [],
        hasGenerated: false,
        isGenerating: false,
        failureMessage: null,
        generatedOccasion: null,
      );
      return;
    }
    final occasion =
        (state.occasion != null && item.occasionTags.contains(state.occasion))
            ? state.occasion
            : (item.occasionTags.isNotEmpty
                ? item.occasionTags.first
                : state.occasion);
    state = state.copyWith(
      pinnedItem: item,
      occasion: occasion,
      requireOuterwear:
          item.category == ItemCategory.outerwear ? true : state.requireOuterwear,
      requireShoes:
          item.category == ItemCategory.footwear ? true : state.requireShoes,
      outfits: const [],
      hasGenerated: false,
      isGenerating: false,
      failureMessage: null,
      generatedOccasion: null,
    );
  }

  void clearPin() => setPinnedItem(null);

  // ── Generation ──────────────────────────────────────────────────────────

  /// Initial generation (Steps 1–10). Re-displays the current result if a
  /// generation already happened this session.
  void generate() {
    final firstGen = !state.hasGenerated;
    final cfg = firstGen ? _config : (_activeConfig ?? _config);
    final result = _session.generate(_wardrobe, cfg);
    if (firstGen) _activeConfig = cfg; // lock the config the cards were made with
    state = state.copyWith(
      outfits: result.outfits,
      failureMessage: result.failureMessage,
      hasGenerated: true,
      isGenerating: false,
      generatedOccasion: cfg.occasion,
    );
  }

  /// "Clear and regenerate" — wipe the skip/shown history and run a fresh
  /// generation, KEEPING the pin + current filters (DECISIONS G1).
  void regenerate() {
    _clearSession();
    generate();
  }

  /// Skip item(s) from the generator (skip-item = 1, skip-outfit = N).
  /// Cascade-removes affected cards + refills, then syncs skip_count to
  /// Supabase. The session is preserved across the resulting wardrobe refresh.
  Future<void> skip(List<Item> skippedItems) async {
    if (skippedItems.isEmpty) return;
    state = state.copyWith(isGenerating: true);

    // Run the pure cascade/replacement against the current wardrobe first so
    // the displayed result is correct regardless of refresh timing. Use the
    // GENERATED config (not the live filters) so a staged occasion/layer change
    // doesn't leak into replacements before Regenerate (DECISIONS G1).
    final result = _session.skip(
      _wardrobe,
      _activeConfig ?? _config,
      skippedItems.map((i) => i.id).toSet(),
    );
    state = state.copyWith(outfits: result.outfits, isGenerating: false);

    // Persist skip_count; this refreshes the wardrobe once — preserve session.
    _preserveSessionOnce = true;
    await ref.read(wardrobeProvider.notifier).logSkippedItems(
          skippedItems,
          source: ItemEventSource.outfitGenerator,
        );
  }

  // ── internal ────────────────────────────────────────────────────────────

  List<Item> get _wardrobe =>
      ref.read(wardrobeProvider).asData?.value ?? const [];

  GeneratorConfig get _config {
    final Profile? profile = ref.read(profileProvider).asData?.value;
    return GeneratorConfig(
      occasion: state.occasion,
      requireOuterwear: state.requireOuterwear,
      requireShoes: state.requireShoes,
      pinnedItem: state.pinnedItem,
      mode: profile?.recommendationMode ?? RecommendationMode.balanced,
      preferredColours: profile?.preferredColours.toSet() ?? const {},
      dislikedColours: profile?.dislikedColours.toSet() ?? const {},
      now: DateTime.now(),
    );
  }
}
