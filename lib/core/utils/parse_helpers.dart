/// Resilient, production-grade parser utility for Firestore & external JSON data.
/// Protects against unexpected type casts (e.g. String vs num, Timestamp vs DateTime,
/// `Map<dynamic, dynamic>` vs `Map<String, dynamic>`).
class ParseHelpers {
  /// Safely parse a double from num, String, or return defaultValue.
  static double parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim()) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Safely parse an int from num, String, or return defaultValue.
  static int parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value.trim()) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Safely parse a boolean from bool, num (0/1), or String ('true'/'false').
  static bool parseBool(dynamic value, [bool defaultValue = false]) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final s = value.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return defaultValue;
  }

  /// Safely parse a String from any dynamic object.
  static String parseString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// Safely parse a nullable String. Returns null if null or empty.
  static String? parseNullableString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isNotEmpty ? s : null;
  }

  /// Safely parse a list of strings from a List or a single String.
  static List<String> parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isNotEmpty ? [trimmed] : [];
    }
    return [];
  }

  /// Safely parse a DateTime from DateTime, Firestore Timestamp (.toDate()),
  /// epoch milliseconds (num), or ISO-8601 String.
  static DateTime parseDateTime(dynamic value, [DateTime? fallback]) {
    if (value == null) return fallback ?? DateTime.now();
    if (value is DateTime) return value;
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    try {
      final dynamic v = value;
      final res = v.toDate();
      if (res is DateTime) return res;
    } catch (_) {}
    return DateTime.tryParse(value.toString()) ?? (fallback ?? DateTime.now());
  }

  /// Safely parse a nullable DateTime. Returns null if missing or invalid.
  static DateTime? parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    try {
      final dynamic v = value;
      final res = v.toDate();
      if (res is DateTime) return res;
    } catch (_) {}
    return DateTime.tryParse(value.toString());
  }

  /// Safely convert any map (including `Map<dynamic, dynamic>`) to `Map<String, dynamic>`.
  static Map<String, dynamic> parseMap(dynamic value) {
    if (value == null || value is! Map) return {};
    return Map<String, dynamic>.from(value);
  }
}
