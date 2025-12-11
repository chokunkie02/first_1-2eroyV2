import 'package:shared_preferences/shared_preferences.dart';

class ScanHistoryService {
  static const String _prefix = 'scan_history_';

  /// Returns the cutoff date for scanning images.
  /// If never scanned, returns DateTime.now() - 30 days.
  /// Otherwise, returns the last scan time.
  Future<DateTime> getCutoffDate(String albumId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$albumId';
    final lastScanMillis = prefs.getInt(key);

    if (lastScanMillis != null) {
      return DateTime.fromMillisecondsSinceEpoch(lastScanMillis);
    } else {
      // Default: 30 days ago
      return DateTime.now().subtract(const Duration(days: 30));
    }
  }

  /// Updates the last scan time for a specific album to Now.
  Future<void> updateLastScanTime(String albumId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$albumId';
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<String>> getSelectedAlbumIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${_prefix}selected_albums') ?? [];
  }

  Future<void> saveSelectedAlbumIds(List<String> albumIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${_prefix}selected_albums', albumIds);
  }

  Future<Set<String>> getScannedFileIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('${_prefix}scanned_files') ?? [];
    return list.toSet();
  }

  Future<void> addScannedFileId(String fileId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_prefix}scanned_files';
    final list = prefs.getStringList(key) ?? [];
    if (!list.contains(fileId)) {
      list.add(fileId);
      await prefs.setStringList(key, list);
    }
  }
  
  Future<void> addScannedFileIds(List<String> fileIds) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_prefix}scanned_files';
    final list = prefs.getStringList(key) ?? [];
    bool changed = false;
    for (final id in fileIds) {
      if (!list.contains(id)) {
        list.add(id);
        changed = true;
      }
    }
    if (changed) {
      await prefs.setStringList(key, list);
    }
  }
}
