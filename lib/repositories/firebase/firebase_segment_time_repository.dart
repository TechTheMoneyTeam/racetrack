import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/segment_time.dart';
import '../abstract/segment_time_repository.dart';
import '../../dtos/segment_time_dto.dart';

class FirebaseSegmentTimeRepository implements SegmentTimeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> recordTime(SegmentTime segmentTime) async {
    final docId = '${segmentTime.raceId}_${segmentTime.bibNumber}_${segmentTime.segment}';
  
    try {
      await _firestore
          .collection('segmentTimes')
          .doc(docId)
          .set(SegmentTimeDTO.toJson(segmentTime));
   
    } catch (e, stack) {
    
      rethrow;
    }
  }

  @override
  Stream<List<SegmentTime>> getSegmentTimes(String raceId) {
    print('[FirebaseSegmentTimeRepository] Getting segment times for race: $raceId');
    return _firestore
        .collection('segmentTimes')
        .where('raceId', isEqualTo: raceId)
        .orderBy('timeStamp', descending: false)
        .snapshots()
        .map((snapshot) {
          
          return snapshot.docs
              .map((doc) {
                try {
                  return SegmentTimeDTO.fromJson(doc.data());
                } catch (e, stack) {
              
                  rethrow;
                }
              })
              .toList();
        });
  }

  @override
  Future<void> deleteSegmentTime(String bibNumber, String segment, String raceId) async {
    final docId = '${raceId}_${bibNumber}_$segment';
    
    try {
      await _firestore.collection('segmentTimes').doc(docId).delete();
    ;
    } catch (e, stack) {
     
      rethrow;
    }
  }

  @override
  Stream<List<SegmentTime>> getParticipantSegmentTimes(String bibNumber, String raceId) {
    print('[FirebaseSegmentTimeRepository] Getting segment times for participant: bibNumber=$bibNumber, raceId=$raceId');
    return _firestore
        .collection('segmentTimes')
        .where('raceId', isEqualTo: raceId)
        .where('bibNumber', isEqualTo: bibNumber)
        .orderBy('timeStamp', descending: false)
        .snapshots()
        .map((snapshot) {
       
          return snapshot.docs
              .map((doc) {
                try {
                  return SegmentTimeDTO.fromJson(doc.data());
                } catch (e, stack) {
             
                  rethrow;
                }
              })
              .toList();
        });
  }
}