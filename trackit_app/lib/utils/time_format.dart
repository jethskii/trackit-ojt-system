/// Returns a time-of-day appropriate greeting, e.g. "Good Morning".
String greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 18) return 'Good Afternoon';
  return 'Good Evening';
}

/// Formats a past [DateTime] as a short relative string (e.g. "2h ago").
String timeAgo(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);

  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}
