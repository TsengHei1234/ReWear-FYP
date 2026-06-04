import '../../core/constants/enums.dart';

/// A clothing item row from the `items` table (Database §4).
class Item {
  const Item({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.type,
    required this.colorTags,
    required this.occasionTags,
    required this.formalityLevel,
    required this.condition,
    required this.conditionReviewMode,
    required this.isFavorite,
    required this.status,
    required this.dateAdded,
    required this.isNewItem,
    required this.initialHistoryType,
    required this.initialUsageAgeDays,
    required this.wearCountUnknown,
    required this.lastWornUnknown,
    required this.wearCount,
    required this.skipCount,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
    this.conditionNextDrop,
    this.initialLastWornOption,
    this.initialWearCountOption,
    this.initialOwnedDurationOption,
    this.lastWornDate,
    this.laundryStartedAt,
    this.keptUntil,
    this.donatedAt,
  });

  final String id;
  final String userId;
  final String? imagePath;
  final String name;

  // Metadata
  final ItemCategory category;
  final String type;
  final List<String> colorTags;
  final List<Occasion> occasionTags;
  final int formalityLevel;
  final int condition;
  final ConditionReviewMode conditionReviewMode;
  final int? conditionNextDrop;
  final bool isFavorite;
  final ItemStatus status;

  // Initial history
  final DateTime dateAdded;
  final bool isNewItem;
  final InitialHistoryType initialHistoryType;
  final String? initialLastWornOption;
  final String? initialWearCountOption;
  final String? initialOwnedDurationOption;
  final int initialUsageAgeDays;
  final bool wearCountUnknown;
  final bool lastWornUnknown;

  // Rule-engine summary
  final int wearCount;
  final DateTime? lastWornDate;
  final int skipCount;

  // Status / donation
  final DateTime? laundryStartedAt;
  final DateTime? keptUntil;
  final DateTime? donatedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imagePath: json['image_path'] as String?,
      name: json['name'] as String,
      category: ItemCategory.fromValue(json['category'] as String),
      type: json['type'] as String,
      colorTags: _stringList(json['color_tags']),
      occasionTags: _stringList(json['occasion_tags'])
          .map(Occasion.fromValue)
          .toList(),
      formalityLevel: json['formality_level'] as int,
      condition: json['condition'] as int,
      conditionReviewMode: ConditionReviewMode.fromValue(
          json['condition_review_mode'] as String),
      conditionNextDrop: json['condition_next_drop'] as int?,
      isFavorite: json['is_favorite'] as bool,
      status: ItemStatus.fromValue(json['status'] as String),
      dateAdded: DateTime.parse(json['date_added'] as String),
      isNewItem: json['is_new_item'] as bool,
      initialHistoryType: InitialHistoryType.fromValue(
          json['initial_history_type'] as String),
      initialLastWornOption: json['initial_last_worn_option'] as String?,
      initialWearCountOption: json['initial_wear_count_option'] as String?,
      initialOwnedDurationOption:
          json['initial_owned_duration_option'] as String?,
      initialUsageAgeDays: json['initial_usage_age_days'] as int,
      wearCountUnknown: json['wear_count_unknown'] as bool,
      lastWornUnknown: json['last_worn_unknown'] as bool,
      wearCount: json['wear_count'] as int,
      lastWornDate: json['last_worn_date'] == null
          ? null
          : DateTime.parse(json['last_worn_date'] as String),
      skipCount: json['skip_count'] as int,
      laundryStartedAt: json['laundry_started_at'] == null
          ? null
          : DateTime.parse(json['laundry_started_at'] as String),
      keptUntil: json['kept_until'] == null
          ? null
          : DateTime.parse(json['kept_until'] as String),
      donatedAt: json['donated_at'] == null
          ? null
          : DateTime.parse(json['donated_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// For INSERT — omits id/user_id (server defaults) and audit timestamps.
  Map<String, dynamic> toInsertJson() => {
        if (imagePath != null) 'image_path': imagePath,
        'name': name,
        'category': category.value,
        'type': type,
        'color_tags': colorTags,
        'occasion_tags': occasionTags.map((o) => o.value).toList(),
        'formality_level': formalityLevel,
        'condition': condition,
        'condition_review_mode': conditionReviewMode.value,
        if (conditionNextDrop != null) 'condition_next_drop': conditionNextDrop,
        'is_favorite': isFavorite,
        'status': status.value,
        'date_added':
            '${dateAdded.year.toString().padLeft(4, '0')}-${dateAdded.month.toString().padLeft(2, '0')}-${dateAdded.day.toString().padLeft(2, '0')}',
        'is_new_item': isNewItem,
        'initial_history_type': initialHistoryType.value,
        if (initialLastWornOption != null)
          'initial_last_worn_option': initialLastWornOption,
        if (initialWearCountOption != null)
          'initial_wear_count_option': initialWearCountOption,
        if (initialOwnedDurationOption != null)
          'initial_owned_duration_option': initialOwnedDurationOption,
        'initial_usage_age_days': initialUsageAgeDays,
        'wear_count_unknown': wearCountUnknown,
        'last_worn_unknown': lastWornUnknown,
        'wear_count': wearCount,
        if (lastWornDate != null)
          'last_worn_date':
              '${lastWornDate!.year.toString().padLeft(4, '0')}-${lastWornDate!.month.toString().padLeft(2, '0')}-${lastWornDate!.day.toString().padLeft(2, '0')}',
        'skip_count': skipCount,
      };

  /// For UPDATE — only the fields the app mutates after creation.
  Map<String, dynamic> toUpdateJson() => {
        if (imagePath != null) 'image_path': imagePath,
        'name': name,
        'category': category.value,
        'type': type,
        'color_tags': colorTags,
        'occasion_tags': occasionTags.map((o) => o.value).toList(),
        'formality_level': formalityLevel,
        'condition': condition,
        'condition_review_mode': conditionReviewMode.value,
        'condition_next_drop': conditionNextDrop,
        'is_favorite': isFavorite,
        'status': status.value,
        'wear_count': wearCount,
        'last_worn_date': lastWornDate == null
            ? null
            : '${lastWornDate!.year.toString().padLeft(4, '0')}-${lastWornDate!.month.toString().padLeft(2, '0')}-${lastWornDate!.day.toString().padLeft(2, '0')}',
        'skip_count': skipCount,
        'wear_count_unknown': wearCountUnknown,
        'last_worn_unknown': lastWornUnknown,
        if (laundryStartedAt != null)
          'laundry_started_at':
              '${laundryStartedAt!.year.toString().padLeft(4, '0')}-${laundryStartedAt!.month.toString().padLeft(2, '0')}-${laundryStartedAt!.day.toString().padLeft(2, '0')}',
        if (keptUntil != null)
          'kept_until':
              '${keptUntil!.year.toString().padLeft(4, '0')}-${keptUntil!.month.toString().padLeft(2, '0')}-${keptUntil!.day.toString().padLeft(2, '0')}',
        if (donatedAt != null)
          'donated_at':
              '${donatedAt!.year.toString().padLeft(4, '0')}-${donatedAt!.month.toString().padLeft(2, '0')}-${donatedAt!.day.toString().padLeft(2, '0')}',
      };

  Item copyWith({
    String? imagePath,
    String? name,
    ItemCategory? category,
    String? type,
    List<String>? colorTags,
    List<Occasion>? occasionTags,
    int? formalityLevel,
    int? condition,
    ConditionReviewMode? conditionReviewMode,
    int? conditionNextDrop,
    bool? isFavorite,
    ItemStatus? status,
    bool? isNewItem,
    InitialHistoryType? initialHistoryType,
    int? initialUsageAgeDays,
    bool? wearCountUnknown,
    bool? lastWornUnknown,
    int? wearCount,
    DateTime? lastWornDate,
    int? skipCount,
    DateTime? laundryStartedAt,
    DateTime? keptUntil,
    DateTime? donatedAt,
  }) =>
      Item(
        id: id,
        userId: userId,
        imagePath: imagePath ?? this.imagePath,
        name: name ?? this.name,
        category: category ?? this.category,
        type: type ?? this.type,
        colorTags: colorTags ?? this.colorTags,
        occasionTags: occasionTags ?? this.occasionTags,
        formalityLevel: formalityLevel ?? this.formalityLevel,
        condition: condition ?? this.condition,
        conditionReviewMode: conditionReviewMode ?? this.conditionReviewMode,
        conditionNextDrop: conditionNextDrop ?? this.conditionNextDrop,
        isFavorite: isFavorite ?? this.isFavorite,
        status: status ?? this.status,
        dateAdded: dateAdded,
        isNewItem: isNewItem ?? this.isNewItem,
        initialHistoryType: initialHistoryType ?? this.initialHistoryType,
        initialLastWornOption: initialLastWornOption,
        initialWearCountOption: initialWearCountOption,
        initialOwnedDurationOption: initialOwnedDurationOption,
        initialUsageAgeDays: initialUsageAgeDays ?? this.initialUsageAgeDays,
        wearCountUnknown: wearCountUnknown ?? this.wearCountUnknown,
        lastWornUnknown: lastWornUnknown ?? this.lastWornUnknown,
        wearCount: wearCount ?? this.wearCount,
        lastWornDate: lastWornDate ?? this.lastWornDate,
        skipCount: skipCount ?? this.skipCount,
        laundryStartedAt: laundryStartedAt ?? this.laundryStartedAt,
        keptUntil: keptUntil ?? this.keptUntil,
        donatedAt: donatedAt ?? this.donatedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static List<String> _stringList(dynamic v) =>
      (v as List?)?.map((e) => e.toString()).toList() ?? const [];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Item && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
