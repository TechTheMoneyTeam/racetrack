class SegmentTime {
  final String bibNumber;
  final String segment; 
  final DateTime timeStamp;
  final String raceId;

  SegmentTime({
    required this.bibNumber,
    required this.segment,
    required this.timeStamp,
    required this.raceId,
  });


  Map<String, dynamic> toJson() {
    return {
      'bibNumber': bibNumber,
      'segment': segment,
      'timeStamp': timeStamp.millisecondsSinceEpoch,
      'raceId': raceId,
    };
  }

  factory SegmentTime.fromJson(Map<String, dynamic> json) {
    return SegmentTime(
      bibNumber: json['bibNumber'],
      segment: json['segment'],
      timeStamp: DateTime.fromMillisecondsSinceEpoch(json['timeStamp']),
      raceId: json['raceId'],
    );
  }
}