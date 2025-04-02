enum RaceStatus { notStarted, started, finished }

class Race {
  final String id;
  RaceStatus status;
  DateTime? startTime;
  DateTime? endTime;
  final List<String> segments; 

  Race({
    required this.id,
    this.status = RaceStatus.notStarted,
    this.startTime,
    this.endTime,
    required this.segments,
  });


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.index,
      'startTime': startTime?.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'segments': segments,
    };
  }

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      id: json['id'],
      status: RaceStatus.values[json['status']],
      startTime: json['startTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['startTime']) 
          : null,
      endTime: json['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime']) 
          : null,
      segments: List<String>.from(json['segments']),
    );
  }
}