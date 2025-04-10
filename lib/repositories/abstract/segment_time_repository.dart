import '../../models/segment_time.dart';

abstract class SegmentTimeRepository {
  Future<void> recordTime(SegmentTime segmentTime);

  Stream<List<SegmentTime>> getSegmentTimes(String raceId);

  Future<void> deleteSegmentTime(
    String bibNumber,
    String segment,
    String raceId,
  );

  Stream<List<SegmentTime>> getParticipantSegmentTimes(
    String bibNumber,
    String raceId,
  );
}
