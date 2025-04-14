import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/race.dart';
import '../abstract/race_repository.dart';

class FirebaseRaceRepository implements RaceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String> createRace(Race race) async {
    try {
      print('[FirebaseRaceRepository] Creating race: ${race.toJson()}');
      final docRef = _firestore.collection('races').doc();
      final raceWithId = Race(
        id: docRef.id,
        status: race.status,
        startTime: race.startTime,
        endTime: race.endTime,
        segments: race.segments,
      );
      await docRef.set(raceWithId.toJson());
      print('[FirebaseRaceRepository] Successfully created race: ${docRef.id}');
      return docRef.id;
    } catch (e, stack) {
      print('[FirebaseRaceRepository] Error creating race: $e');
      print(stack);
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
            final race = Race.fromJson(snapshot.data()!);
            print('[FirebaseRaceRepository] Got race: ${race.toJson()}');
            return race;
          } catch (e, stack) {
            print('[FirebaseRaceRepository] Error parsing race data: $e');
            print('Document data: ${snapshot.data()}');
            print(stack);
            rethrow;
          }
        });
  }

  Future<void> updateRace(Race race) async {
    try {
      print('[FirebaseRaceRepository] Updating race: ${race.toJson()}');
      await _firestore
          .collection('races')
          .doc(race.id)
          .update(race.toJson());
      print('[FirebaseRaceRepository] Successfully updated race: ${race.id}');
    } catch (e, stack) {
      print('[FirebaseRaceRepository] Error updating race: $e');
      print(stack);
      rethrow;
    }
  }

  Future<void> deleteRace(String raceId) async {
    try {
      print('[FirebaseRaceRepository] Deleting race: $raceId');
      await _firestore.collection('races').doc(raceId).delete();
      print('[FirebaseRaceRepository] Successfully deleted race: $raceId');
    } catch (e, stack) {
      print('[FirebaseRaceRepository] Error deleting race: $e');
      print(stack);
      rethrow;
    }
  }

  @override
  Future<List<Race>> getAllRaces() async {
    try {
      print('[FirebaseRaceRepository] Getting all races');
      final querySnapshot = await _firestore.collection('races').get();
      final races = querySnapshot.docs.map((doc) => Race.fromJson(doc.data())).toList();
      print('[FirebaseRaceRepository] Got ${races.length} races');
      return races;
    } catch (e, stack) {
      print('[FirebaseRaceRepository] Error getting all races: $e');
      print(stack);
      rethrow;
    }
  }

  @override
  Future<void> startRace(String raceId) async {
    try {
      print('[FirebaseRaceRepository] Starting race: $raceId');
      await _firestore.collection('races').doc(raceId).update({
        'status': RaceStatus.started.index,
        'startTime': DateTime.now().millisecondsSinceEpoch,
      });
      print('[FirebaseRaceRepository] Successfully started race: $raceId');
    } catch (e, stack) {
      print('[FirebaseRaceRepository] Error starting race: $e');
      print(stack);
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
