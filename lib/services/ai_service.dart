import 'package:cloud_firestore/cloud_firestore.dart';

class AIService {
  static final _db = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>?> getAIConfig() async {
    try {
      final doc = await _db.collection('config').doc('ai_config').get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> aiConfigStream() {
    return _db.collection('config').doc('ai_config').snapshots();
  }
}
