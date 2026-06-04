import '../../data/models/item.dart';

/// A user-facing outfit slot. SHOES holds a FOOTWEAR-category item
/// (RE "Outfit layer to item category mapping").
enum OutfitSlot { top, bottom, outerwear, shoes }

/// An assembled outfit. TOP + BOTTOM are required (P1a); OUTERWEAR + SHOES are
/// optional styling layers controlled by the Generator toggles.
class Outfit {
  const Outfit({
    required this.top,
    required this.bottom,
    this.outerwear,
    this.shoes,
  });

  final Item top;
  final Item bottom;
  final Item? outerwear;
  final Item? shoes;

  /// Present items, in layer order.
  List<Item> get items => [
        top,
        bottom,
        ?outerwear,
        ?shoes,
      ];

  List<String> get itemIds => items.map((i) => i.id).toList();

  Item? itemAt(OutfitSlot slot) => switch (slot) {
        OutfitSlot.top => top,
        OutfitSlot.bottom => bottom,
        OutfitSlot.outerwear => outerwear,
        OutfitSlot.shoes => shoes,
      };

  /// Which slots are filled (used by P1b to iterate candidates).
  List<OutfitSlot> get filledSlots => [
        OutfitSlot.top,
        OutfitSlot.bottom,
        if (outerwear != null) OutfitSlot.outerwear,
        if (shoes != null) OutfitSlot.shoes,
      ];

  /// Returns a copy with [item] placed in [slot].
  Outfit withSlot(OutfitSlot slot, Item item) => Outfit(
        top: slot == OutfitSlot.top ? item : top,
        bottom: slot == OutfitSlot.bottom ? item : bottom,
        outerwear: slot == OutfitSlot.outerwear ? item : outerwear,
        shoes: slot == OutfitSlot.shoes ? item : shoes,
      );
}
