import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/settings_model.dart';

/// Service to read/write store settings from Firestore.
class SettingsService {
  static const String _collection = 'settings';
  static const String _docId = 'store_config';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch the store settings document.
  Future<StoreSettings> getSettings() async {
    try {
      final doc = await _db.collection(_collection).doc(_docId).get();
      if (doc.exists && doc.data() != null) {
        return StoreSettings.fromMap(doc.data()!);
      }
      return const StoreSettings(); // return defaults
    } catch (e) {
      return const StoreSettings();
    }
  }

  /// Save (upsert) the store settings document.
  Future<void> saveSettings(StoreSettings settings) async {
    await _db.collection(_collection).doc(_docId).set(
      {
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
