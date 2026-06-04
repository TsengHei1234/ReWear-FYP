import '../../core/constants/enums.dart';

/// A single item slot row from `outfit_log_items` (Database §7).
///
/// `layer_type` is the outfit SLOT, not the item category —
/// FOOTWEAR items use layer_type SHOES.
class OutfitLogItem {
  const OutfitLogItem({
    required this.id,
    required this.userId,
    required this.outfitLogId,
    required this.itemId,
    required this.layerType,
  });

  final String id;
  final String userId;
  final String outfitLogId;
  final String itemId;
  final LayerType layerType;

  factory OutfitLogItem.fromJson(Map<String, dynamic> json) {
    return OutfitLogItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      outfitLogId: json['outfit_log_id'] as String,
      itemId: json['item_id'] as String,
      layerType: LayerType.fromValue(json['layer_type'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'outfit_log_id': outfitLogId,
        'item_id': itemId,
        'layer_type': layerType.value,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OutfitLogItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
