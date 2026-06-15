/// Per-notification toggle settings with defaults matching the FE spec:
/// N1/N2/N3/N5 default ON, N4/N6 default OFF.
class NotificationToggles {
  const NotificationToggles({
    this.n1 = true,
    this.n2 = true,
    this.n3 = true,
    this.n4 = false,
    this.n5 = true,
    this.n6 = false,
  });

  final bool n1; // Daily Reminder
  final bool n2; // Inactive Warning
  final bool n3; // Long-Unworn Alert
  final bool n4; // Donation Reminder
  final bool n5; // Weekly Summary
  final bool n6; // Condition Updates

  NotificationToggles copyWith({
    bool? n1,
    bool? n2,
    bool? n3,
    bool? n4,
    bool? n5,
    bool? n6,
  }) =>
      NotificationToggles(
        n1: n1 ?? this.n1,
        n2: n2 ?? this.n2,
        n3: n3 ?? this.n3,
        n4: n4 ?? this.n4,
        n5: n5 ?? this.n5,
        n6: n6 ?? this.n6,
      );
}

/// Which app-open notifications are eligible to fire this session.
/// N5 is excluded — it is a scheduled system notification managed separately.
class NotificationResult {
  const NotificationResult({
    this.n1 = false,
    this.n2 = false,
    this.n3 = false,
    this.n4 = false,
    this.n6 = false,
  });

  final bool n1;
  final bool n2;
  final bool n3;
  final bool n4;
  final bool n6;
}

/// Pure eligibility logic for app-open notifications N1–N4 and inline N6.
/// No Flutter, no plugins — fully unit-testable.
class NotificationEligibility {
  static const _throttleDays = 7;

  static NotificationResult evaluate({
    /// Whole calendar days since the last WORN event was logged.
    /// 0 = logged today or no events recorded.
    required int daysSinceLastLog,

    /// Count of items not worn in > 60 days (isLongUnused).
    required int longUnwornCount,

    /// Count of items that are donation candidates.
    required int donationCandidates,

    /// Whether the auto-condition engine detected a condition drop this call.
    required bool conditionDropped,

    /// Whether the item's condition_review_mode is AUTO.
    required bool isAutoConditionMode,

    required NotificationToggles toggles,
    DateTime? lastN3FiredAt,
    DateTime? lastN4FiredAt,
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();

    // N2 suppresses N1 when it fires; conditions are already mutually exclusive
    // (daysSince == 1 and daysSince >= 3 can't both be true), but the explicit
    // suppression guard preserves the intent from the spec.
    final n2 = toggles.n2 && daysSinceLastLog >= 3;
    final n1 = toggles.n1 && daysSinceLastLog == 1 && !n2;

    final n3 = toggles.n3 &&
        longUnwornCount > 0 &&
        _notThrottled(lastN3FiredAt, time);

    final n4 = toggles.n4 &&
        donationCandidates > 0 &&
        _notThrottled(lastN4FiredAt, time);

    // N6 is suppressed when conditionReviewMode == MANUAL — checkAutoConditionDrop
    // already returns the item unchanged in that case, so conditionDropped will be
    // false. The isAutoConditionMode guard is kept for clarity and test coverage.
    final n6 = toggles.n6 && conditionDropped && isAutoConditionMode;

    return NotificationResult(n1: n1, n2: n2, n3: n3, n4: n4, n6: n6);
  }

  static bool _notThrottled(DateTime? lastFiredAt, DateTime now) {
    if (lastFiredAt == null) return true;
    return now.difference(lastFiredAt).inDays > _throttleDays;
  }
}
