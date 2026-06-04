/// Core enums and their stored string values.
///
/// Source of truth: Database Reference §9 "Allowed Values / Constraints" and
/// Rule Engine "Item Data Model". The `.value` strings MUST match the database
/// CHECK constraints exactly — they are what gets written to Supabase.
library;

/// Item category. Stored in `items.category`.
enum ItemCategory {
  top('TOP'),
  bottom('BOTTOM'),
  outerwear('OUTERWEAR'),
  footwear('FOOTWEAR'),
  others('OTHERS');

  const ItemCategory(this.value);
  final String value;

  static ItemCategory fromValue(String v) =>
      ItemCategory.values.firstWhere((e) => e.value == v);
}

/// Item lifecycle status. Stored in `items.status`.
enum ItemStatus {
  inWardrobe('IN_WARDROBE'),
  laundry('LAUNDRY'),
  lent('LENT'),
  stored('STORED'),
  donated('DONATED'),
  deleted('DELETED');

  const ItemStatus(this.value);
  final String value;

  static ItemStatus fromValue(String v) =>
      ItemStatus.values.firstWhere((e) => e.value == v);

  /// Available + wearable by the rule engine (passes F4).
  bool get isActive => this == ItemStatus.inWardrobe;

  /// Still "in the wardrobe" conceptually (shown in lists, donation scan)
  /// but not recommendable.
  bool get isVisibleInWardrobe =>
      this == ItemStatus.inWardrobe ||
      this == ItemStatus.laundry ||
      this == ItemStatus.lent ||
      this == ItemStatus.stored;
}

/// Occasion tags. Stored in `items.occasion_tags[]` and event/log occasion.
/// "Formal" was dropped from MVP (Rule Engine "Locked Occasions").
enum Occasion {
  casual('CASUAL'),
  work('WORK'),
  active('ACTIVE'),
  relax('RELAX');

  const Occasion(this.value);
  final String value;

  static Occasion fromValue(String v) =>
      Occasion.values.firstWhere((e) => e.value == v);
}

/// `item_events.event_type`.
enum EventType {
  worn('WORN'),
  skipped('SKIPPED');

  const EventType(this.value);
  final String value;

  static EventType fromValue(String v) =>
      EventType.values.firstWhere((e) => e.value == v);
}

/// `item_events.source`.
enum ItemEventSource {
  dailyRotation('DAILY_ROTATION'),
  outfitGenerator('OUTFIT_GENERATOR'),
  itemDetail('ITEM_DETAIL'),
  manual('MANUAL');

  const ItemEventSource(this.value);
  final String value;

  static ItemEventSource fromValue(String v) =>
      ItemEventSource.values.firstWhere((e) => e.value == v);
}

/// `outfit_logs.source`.
enum OutfitLogSource {
  outfitGenerator('OUTFIT_GENERATOR'),
  manual('MANUAL');

  const OutfitLogSource(this.value);
  final String value;

  static OutfitLogSource fromValue(String v) =>
      OutfitLogSource.values.firstWhere((e) => e.value == v);
}

/// `outfit_log_items.layer_type`. This is the outfit SLOT, not the item
/// category — FOOTWEAR items use layer_type SHOES (Database §7).
enum LayerType {
  top('TOP'),
  bottom('BOTTOM'),
  outerwear('OUTERWEAR'),
  shoes('SHOES');

  const LayerType(this.value);
  final String value;

  static LayerType fromValue(String v) =>
      LayerType.values.firstWhere((e) => e.value == v);

  /// Maps an outfit layer to the item category used for pool building.
  /// Rule Engine "Outfit layer to item category mapping".
  ItemCategory get itemCategory => switch (this) {
        LayerType.top => ItemCategory.top,
        LayerType.bottom => ItemCategory.bottom,
        LayerType.outerwear => ItemCategory.outerwear,
        LayerType.shoes => ItemCategory.footwear,
      };
}

/// `profiles.recommendation_mode`.
enum RecommendationMode {
  balanced('BALANCED'),
  pureRotation('PURE_ROTATION');

  const RecommendationMode(this.value);
  final String value;

  static RecommendationMode fromValue(String v) =>
      RecommendationMode.values.firstWhere((e) => e.value == v);
}

/// `items.condition_review_mode`.
enum ConditionReviewMode {
  auto('AUTO'),
  manual('MANUAL');

  const ConditionReviewMode(this.value);
  final String value;

  static ConditionReviewMode fromValue(String v) =>
      ConditionReviewMode.values.firstWhere((e) => e.value == v);
}

/// `items.initial_history_type`.
enum InitialHistoryType {
  brandNew('BRAND_NEW'),
  alreadyOwnedWorn('ALREADY_OWNED_WORN'),
  alreadyOwnedUnworn('ALREADY_OWNED_UNWORN');

  const InitialHistoryType(this.value);
  final String value;

  static InitialHistoryType fromValue(String v) =>
      InitialHistoryType.values.firstWhere((e) => e.value == v);
}

/// Clothing colour swatches for Style Preferences (Frontend §1 / locked #8/#9).
/// `.value` is the stored token (used in style_preferences + color_tags).
enum SwatchColour {
  black('black'),
  white('white'),
  grey('grey'),
  beige('beige'),
  navy('navy'),
  blue('blue'),
  red('red'),
  green('green'),
  brown('brown'),
  yellow('yellow'),
  pink('pink'),
  purple('purple');

  const SwatchColour(this.value);
  final String value;

  static SwatchColour fromValue(String v) =>
      SwatchColour.values.firstWhere((e) => e.value == v);
}

/// Condition label mapping (Rule Engine "Condition label mapping").
/// condition int 1–5 → display label.
String conditionLabel(int condition) => switch (condition) {
      5 => 'Excellent',
      4 => 'Good',
      3 => 'Fair',
      2 => 'Worn',
      1 => 'Damaged',
      _ => 'Unknown',
    };
