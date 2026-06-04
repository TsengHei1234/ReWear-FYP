import '../../core/constants/enums.dart';

/// A single WORN / SKIPPED event row from `item_events` (Database §6).
class ItemEvent {
  const ItemEvent({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.eventType,
    required this.source,
    required this.eventAt,
    this.occasion,
    this.outfitLogId,
  });

  final String id;
  final String userId;
  final String itemId;
  final EventType eventType;
  final ItemEventSource source;
  final Occasion? occasion;
  final String? outfitLogId;
  final DateTime eventAt;

  factory ItemEvent.fromJson(Map<String, dynamic> json) {
    return ItemEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      itemId: json['item_id'] as String,
      eventType: EventType.fromValue(json['event_type'] as String),
      source: ItemEventSource.fromValue(json['source'] as String),
      occasion: json['occasion'] == null
          ? null
          : Occasion.fromValue(json['occasion'] as String),
      outfitLogId: json['outfit_log_id'] as String?,
      eventAt: DateTime.parse(json['event_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'item_id': itemId,
        'event_type': eventType.value,
        'source': source.value,
        if (occasion != null) 'occasion': occasion!.value,
        if (outfitLogId != null) 'outfit_log_id': outfitLogId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ItemEvent && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
