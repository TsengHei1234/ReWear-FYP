import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps [FlutterLocalNotificationsPlugin] for all ReWear notifications.
///
/// Call [initialize] once in main() before runApp(). After that, fire
/// notifications directly via the named show* / schedule* methods.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _channelId = 'rewear_notifications';
  static const _channelName = 'ReWear Notifications';

  static const _idN1 = 1;
  static const _idN2 = 2;
  static const _idN3 = 3;
  static const _idN4 = 4;
  static const _idN5 = 5;
  static const _idN6 = 6;

  static const _kLastN3 = 'notif_last_n3';
  static const _kLastN4 = 'notif_last_n4';

  final _plugin = FlutterLocalNotificationsPlugin();

  /// True after [initialize] completes. Guards notification calls in tests
  /// where the plugin and SharedPreferences are not set up.
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize({void Function(String? payload)? onTap}) async {
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) =>
          onTap?.call(details.payload),
    );

    // Create the Android notification channel.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Wardrobe reminders and weekly summaries',
            importance: Importance.defaultImportance,
          ),
        );

    // Request Android 13+ POST_NOTIFICATIONS permission.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  // ── App-open notifications ───────────────────────────────────────────────

  Future<void> showN1() => _show(
        id: _idN1,
        title: 'Daily wardrobe check-in',
        body: 'Did you wear something yesterday? Log it to keep your wardrobe history updated.',
        payload: 'wardrobe',
      );

  Future<void> showN2() => _show(
        id: _idN2,
        title: 'Outfit logging streak broken',
        body: "You haven't logged an outfit in a few days. Keep your history updated.",
        payload: 'wardrobe',
      );

  Future<void> showN3(int count) => _show(
        id: _idN3,
        title: 'Long-unworn items',
        body:
            '$count item${count == 1 ? '' : 's'} not worn in a while. Review your wardrobe rotation.',
      );

  Future<void> showN4(int count) => _show(
        id: _idN4,
        title: 'Donation candidates',
        body: '$count item${count == 1 ? '' : 's'} listed for donation review.',
        payload: 'donate',
      );

  Future<void> showN6(String itemId, String itemName, String conditionLabel) =>
      _show(
        id: _idN6,
        title: 'Condition update',
        body: '$itemName is now in $conditionLabel condition. Tap to review.',
        payload: 'item:$itemId',
      );

  // ── N5 — Weekly Wardrobe Summary (scheduled) ────────────────────────────

  /// Cancels any pending N5 then schedules the next one for Sunday at 20:00
  /// local time. Called each time the wardrobe loads, ensuring the body text
  /// uses fresh stats. If [totalItems] is 0 the summary is suppressed.
  Future<void> scheduleN5Weekly({
    required int wornInLast30,
    required int dormant,
    required int forDonationReview,
    required int totalItems,
  }) async {
    await _plugin.cancel(id: _idN5);
    if (totalItems == 0) return;

    final body =
        '$wornInLast30 worn in the last 30 days · $dormant dormant · $forDonationReview for donation review';

    await _plugin.zonedSchedule(
      id: _idN5,
      title: 'Weekly Wardrobe Summary',
      body: body,
      scheduledDate: _nextSunday20(),
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // No matchDateTimeComponents — one-shot so the body stays fresh.
      // WardrobeNotifier.build() reschedules on each app open.
    );
  }

  Future<void> cancelN5() => _plugin.cancel(id: _idN5);

  // ── Throttle timestamps ──────────────────────────────────────────────────

  Future<DateTime?> getLastN3FiredAt() => _getTimestamp(_kLastN3);
  Future<DateTime?> getLastN4FiredAt() => _getTimestamp(_kLastN4);
  Future<void> recordN3Fired() => _saveTimestamp(_kLastN3);
  Future<void> recordN4Fired() => _saveTimestamp(_kLastN4);

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details(),
      payload: payload,
    );
  }

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        ),
      );

  /// Returns a [tz.TZDateTime] for the next Sunday at 20:00 local time.
  tz.TZDateTime _nextSunday20() {
    var candidate = tz.TZDateTime.now(tz.local);
    do {
      candidate = candidate.add(const Duration(days: 1));
    } while (candidate.weekday != DateTime.sunday);
    return tz.TZDateTime(
        tz.local, candidate.year, candidate.month, candidate.day, 20);
  }

  Future<DateTime?> _getTimestamp(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> _saveTimestamp(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }
}
