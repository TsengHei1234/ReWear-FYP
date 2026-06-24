import 'enums.dart';

/// One entry in the Item Type Dictionary.
///
/// Source of truth: Rule Engine "Item Type Dictionary and Default Mapping".
/// The dictionary is app-code constants (NOT a database table). It drives:
/// valid types per category, default + allowed occasions, default formality,
/// and the AUTO condition-review threshold.
class ItemTypeDef {
  const ItemTypeDef({
    required this.storedValue,
    required this.displayLabel,
    required this.category,
    required this.defaultOccasions,
    required this.allowedOccasions,
    required this.defaultFormality,
    required this.conditionThreshold,
  });

  /// Stored in `items.type`. Unique per category (display labels may repeat).
  final String storedValue;
  final String displayLabel;
  final ItemCategory category;

  /// Auto-selected when this type is chosen on Add Item.
  final List<Occasion> defaultOccasions;

  /// The only occasions the user may toggle. Blocked occasions are never stored.
  final List<Occasion> allowedOccasions;

  /// 1–5. Not user-editable in MVP (auto-derived). See plan M4.
  final int defaultFormality;

  /// Wears between AUTO condition drops (lifetime / 4).
  final int conditionThreshold;
}

/// The full Item Type Dictionary, grouped by category.
class ItemTypeDictionary {
  ItemTypeDictionary._();

  /// Convenience: occasion list shorthands.
  static const _c = Occasion.casual;
  static const _w = Occasion.work;
  static const _a = Occasion.active;
  static const _r = Occasion.relax;

  /// All entries keyed by category, in the order they should appear in dropdowns.
  static const Map<ItemCategory, List<ItemTypeDef>> byCategory = {
    ItemCategory.top: _tops,
    ItemCategory.bottom: _bottoms,
    ItemCategory.outerwear: _outerwear,
    ItemCategory.footwear: _footwear,
    ItemCategory.others: _others,
  };

  /// Flat lookup by stored type value (unique across the whole dictionary).
  static ItemTypeDef? byStoredValue(String storedValue) {
    for (final list in byCategory.values) {
      for (final def in list) {
        if (def.storedValue == storedValue) return def;
      }
    }
    return null;
  }

  /// Types valid for a category (for Add/Edit dropdowns).
  static List<ItemTypeDef> forCategory(ItemCategory c) => byCategory[c] ?? const [];

  /// Validates that a stored type belongs to a category before save.
  static bool isValidForCategory(String storedValue, ItemCategory c) =>
      forCategory(c).any((d) => d.storedValue == storedValue);

  /// Condition threshold for a category/type. Footwear is type-specific
  /// (only SPORT_SHOES uses 50); all else is the type's stored threshold.
  static int conditionThreshold(String storedValue) =>
      byStoredValue(storedValue)?.conditionThreshold ?? 25;

  // ── TOP — threshold 28 ─────────────────────────────────────────
  static const _tops = <ItemTypeDef>[
    ItemTypeDef(storedValue: 'T_SHIRT', displayLabel: 'T-shirt', category: ItemCategory.top, defaultOccasions: [_c, _r], allowedOccasions: [_c, _r, _a], defaultFormality: 2, conditionThreshold: 28),
    ItemTypeDef(storedValue: 'SPORTS_T_SHIRT', displayLabel: 'Sports T-shirt / Active top', category: ItemCategory.top, defaultOccasions: [_a], allowedOccasions: [_a, _c, _r], defaultFormality: 1, conditionThreshold: 28),
    ItemTypeDef(storedValue: 'TANK_TOP_SINGLET', displayLabel: 'Tank top / Singlet', category: ItemCategory.top, defaultOccasions: [_r, _a], allowedOccasions: [_r, _a, _c], defaultFormality: 1, conditionThreshold: 28),
    ItemTypeDef(storedValue: 'LONG_SLEEVE_TOP', displayLabel: 'Long-sleeve top', category: ItemCategory.top, defaultOccasions: [_c, _r], allowedOccasions: [_c, _r], defaultFormality: 2, conditionThreshold: 28),
    ItemTypeDef(storedValue: 'POLO_SHIRT', displayLabel: 'Polo shirt', category: ItemCategory.top, defaultOccasions: [_c], allowedOccasions: [_c, _w], defaultFormality: 3, conditionThreshold: 28),
    ItemTypeDef(storedValue: 'CASUAL_BUTTON_UP_SHIRT', displayLabel: 'Casual button-up shirt', category: ItemCategory.top, defaultOccasions: [_c], allowedOccasions: [_c, _w], defaultFormality: 3, conditionThreshold: 28),
    ItemTypeDef(storedValue: 'DRESS_SHIRT', displayLabel: 'Dress shirt', category: ItemCategory.top, defaultOccasions: [_w], allowedOccasions: [_w], defaultFormality: 4, conditionThreshold: 28),
    ItemTypeDef(storedValue: 'BLOUSE', displayLabel: 'Blouse', category: ItemCategory.top, defaultOccasions: [_c, _w], allowedOccasions: [_c, _w], defaultFormality: 3, conditionThreshold: 28),
    ItemTypeDef(storedValue: 'TOP_HOODIE', displayLabel: 'Hoodie / Sweatshirt as top', category: ItemCategory.top, defaultOccasions: [_c, _r], allowedOccasions: [_c, _r], defaultFormality: 2, conditionThreshold: 28),
    ItemTypeDef(storedValue: 'SPORTS_BRA', displayLabel: 'Sports bra / Active bra', category: ItemCategory.top, defaultOccasions: [_a], allowedOccasions: [_a, _r], defaultFormality: 1, conditionThreshold: 28),
    ItemTypeDef(storedValue: 'CAMISOLE', displayLabel: 'Camisole / Cami top', category: ItemCategory.top, defaultOccasions: [_c, _r], allowedOccasions: [_c, _r], defaultFormality: 2, conditionThreshold: 28),
    ItemTypeDef(storedValue: 'CROP_TOP', displayLabel: 'Crop top', category: ItemCategory.top, defaultOccasions: [_c], allowedOccasions: [_c, _r], defaultFormality: 2, conditionThreshold: 28),
    ItemTypeDef(storedValue: 'OTHER_TOP', displayLabel: 'Other top', category: ItemCategory.top, defaultOccasions: [_c], allowedOccasions: [_c, _r, _a, _w], defaultFormality: 2, conditionThreshold: 28),
  ];

  // ── BOTTOM — threshold 58 ──────────────────────────────────────
  static const _bottoms = <ItemTypeDef>[
    ItemTypeDef(storedValue: 'JEANS', displayLabel: 'Jeans', category: ItemCategory.bottom, defaultOccasions: [_c], allowedOccasions: [_c, _w, _r], defaultFormality: 2, conditionThreshold: 58),
    ItemTypeDef(storedValue: 'CASUAL_SHORTS', displayLabel: 'Casual shorts', category: ItemCategory.bottom, defaultOccasions: [_c, _r], allowedOccasions: [_c, _r], defaultFormality: 2, conditionThreshold: 58),
    ItemTypeDef(storedValue: 'SPORT_SHORTS', displayLabel: 'Sport shorts', category: ItemCategory.bottom, defaultOccasions: [_a], allowedOccasions: [_a, _r], defaultFormality: 1, conditionThreshold: 58),
    ItemTypeDef(storedValue: 'JOGGERS_SWEATPANTS', displayLabel: 'Joggers / Sweatpants', category: ItemCategory.bottom, defaultOccasions: [_r], allowedOccasions: [_r, _c, _a], defaultFormality: 1, conditionThreshold: 58),
    ItemTypeDef(storedValue: 'CHINOS', displayLabel: 'Chinos', category: ItemCategory.bottom, defaultOccasions: [_c, _w], allowedOccasions: [_c, _w], defaultFormality: 3, conditionThreshold: 58),
    ItemTypeDef(storedValue: 'CASUAL_LONG_PANTS', displayLabel: 'Casual long pants', category: ItemCategory.bottom, defaultOccasions: [_c], allowedOccasions: [_c, _w], defaultFormality: 3, conditionThreshold: 58),
    ItemTypeDef(storedValue: 'FORMAL_TROUSERS_SLACKS', displayLabel: 'Formal trousers / Slacks', category: ItemCategory.bottom, defaultOccasions: [_w], allowedOccasions: [_w], defaultFormality: 4, conditionThreshold: 58),
    ItemTypeDef(storedValue: 'CASUAL_SKIRT', displayLabel: 'Casual skirt', category: ItemCategory.bottom, defaultOccasions: [_c], allowedOccasions: [_c, _r], defaultFormality: 2, conditionThreshold: 58),
    ItemTypeDef(storedValue: 'WORK_SKIRT', displayLabel: 'Work skirt', category: ItemCategory.bottom, defaultOccasions: [_w], allowedOccasions: [_w, _c], defaultFormality: 3, conditionThreshold: 58),
    ItemTypeDef(storedValue: 'DRESS_SKIRT', displayLabel: 'Dress skirt', category: ItemCategory.bottom, defaultOccasions: [_w], allowedOccasions: [_w], defaultFormality: 4, conditionThreshold: 58),
    ItemTypeDef(storedValue: 'LEGGINGS', displayLabel: 'Leggings', category: ItemCategory.bottom, defaultOccasions: [_a, _r], allowedOccasions: [_a, _r, _c], defaultFormality: 1, conditionThreshold: 58),
    ItemTypeDef(storedValue: 'OTHER_BOTTOM', displayLabel: 'Other bottom', category: ItemCategory.bottom, defaultOccasions: [_c], allowedOccasions: [_c, _r, _a, _w], defaultFormality: 2, conditionThreshold: 58),
  ];

  // ── OUTERWEAR — threshold 34 ───────────────────────────────────
  static const _outerwear = <ItemTypeDef>[
    ItemTypeDef(storedValue: 'OUTERWEAR_HOODIE', displayLabel: 'Hoodie / Sweatshirt as outerwear', category: ItemCategory.outerwear, defaultOccasions: [_c, _r], allowedOccasions: [_c, _r], defaultFormality: 2, conditionThreshold: 34),
    ItemTypeDef(storedValue: 'CARDIGAN', displayLabel: 'Cardigan', category: ItemCategory.outerwear, defaultOccasions: [_c, _w], allowedOccasions: [_c, _w, _r], defaultFormality: 3, conditionThreshold: 34),
    ItemTypeDef(storedValue: 'CASUAL_JACKET', displayLabel: 'Casual jacket', category: ItemCategory.outerwear, defaultOccasions: [_c], allowedOccasions: [_c, _w, _r], defaultFormality: 2, conditionThreshold: 34),
    ItemTypeDef(storedValue: 'DENIM_JACKET', displayLabel: 'Denim jacket', category: ItemCategory.outerwear, defaultOccasions: [_c], allowedOccasions: [_c, _r], defaultFormality: 2, conditionThreshold: 34),
    ItemTypeDef(storedValue: 'BOMBER_JACKET', displayLabel: 'Bomber jacket', category: ItemCategory.outerwear, defaultOccasions: [_c], allowedOccasions: [_c, _r], defaultFormality: 2, conditionThreshold: 34),
    ItemTypeDef(storedValue: 'BLAZER', displayLabel: 'Blazer', category: ItemCategory.outerwear, defaultOccasions: [_w], allowedOccasions: [_w, _c], defaultFormality: 4, conditionThreshold: 34),
    ItemTypeDef(storedValue: 'PARKA', displayLabel: 'Parka', category: ItemCategory.outerwear, defaultOccasions: [_c], allowedOccasions: [_c, _r], defaultFormality: 2, conditionThreshold: 34),
    ItemTypeDef(storedValue: 'CASUAL_COAT', displayLabel: 'Casual coat', category: ItemCategory.outerwear, defaultOccasions: [_c], allowedOccasions: [_c, _w], defaultFormality: 3, conditionThreshold: 34),
    ItemTypeDef(storedValue: 'FORMAL_COAT_OVERCOAT', displayLabel: 'Formal coat / Overcoat', category: ItemCategory.outerwear, defaultOccasions: [_w], allowedOccasions: [_w, _c], defaultFormality: 4, conditionThreshold: 34),
    ItemTypeDef(storedValue: 'RAIN_JACKET_WINDBREAKER', displayLabel: 'Rain jacket / Windbreaker', category: ItemCategory.outerwear, defaultOccasions: [_c], allowedOccasions: [_c, _a], defaultFormality: 2, conditionThreshold: 34),
    ItemTypeDef(storedValue: 'OVERSHIRT_SHIRT_JACKET', displayLabel: 'Overshirt / Shirt jacket', category: ItemCategory.outerwear, defaultOccasions: [_c], allowedOccasions: [_c, _r], defaultFormality: 2, conditionThreshold: 34),
    ItemTypeDef(storedValue: 'OTHER_OUTERWEAR', displayLabel: 'Other outerwear', category: ItemCategory.outerwear, defaultOccasions: [_c], allowedOccasions: [_c, _w, _r, _a], defaultFormality: 2, conditionThreshold: 34),
  ];

  // ── FOOTWEAR — threshold 25, except SPORT_SHOES 50 ─────────────
  static const _footwear = <ItemTypeDef>[
    ItemTypeDef(storedValue: 'SPORT_SHOES', displayLabel: 'Sport shoes', category: ItemCategory.footwear, defaultOccasions: [_a], allowedOccasions: [_a, _c], defaultFormality: 2, conditionThreshold: 50),
    ItemTypeDef(storedValue: 'CASUAL_SNEAKERS', displayLabel: 'Casual sneakers', category: ItemCategory.footwear, defaultOccasions: [_c], allowedOccasions: [_c, _r, _w], defaultFormality: 2, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'SLIP_ON_SHOES', displayLabel: 'Slip-on shoes', category: ItemCategory.footwear, defaultOccasions: [_c, _r], allowedOccasions: [_c, _r], defaultFormality: 2, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'LOAFERS', displayLabel: 'Loafers', category: ItemCategory.footwear, defaultOccasions: [_c, _w], allowedOccasions: [_c, _w], defaultFormality: 3, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'SANDALS', displayLabel: 'Sandals', category: ItemCategory.footwear, defaultOccasions: [_c, _r], allowedOccasions: [_c, _r], defaultFormality: 2, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'SLIPPERS_FLIP_FLOPS', displayLabel: 'Slippers / Flip-flops', category: ItemCategory.footwear, defaultOccasions: [_r], allowedOccasions: [_r, _c], defaultFormality: 1, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'CASUAL_BOOTS', displayLabel: 'Casual boots', category: ItemCategory.footwear, defaultOccasions: [_c], allowedOccasions: [_c, _w], defaultFormality: 3, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'FORMAL_SHOES', displayLabel: 'Formal shoes', category: ItemCategory.footwear, defaultOccasions: [_w], allowedOccasions: [_w], defaultFormality: 4, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'BALLET_FLATS', displayLabel: 'Flats / Ballet flats', category: ItemCategory.footwear, defaultOccasions: [_c, _w], allowedOccasions: [_c, _w], defaultFormality: 3, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'HEELS', displayLabel: 'Heels', category: ItemCategory.footwear, defaultOccasions: [_w], allowedOccasions: [_w, _c], defaultFormality: 4, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'OTHER_SHOES', displayLabel: 'Other shoes', category: ItemCategory.footwear, defaultOccasions: [_c], allowedOccasions: [_c, _w, _a, _r], defaultFormality: 2, conditionThreshold: 25),
  ];

  // ── OTHERS — threshold 25 (excluded from rotation/generator) ───
  static const _others = <ItemTypeDef>[
    ItemTypeDef(storedValue: 'ACCESSORY', displayLabel: 'Accessory', category: ItemCategory.others, defaultOccasions: [_c], allowedOccasions: [_c, _w, _a, _r], defaultFormality: 2, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'BAG', displayLabel: 'Bag', category: ItemCategory.others, defaultOccasions: [_c], allowedOccasions: [_c, _w, _a, _r], defaultFormality: 2, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'BELT', displayLabel: 'Belt', category: ItemCategory.others, defaultOccasions: [_c, _w], allowedOccasions: [_c, _w], defaultFormality: 3, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'HAT_CAP', displayLabel: 'Hat / Cap', category: ItemCategory.others, defaultOccasions: [_c], allowedOccasions: [_c, _a, _r], defaultFormality: 2, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'SCARF', displayLabel: 'Scarf', category: ItemCategory.others, defaultOccasions: [_c], allowedOccasions: [_c, _w, _r], defaultFormality: 3, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'TIE', displayLabel: 'Tie', category: ItemCategory.others, defaultOccasions: [_w], allowedOccasions: [_w], defaultFormality: 4, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'RING_JEWELLERY', displayLabel: 'Ring / Jewellery', category: ItemCategory.others, defaultOccasions: [_c], allowedOccasions: [_c, _w, _r], defaultFormality: 3, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'WATCH', displayLabel: 'Watch', category: ItemCategory.others, defaultOccasions: [_c, _w], allowedOccasions: [_c, _w, _a, _r], defaultFormality: 3, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'SUNGLASSES', displayLabel: 'Sunglasses', category: ItemCategory.others, defaultOccasions: [_c], allowedOccasions: [_c, _a, _r], defaultFormality: 2, conditionThreshold: 25),
    ItemTypeDef(storedValue: 'OTHER_ITEM', displayLabel: 'Other item', category: ItemCategory.others, defaultOccasions: [_c], allowedOccasions: [_c, _w, _a, _r], defaultFormality: 2, conditionThreshold: 25),
  ];
}
