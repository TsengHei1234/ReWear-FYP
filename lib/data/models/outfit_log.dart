import '../../core/constants/enums.dart';

/// A logged outfit row from `outfit_logs` (Database §5).
class OutfitLog {
  const OutfitLog({
    required this.id,
    required this.userId,
    required this.source,
    required this.loggedAt,
    this.occasion,
    this.outfitScore,
  });

  final String id;
  final String userId;
  final Occasion? occasion;
  final double? outfitScore;
  final OutfitLogSource source;
  final DateTime loggedAt;

  factory OutfitLog.fromJson(Map<String, dynamic> json) {
    return OutfitLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      occasion: json['occasion'] == null
          ? null
          : Occasion.fromValue(json['occasion'] as String),
      outfitScore: (json['outfit_score'] as num?)?.toDouble(),
      source: OutfitLogSource.fromValue(json['source'] as String),
      loggedAt: DateTime.parse(json['logged_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        if (occasion != null) 'occasion': occasion!.value,
        if (outfitScore != null) 'outfit_score': outfitScore,
        'source': source.value,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OutfitLog && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
