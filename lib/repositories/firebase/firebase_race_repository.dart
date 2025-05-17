import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/race.dart';
import '../abstract/race_repository.dart';
import '../../dtos/race_dto.dart';

class FirebaseRaceRepository implements RaceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String> createRace(Race race) async {
    try {
    
      final docRef = _firestore.collection('races').doc();
      final raceWithId = Race(
        id: docRef.id,
        status: race.status,
        startTime: race.startTime,
        endTime: race.endTime,
        segments: race.segments,
        distances: race.distances,
        raceType: race.raceType,
      );
      await docRef.set(RaceDTO.toJson(raceWithId));

      return docRef.id;
    } catch (e, stack) {
     
      rethrow;
    }
  }

  @override
  Stream<Race> getRace(String raceId) {
    print('[FirebaseRaceRepository] Getting race: $raceId');
    return _firestore
        .collection('races')
        .doc(raceId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            throw Exception('Race $raceId not found');
          }
          try {
            final race = RaceDTO.fromJson(snapshot.data()!);
   
            return race;
          } catch (e, stack) {
       
            rethrow;
          }
        });
  }

  Future<void> updateRace(Race race) async {
    try {

      await _firestore
          .collection('races')
          .doc(race.id)
          .update(RaceDTO.toJson(race));
    
    } catch (e, stack) {
   
      rethrow;
    }
  }

  Future<void> deleteRace(String raceId) async {
    try {
  
      await _firestore.collection('races').doc(raceId).delete();

    } catch (e, stack) {

      rethrow;
    }
  }

  @override
  Future<List<Race>> getAllRaces() async {
    try {

      final querySnapshot = await _firestore.collection('races').get();
      final races = querySnapshot.docs.map((doc) => RaceDTO.fromJson(doc.data())).toList();
    
      return races;
    } catch (e, stack) {
  
      rethrow;
    }
  }

  @override
  Future<void> startRace(String raceId) async {
    try {
   
      await _firestore.collection('races').doc(raceId).update({
        'status': RaceStatus.started.index,
        'startTime': DateTime.now().millisecondsSinceEpoch,
      });
     =
    } catch (e, stack) {
 
      rethrow;
    }
  }

  @override
  Future<void> finishRace(String raceId) async {
    try {
      print('[FirebaseRaceRepository] Finishing race: $raceId');
      await _firestore.collection('races').doc(raceId).update({
        'status': RaceStatus.finished.index,
        'endTime': DateTime.now().millisecondsSinceEpoch,
      });
      print('[FirebaseRaceRepository] Successfully finished race: $raceId');
    } catch (e, stack) {
      print('[FirebaseRaceRepository] Error finishing race: $e');
      print(stack);
      rethrow;
    }
  }

  @override
  Future<void> resetRace(String raceId) async {
    try {
      print('[FirebaseRaceRepository] Resetting race: $raceId');
      final raceDoc = await _firestore.collection('races').doc(raceId).get();
      if (!raceDoc.exists) {
        throw Exception('Race $raceId not found');
      }
      
      await _firestore.collection('races').doc(raceId).update({
        'status': RaceStatus.notStarted.index,
        'startTime': null,
        'endTime': null,
      });

      final segmentTimesQuery = await _firestore
          .collection('segmentTimes')
          .where('raceId', isEqualTo: raceId)
          .get();
      
      print('[FirebaseRaceRepository] Deleting ${segmentTimesQuery.docs.length} segment times');
      for (var doc in segmentTimesQuery.docs) {
        await doc.reference.delete();
      }
      
      print('[FirebaseRaceRepository] Successfully reset race: $raceId');
    } catch (e, stack) {
      print('[FirebaseRaceRepository] Error resetting race: $e');
      print(stack);
      rethrow;
    }
  }
}
