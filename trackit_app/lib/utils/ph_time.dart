import 'package:intl/intl.dart';

/// Philippine Standard Time is a fixed UTC+8 offset with no daylight
/// saving, so unlike most timezones this never needs full IANA tzdata --
/// a constant offset is exact. Attendance clock-in/out must always be
/// shown in PHT, never the device's own timezone (see
/// server/utils/manilaTime.js for the backend half of this).
const Duration _phOffset = Duration(hours: 8);

/// Converts a real instant -- a UTC timestamp parsed from the server, or
/// a device-local `DateTime.now()` -- into Philippine wall-clock fields.
/// The result is only meaningful for *display* (via [DateFormat]) or for
/// reading its year/month/day as a PHT calendar date; it's not a real
/// instant anymore, so never diff it against another DateTime.
DateTime toPhTime(DateTime dateTime) => dateTime.toUtc().add(_phOffset);

/// The current moment, in Philippine wall-clock fields -- use this
/// instead of `DateTime.now()` anywhere "today" needs to match Philippine
/// Standard Time regardless of the device's own timezone (e.g. date
/// picker bounds).
DateTime nowInPh() => toPhTime(DateTime.now());

/// Formats a real instant as Philippine time using [pattern] (a
/// [DateFormat] pattern, e.g. 'MMM d, yyyy' or 'hh:mm a').
String formatPh(DateTime dateTime, String pattern) =>
    DateFormat(pattern).format(toPhTime(dateTime));
