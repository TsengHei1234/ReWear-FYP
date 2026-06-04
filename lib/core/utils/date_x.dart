// Date formatting helpers used across the app.

/// Returns a concise "time since" label for a worn date.
/// e.g. "Today", "2d ago", "3w ago", "5mo ago", "2yr ago", or "Never".
String lastWornLabel(DateTime? lastWornDate) {
  if (lastWornDate == null) return 'Never';
  final days = DateTime.now().difference(lastWornDate).inDays;
  if (days == 0) return 'Today';
  if (days < 7) return '${days}d ago';
  if (days < 30) return '${(days / 7).floor()}w ago';
  if (days < 365) return '${(days / 30).floor()}mo ago';
  return '${(days / 365).floor()}yr ago';
}

/// Days since a date (0 if today).
int daysSince(DateTime date) => DateTime.now().difference(date).inDays;
