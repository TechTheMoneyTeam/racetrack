import '../models/race.dart';

class RaceDTO {
  static Map<String, dynamic> toJson(Race race) {
    return {
      'id': race.id,
      'status': race.status.index,
      'startTime': race.startTime?.millisecondsSinceEpoch,
      'endTime': race.endTime?.millisecondsSinceEpoch,
      'segments': race.segments,
      'distances': race.distances,
      'raceType': race.raceType,
    };
  }

  static Race fromJson(Map<String, dynamic> json) {
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
      distances: json['distances'] != null 
          ? Map<String, double>.from(json['distances']) 
          : null,
      raceType: json['raceType'],
    );
  }
} 