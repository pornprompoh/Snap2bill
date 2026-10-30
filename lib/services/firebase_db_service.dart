import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/bill_model.dart';
import '../models/user_model.dart';

class FirebaseDbService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseDbService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('profiles');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _bills =>
      _firestore.collection('bills');
  CollectionReference<Map<String, dynamic>> get _participants =>
      _firestore.collection('bill_participants');

  String newBillId() => _bills.doc().id;

  Map<String, dynamic> _withId(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) => {'id': document.id, ...document.data()};

  Map<String, dynamic> _withDocumentId(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) => {'id': document.id, ...?document.data()};

  Future<String> createUser(String userId, Map<String, dynamic> data) async {
    await _users.doc(userId).set({
      ...data,
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return userId;
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final snapshot = await _users.doc(userId).get();
    return snapshot.exists ? _withDocumentId(snapshot) : null;
  }

  Future<Map<String, dynamic>?> getLobby(String roomCode) async {
    final snapshot = await _firestore.collection('lobbies').doc(roomCode).get();
    final data = snapshot.data();
    return data == null ? null : {'id': snapshot.id, ...data};
  }

  Future<void> createLobby({
    required String roomCode,
    required String? hostId,
    required String shopName,
    required double totalAmount,
    required Map<String, dynamic>? receiptData,
  }) async {
    await _firestore.collection('lobbies').doc(roomCode).set({
      'host_id': hostId,
      'room_code': roomCode,
      'shop_name': shopName,
      'total_amount': totalAmount,
      'status': 'waiting',
      'receipt_json': receiptData,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<RoomMember>> getRoomGuestMembers(String roomCode) async {
    final lobby = await getLobby(roomCode);
    final receipt = lobby?['receipt_json'];
    if (receipt is! Map) return [];
    final rawMembers = receipt['room_members'];
    if (rawMembers is! Iterable) return [];
    return rawMembers
        .whereType<Map>()
        .map((member) => RoomMember.fromMap(Map<String, dynamic>.from(member)))
        .where((member) => member.id.isNotEmpty && member.isGuest)
        .toList();
  }

  Future<RoomMember> addRoomGuestMember(
    String roomCode,
    RoomMember member,
  ) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('ผู้ใช้ยังไม่ได้ล็อกอิน');

    final lobbyRef = _firestore.collection('lobbies').doc(roomCode);
    await _firestore.runTransaction((transaction) async {
      final lobbySnapshot = await transaction.get(lobbyRef);
      final lobby = lobbySnapshot.data();
      if (lobby == null) throw StateError('ไม่พบห้องนี้');
      if (lobby['host_id']?.toString() != userId) {
        throw StateError('เฉพาะเจ้าของห้องเท่านั้นที่เพิ่มเพื่อนได้');
      }

      final receipt = lobby['receipt_json'] is Map
          ? Map<String, dynamic>.from(lobby['receipt_json'] as Map)
          : <String, dynamic>{};
      final rawMembers = receipt['room_members'];
      final members = rawMembers is Iterable
          ? rawMembers
                .whereType<Map>()
                .map((value) => Map<String, dynamic>.from(value))
                .toList()
          : <Map<String, dynamic>>[];
      members.add(member.toMap());
      receipt['room_members'] = members;
      transaction.update(lobbyRef, {'receipt_json': receipt});
    });
    return member;
  }

  Future<UserModel?> getMyProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _profiles.doc(user.uid).get();
    final data = snapshot.data();
    if (data == null) {
      return UserModel(
        id: user.uid,
        displayName: user.displayName,
        email: user.email,
        avatarUrl: user.photoURL,
      );
    }
    return UserModel.fromMap({'id': snapshot.id, ...data});
  }

  Future<UserModel> getProfile(String userId) async {
    final snapshot = await _profiles.doc(userId).get();
    final data = snapshot.data();
    if (data == null) throw StateError('ไม่พบโปรไฟล์ผู้ใช้');
    return UserModel.fromMap({'id': snapshot.id, ...data});
  }

  Future<List<Map<String, dynamic>>> getProfiles(
    Iterable<String> userIds,
  ) async {
    final ids = userIds.toSet().where((id) => id.isNotEmpty).toList();
    final documents = <Map<String, dynamic>>[];
    for (var index = 0; index < ids.length; index += 30) {
      final batch = ids.skip(index).take(30).toList();
      final snapshot = await _profiles
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      documents.addAll(snapshot.docs.map(_withId));
    }
    return documents;
  }

  Future<UserModel> updateUserProfile({
    required String displayName,
    required Map<String, dynamic>? paymentInfo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('ผู้ใช้ยังไม่ได้ล็อกอิน');

    final promptPayType = paymentInfo?['type'];
    if (promptPayType != null &&
        promptPayType != 'phone' &&
        promptPayType != 'id_card') {
      throw ArgumentError.value(promptPayType, 'paymentInfo.type');
    }

    final data = <String, dynamic>{
      'id': user.uid,
      'display_name': displayName,
      'email': user.email,
      'avatar_url': user.photoURL,
      'payment_info': paymentInfo,
      'updated_at': FieldValue.serverTimestamp(),
    };
    await _profiles.doc(user.uid).set(data, SetOptions(merge: true));
    return UserModel.fromMap(data);
  }

  Future<List<UserModel>> getPastParticipants(String currentUserId) async {
    final participantRows = await _participants
        .where('profile_id', isEqualTo: currentUserId)
        .get();
    final ownedBillRows = await _bills
        .where('owner_id', isEqualTo: currentUserId)
        .get();
    final billIds = <String>{
      for (final row in participantRows.docs)
        if (row.data()['bill_id'] != null) row.data()['bill_id'].toString(),
      for (final row in ownedBillRows.docs) row.id,
    };
    if (billIds.isEmpty) return [];

    final bills = <Map<String, dynamic>>[];
    for (final billId in billIds) {
      final document = await _bills.doc(billId).get();
      final data = document.data();
      if (data != null) bills.add({'id': document.id, ...data});
    }
    final allParticipantRows = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (var index = 0; index < billIds.length; index += 30) {
      final ids = billIds.skip(index).take(30).toList();
      final rows = await _participants.where('bill_id', whereIn: ids).get();
      allParticipantRows.addAll(rows.docs);
    }

    final participantIdsByBill = <String, Set<String>>{};
    for (final row in allParticipantRows) {
      final data = row.data();
      final billId = data['bill_id']?.toString();
      final profileId = data['profile_id']?.toString();
      if (billId == null || profileId == null || profileId.isEmpty) continue;
      participantIdsByBill.putIfAbsent(billId, () => <String>{}).add(profileId);
    }

    final participantCounts = <String, int>{};
    final mostRecentBillByParticipant = <String, DateTime>{};
    for (final bill in bills) {
      final billId = bill['id']?.toString();
      if (billId == null) continue;
      final ownerId = bill['owner_id']?.toString();
      final memberIds = participantIdsByBill[billId] ?? <String>{};
      if (ownerId != null && ownerId.isNotEmpty) memberIds.add(ownerId);
      final rawSharers = bill['sharers_json'];
      if (rawSharers is Map) {
        for (final sharers in rawSharers.values) {
          if (sharers is! Iterable) continue;
          for (final sharer in sharers) {
            if (sharer is Map && sharer['user_id'] != null) {
              memberIds.add(sharer['user_id'].toString());
            }
          }
        }
      }
      if (!memberIds.contains(currentUserId)) continue;

      final rawDate = bill['created_at'];
      final billDate = rawDate is Timestamp
          ? rawDate.toDate()
          : DateTime.tryParse(rawDate?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      for (final participantId in memberIds) {
        if (participantId == currentUserId ||
            participantId.startsWith('guest_')) {
          continue;
        }
        participantCounts.update(
          participantId,
          (currentCount) => currentCount + 1,
          ifAbsent: () => 1,
        );
        final previousDate = mostRecentBillByParticipant[participantId];
        if (previousDate == null || billDate.isAfter(previousDate)) {
          mostRecentBillByParticipant[participantId] = billDate;
        }
      }
    }
    if (participantCounts.isEmpty) return [];

    final profiles = await getProfiles(participantCounts.keys);
    final participants = profiles.map(UserModel.fromMap).toList()
      ..sort((first, second) {
        final countOrder = (participantCounts[second.id] ?? 0).compareTo(
          participantCounts[first.id] ?? 0,
        );
        if (countOrder != 0) return countOrder;
        return (mostRecentBillByParticipant[second.id] ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
            .compareTo(
              mostRecentBillByParticipant[first.id] ??
                  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            );
      });
    return participants;
  }

  Future<List<FriendModel>> getMyFriends() async {
    final userId = currentUserId;
    if (userId == null) return [];
    final response = await _firestore
        .collection('friends')
        .where('user_id', isEqualTo: userId)
        .where('is_deleted', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .get();
    return response.docs.map((document) {
      return FriendModel.fromJson({'id': document.id, ...document.data()});
    }).toList();
  }

  Future<void> addFriend(String friendName) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('ผู้ใช้ยังไม่ได้ล็อกอิน');
    await _firestore.collection('friends').add({
      'user_id': userId,
      'friend_name': friendName,
      'is_deleted': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<BillModel>> getMyBills() async {
    final userId = currentUserId;
    if (userId == null) return [];
    final response = await _bills
        .where('owner_id', isEqualTo: userId)
        .where('is_deleted', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .get();
    return response.docs
        .map((document) => BillModel.fromJson(_withId(document)))
        .toList();
  }

  Future<BillModel> createBill(Object data, [double? totalAmount]) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('ผู้ใช้ยังไม่ได้ล็อกอิน');

    final billData = switch (data) {
      Map<String, dynamic> values => Map<String, dynamic>.from(values),
      String shopName when totalAmount != null => {
        'shop_name': shopName,
        'total_amount': totalAmount,
        'final_total': totalAmount,
      },
      _ => throw ArgumentError.value(
        data,
        'data',
        'Expected bill data or a shop name with a total amount.',
      ),
    };
    final suppliedId = billData.remove('id')?.toString();
    final billId = suppliedId == null || suppliedId.isEmpty
        ? _bills.doc().id
        : suppliedId;
    final ownerId =
        billData['userId']?.toString() ??
        billData['owner_id']?.toString() ??
        userId;
    final now = FieldValue.serverTimestamp();
    final items = _takeItems(billData);
    final persistedData = {
      ...billData,
      'owner_id': ownerId,
      'userId': ownerId,
      'created_at': billData['created_at'] ?? now,
      'createdAt': billData['createdAt'] ?? now,
      'status': billData['status'] ?? 'draft',
      'is_deleted': billData['is_deleted'] ?? false,
    };

    final batch = _firestore.batch();
    batch.set(_bills.doc(billId), persistedData);
    for (final item in items) {
      final itemId = item['id']?.toString();
      final itemReference = itemId == null || itemId.isEmpty
          ? _bills.doc(billId).collection('items').doc()
          : _bills.doc(billId).collection('items').doc(itemId);
      batch.set(itemReference, item);
    }
    await batch.commit();
    return BillModel.fromJson({'id': billId, ...persistedData});
  }

  List<Map<String, dynamic>> _takeItems(Map<String, dynamic> data) {
    final rawItems = data.remove('items');
    if (rawItems == null) return [];
    if (rawItems is! Iterable) {
      throw ArgumentError.value(rawItems, 'items', 'Must be a list of maps.');
    }
    return rawItems.map((item) {
      if (item is! Map) {
        throw ArgumentError.value(item, 'items', 'Each item must be a map.');
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  Future<Map<String, dynamic>?> getBillById(String billId) async {
    final snapshot = await _bills.doc(billId).get();
    if (!snapshot.exists) return null;

    final bill = _withDocumentId(snapshot);
    bill['items'] = await getBillItems(billId);
    bill['owner_id'] ??= bill['userId'];
    bill['created_at'] ??= bill['createdAt'];
    return bill;
  }

  Future<List<Map<String, dynamic>>> getBillItems(String billId) async {
    final snapshot = await _bills.doc(billId).collection('items').get();
    return snapshot.docs.map(_withId).toList();
  }

  Future<List<Map<String, dynamic>>> getUserBills(String userId) async {
    final results = <String, Map<String, dynamic>>{};
    for (final field in ['userId', 'owner_id']) {
      final snapshot = await _bills.where(field, isEqualTo: userId).get();
      for (final document in snapshot.docs) {
        final bill = _withId(document);
        bill['owner_id'] ??= bill['userId'];
        bill['created_at'] ??= bill['createdAt'];
        results[document.id] = bill;
      }
    }
    final bills = results.values.toList()
      ..sort((first, second) {
        return _dateFromValue(
          second['createdAt'] ?? second['created_at'],
        ).compareTo(_dateFromValue(first['createdAt'] ?? first['created_at']));
      });
    return bills;
  }

  DateTime _dateFromValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> updateBill(String billId, Map<String, dynamic> data) async {
    final updateData = Map<String, dynamic>.from(data);
    final items = _takeItems(updateData);
    updateData['updatedAt'] = FieldValue.serverTimestamp();
    final billReference = _bills.doc(billId);
    final batch = _firestore.batch();
    batch.update(billReference, updateData);
    if (data.containsKey('items')) {
      final existingItems = await billReference.collection('items').get();
      for (final item in existingItems.docs) {
        batch.delete(item.reference);
      }
      for (final item in items) {
        final itemId = item['id']?.toString();
        final itemReference = itemId == null || itemId.isEmpty
            ? billReference.collection('items').doc()
            : billReference.collection('items').doc(itemId);
        batch.set(itemReference, item);
      }
    }
    await batch.commit();
  }

  Future<String> saveContact(Map<String, dynamic> data) async {
    final userId = data['userId']?.toString() ?? currentUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('ผู้ใช้ยังไม่ได้ล็อกอิน');
    }
    final suppliedId = data['id']?.toString();
    final reference = suppliedId == null || suppliedId.isEmpty
        ? _firestore.collection('saved_contacts').doc()
        : _firestore.collection('saved_contacts').doc(suppliedId);
    await reference.set({
      ...data,
      'userId': userId,
      'user_id': userId,
      'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
      'created_at': data['created_at'] ?? FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return reference.id;
  }

  Future<List<Map<String, dynamic>>> getContacts(String userId) async {
    final contacts = <String, Map<String, dynamic>>{};
    for (final field in ['userId', 'user_id']) {
      final snapshot = await _firestore
          .collection('saved_contacts')
          .where(field, isEqualTo: userId)
          .get();
      for (final document in snapshot.docs) {
        contacts[document.id] = _withId(document);
      }
    }
    final result = contacts.values.toList()
      ..sort(
        (first, second) => _dateFromValue(
          second['createdAt'] ?? second['created_at'],
        ).compareTo(_dateFromValue(first['createdAt'] ?? first['created_at'])),
      );
    return result;
  }

  Future<void> deleteContact(String contactId, {String? userId}) async {
    final reference = _firestore.collection('saved_contacts').doc(contactId);
    final snapshot = await reference.get();
    final data = snapshot.data();
    if (data == null ||
        (data['userId'] ?? data['user_id'])?.toString() !=
            (userId ?? currentUserId)) {
      throw StateError('ไม่พบรายชื่อเพื่อนที่ต้องการลบ');
    }
    await reference.delete();
  }

  Future<List<Map<String, dynamic>>> getBillsForUser(String userId) async {
    final ownedBills = await _bills.where('owner_id', isEqualTo: userId).get();
    final participantRows = await _participants
        .where('profile_id', isEqualTo: userId)
        .get();
    final billIds = <String>{
      ...ownedBills.docs.map((document) => document.id),
      for (final row in participantRows.docs)
        if (row.data()['bill_id'] != null) row.data()['bill_id'].toString(),
    };
    final result = <String, Map<String, dynamic>>{
      for (final document in ownedBills.docs) document.id: _withId(document),
    };
    final missingIds = billIds.where((id) => !result.containsKey(id));
    for (final billId in missingIds) {
      final document = await _bills.doc(billId).get();
      final data = document.data();
      if (data != null) result[document.id] = {'id': document.id, ...data};
    }
    final bills = result.values.toList()
      ..sort(
        (first, second) => _dateFromValue(
          second['createdAt'] ?? second['created_at'],
        ).compareTo(_dateFromValue(first['createdAt'] ?? first['created_at'])),
      );
    return bills;
  }

  Future<List<Map<String, dynamic>>> getBillParticipants(String billId) async {
    final rows = await _participants.where('bill_id', isEqualTo: billId).get();
    return rows.docs.map(_withId).toList();
  }

  Future<String> saveCompletedBill({
    required String billId,
    required Map<String, dynamic> bill,
    required Map<String, double> participantTotals,
  }) async {
    final batch = _firestore.batch();
    final billReference = _bills.doc(billId);
    batch.set(billReference, {
      ...bill,
      'userId': bill['userId'] ?? bill['owner_id'],
      'created_at': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'is_deleted': false,
    });
    final receiptData = bill['receipt_json'];
    final rawItems = receiptData is Map ? receiptData['items'] : null;
    if (rawItems is Iterable) {
      final items = rawItems.toList();
      for (var index = 0; index < items.length; index++) {
        final rawItem = items[index];
        if (rawItem is! Map) {
          throw ArgumentError.value(
            rawItem,
            'bill.receipt_json.items',
            'Each bill item must be a map.',
          );
        }
        final itemId = rawItem['id']?.toString();
        final itemReference = itemId == null || itemId.isEmpty
            ? billReference.collection('items').doc(index.toString())
            : billReference.collection('items').doc(itemId);
        batch.set(itemReference, Map<String, dynamic>.from(rawItem));
      }
    }
    for (final entry in participantTotals.entries) {
      if (entry.key.startsWith('guest_')) continue;
      final participantReference = _participants.doc(
        '${billReference.id}_${entry.key}',
      );
      batch.set(participantReference, {
        'bill_id': billReference.id,
        'profile_id': entry.key,
        'amount_owed': entry.value,
        'status': 'pending',
      });
    }
    await batch.commit();
    return billReference.id;
  }

  Future<void> updateParticipantStatus(
    String billId,
    String profileId,
    String status,
  ) async {
    final rows = await _participants
        .where('bill_id', isEqualTo: billId)
        .where('profile_id', isEqualTo: profileId)
        .get();
    if (rows.docs.isEmpty) {
      throw StateError('ไม่พบข้อมูลผู้ร่วมบิลที่ต้องการอัปเดต');
    }
    final batch = _firestore.batch();
    for (final row in rows.docs) {
      batch.update(row.reference, {'status': status});
    }
    await batch.commit();
  }
}
