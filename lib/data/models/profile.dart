import '../../core/constants/enums.dart';

/// A user's app settings row (`profiles` table).
///
/// Source of truth: Database Reference §3. `id` == auth.users.id.
class Profile {
  const Profile({
    required this.id,
    this.email,
    this.displayName,
    this.preferredColours = const [],
    this.dislikedColours = const [],
    this.laundryCycleDays = 3,
    this.recommendationMode = RecommendationMode.balanced,
  });

  final String id;
  final String? email;
  final String? displayName;

  /// From `style_preferences` jsonb → preferred_colours[].
  final List<String> preferredColours;

  /// From `style_preferences` jsonb → disliked_colours[].
  final List<String> dislikedColours;

  final int laundryCycleDays;
  final RecommendationMode recommendationMode;

  factory Profile.fromJson(Map<String, dynamic> json) {
    final style = (json['style_preferences'] as Map<String, dynamic>?) ?? const {};
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      preferredColours: _stringList(style['preferred_colours']),
      dislikedColours: _stringList(style['disliked_colours']),
      laundryCycleDays: (json['laundry_cycle_days'] as int?) ?? 3,
      recommendationMode: RecommendationMode.fromValue(
        (json['recommendation_mode'] as String?) ?? 'BALANCED',
      ),
    );
  }

  /// Only the columns the app updates (id is the PK key, not updated here).
  Map<String, dynamic> toUpdateJson() => {
        if (displayName != null) 'display_name': displayName,
        'style_preferences': {
          'preferred_colours': preferredColours,
          'disliked_colours': dislikedColours,
        },
        'laundry_cycle_days': laundryCycleDays,
        'recommendation_mode': recommendationMode.value,
      };

  Profile copyWith({
    String? email,
    String? displayName,
    List<String>? preferredColours,
    List<String>? dislikedColours,
    int? laundryCycleDays,
    RecommendationMode? recommendationMode,
  }) =>
      Profile(
        id: id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        preferredColours: preferredColours ?? this.preferredColours,
        dislikedColours: dislikedColours ?? this.dislikedColours,
        laundryCycleDays: laundryCycleDays ?? this.laundryCycleDays,
        recommendationMode: recommendationMode ?? this.recommendationMode,
      );

  static List<String> _stringList(dynamic v) =>
      (v as List?)?.map((e) => e.toString()).toList() ?? const [];
}
