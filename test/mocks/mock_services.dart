// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseStorageClient;
import 'package:snap2bill/services/firebase_auth_service.dart';
import 'package:snap2bill/services/firebase_db_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseAuthService extends Mock implements FirebaseAuthService {}

class MockFirebaseDbService extends Mock implements FirebaseDbService {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockWriteBatch extends Mock implements WriteBatch {}

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

void registerMockServiceFallbackValues() {
  registerFallbackValue(MockCollectionReference());
  registerFallbackValue(MockDocumentReference());
  registerFallbackValue(SetOptions(merge: true));
}
