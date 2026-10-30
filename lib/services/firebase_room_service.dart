import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseRoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _participants(String roomCode) =>
      _firestore.collection('lobbies').doc(roomCode).collection('participants');

  CollectionReference<Map<String, dynamic>> _events(String roomCode) =>
      _firestore.collection('lobbies').doc(roomCode).collection('events');

  Stream<List<Map<String, dynamic>>> watchParticipants(String roomCode) {
    return _participants(roomCode).snapshots().map(
      (snapshot) => snapshot.docs
          .map((document) => {'session_id': document.id, ...document.data()})
          .toList(),
    );
  }

  Stream<Map<String, dynamic>> watchEvents(String roomCode) {
    var isInitialSnapshot = true;
    return _events(roomCode).snapshots().asyncExpand((snapshot) {
      if (isInitialSnapshot) {
        isInitialSnapshot = false;
        return Stream<Map<String, dynamic>>.value({'event': '_ready'});
      }
      final addedEvents = snapshot.docChanges
          .where((change) => change.type == DocumentChangeType.added)
          .map((change) => change.doc.data())
          .whereType<Map<String, dynamic>>();
      return Stream<Map<String, dynamic>>.fromIterable(addedEvents);
    });
  }

  Future<void> setPresence(
    String roomCode,
    String sessionId,
    Map<String, dynamic> participant,
  ) {
    return _participants(roomCode).doc(sessionId).set({
      ...participant,
      'last_seen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removePresence(String roomCode, String sessionId) {
    return _participants(roomCode).doc(sessionId).delete();
  }

  Future<void> sendEvent(
    String roomCode,
    String event,
    Map<String, dynamic> payload,
  ) {
    return _events(roomCode).add({
      'event': event,
      'payload': payload,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
