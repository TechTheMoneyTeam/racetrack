import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/participant.dart';
import '../abstract/participant_repository.dart';

class FirebaseParticipantRepository implements ParticipantRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'participants';

  Future<void> _initializeCollection() async {
    try {
 
      final snapshot = await _firestore.collection(collectionName).limit(1).get();
      if (snapshot.docs.isEmpty) {

        final docRef = _firestore.collection(collectionName).doc('temp');
        await docRef.set({
          'initialized': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await docRef.delete();
      }
      print('[FirebaseParticipantRepository] Collection initialized successfully');
    } catch (e, stack) {
      print('[FirebaseParticipantRepository] Error initializing collection: $e');
      print(stack);
      rethrow;
    }
  }

  @override
  Future<void> addParticipant(Participant participant) async {
    try {
      print('[FirebaseParticipantRepository] Adding participant: ${participant.toJson()}');
      

      await _initializeCollection();
      

      final docRef = _firestore.collection(collectionName).doc(participant.bibNumber);
      

      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        throw Exception('Participant with this BIB number already exists');
      }

      final data = {
        ...participant.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await docRef.set(data);
      print('[FirebaseParticipantRepository] Successfully added participant: ${participant.bibNumber}');
    } catch (e, stack) {
      print('[FirebaseParticipantRepository] Error adding participant: $e');
      print(stack);
      rethrow;
    }
  }

  @override
  Stream<List<Participant>> getParticipants(String raceId) {
    print('[FirebaseParticipantRepository] Getting participants for race: $raceId');
    return _firestore
        .collection(collectionName)
        .where('raceId', isEqualTo: raceId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          print('[FirebaseParticipantRepository] Got ${snapshot.docs.length} participants');
          return snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  print('[FirebaseParticipantRepository] Parsing participant data: $data');
                  return Participant.fromJson(data);
                } catch (e, stack) {
                  print('[FirebaseParticipantRepository] Error parsing participant data: $e');
                  print('Document data: ${doc.data()}');
                  print(stack);
                  rethrow;
                }
              })
              .toList();
        });
  }

  @override
  Future<void> updateParticipant(Participant participant) async {
    try {
      print('[FirebaseParticipantRepository] Updating participant: ${participant.toJson()}');
      final docRef = _firestore.collection(collectionName).doc(participant.bibNumber);
 
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception('Participant not found');
      }
      
      await docRef.update({
        ...participant.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FirebaseParticipantRepository] Successfully updated participant: ${participant.bibNumber}');
    } catch (e, stack) {
      print('[FirebaseParticipantRepository] Error updating participant: $e');
      print(stack);
      rethrow;
    }
  }

  @override
  Future<void> deleteParticipant(String bibNumber, String raceId) async {
    try {
      print('[FirebaseParticipantRepository] Deleting participant: bibNumber=$bibNumber, raceId=$raceId');
      final docRef = _firestore.collection(collectionName).doc(bibNumber);
      

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception('Participant not found');
      }
      

      final data = docSnapshot.data();
      if (data?['raceId'] != raceId) {
        throw Exception('Participant does not belong to this race');
      }
      
      await docRef.delete();
      print('[FirebaseParticipantRepository] Successfully deleted participant: $bibNumber');
    } catch (e, stack) {
      print('[FirebaseParticipantRepository] Error deleting participant: $e');
      print(stack);
      rethrow;
    }
  }

Future<void> debugFirestore() async {
  try {
    print('[FirebaseParticipantRepository] Testing Firestore connection...');
    
    final testDocRef = _firestore.collection('debug_test').doc('test_${DateTime.now().millisecondsSinceEpoch}');
    
    await testDocRef.set({
      'timestamp': FieldValue.serverTimestamp(),
      'test': 'This is a test document',
    });
    
    print('[FirebaseParticipantRepository] Successfully wrote test document to Firestore');
    

    final docSnapshot = await testDocRef.get();
    print('[FirebaseParticipantRepository] Successfully read test document: ${docSnapshot.exists}');
    

    await testDocRef.delete();
    print('[FirebaseParticipantRepository] Successfully deleted test document');
    
  } catch (e, stack) {
    print('[FirebaseParticipantRepository] Error testing Firestore: $e');
    print(stack);
    rethrow;
  }
}


Future<void> checkFirebaseSetup() async {
  try {
    print('[Firebase Check] Verifying Firebase setup...');
    
    if (Firebase.apps.isEmpty) {
      print('[Firebase Check] Firebase is not initialized!');
      throw Exception('Firebase is not initialized');
    }

    final firestore = FirebaseFirestore.instance;
    final testCollection = firestore.collection('firebase_test');
    final testDoc = testCollection.doc('test_doc');
    

    await testDoc.set({
      'test': 'Firebase is working',
      'timestamp': FieldValue.serverTimestamp(),
    });
    

    final snapshot = await testDoc.get();
    if (!snapshot.exists) {
      throw Exception('Test document was not written to Firestore');
    }
    

    await testDoc.delete();
    
    print('[Firebase Check] Firebase setup verified successfully');
  } catch (e, stack) {
    print('[Firebase Check] Error verifying Firebase setup: $e');
    print(stack);
    rethrow;
  }
}
}