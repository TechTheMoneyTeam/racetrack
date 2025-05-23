import '../models/segment_time.dart';

class SegmentTimeDTO {
  static Map<String, dynamic> toJson(SegmentTime segmentTime) {
    return {
      'bibNumber': segmentTime.bibNumber,
      'segment': segmentTime.segment,
      'timeStamp': segmentTime.timeStamp.millisecondsSinceEpoch,
      'raceId': segmentTime.raceId,
    };
  }

  static SegmentTime fromJson(Map<String, dynamic> json) {
    return SegmentTime(
      bibNumber: json['bibNumber'],
      segment: json['segment'],
      timeStamp: DateTime.fromMillisecondsSinceEpoch(json['timeStamp']),
      raceId: json['raceId'],
    );
  }
} 