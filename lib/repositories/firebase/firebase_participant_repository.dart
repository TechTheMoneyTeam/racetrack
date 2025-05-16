import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/participant.dart';
import '../abstract/participant_repository.dart';
import '../../dtos/participant_dto.dart';

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
      print('[FirebaseParticipantRepository] Adding participant');
      await _initializeCollection();
      final docRef = _firestore.collection(collectionName).doc(participant.bibNumber);
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        throw Exception('Participant with this BIB number already exists');
      }

      final data = {
        ...ParticipantDTO.toJson(participant),
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
        .snapshots()
        .map((snapshot) {
          print('[FirebaseParticipantRepository] Got ${snapshot.docs.length} participants');
          return snapshot.docs
              .map((doc) {
                try {
                  return ParticipantDTO.fromJson(doc.data());
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
      print('[FirebaseParticipantRepository] Updating participant: ${participant.bibNumber}');
      await _firestore
          .collection(collectionName)
          .doc(participant.bibNumber)
          .update(ParticipantDTO.toJson(participant));
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
      print('[FirebaseParticipantRepository] Deleting participant: $bibNumber');
      
      // Delete the participant
      await _firestore.collection(collectionName).doc(bibNumber).delete();
      final segmentTimesQuery = await _firestore
          .collection('segmentTimes')
          .where('bibNumber', isEqualTo: bibNumber)
          .where('raceId', isEqualTo: raceId)
          .get();
      
      for (var doc in segmentTimesQuery.docs) {
        await doc.reference.delete();
      }
      
      print('[FirebaseParticipantRepository] Successfully deleted participant and ${segmentTimesQuery.docs.length} related segment times');
    } catch (e, stack) {
      print('[FirebaseParticipantRepository] Error deleting participant: $e');
      print(stack);
      rethrow;
    }
  }

}