import '../models/participant.dart';

class ParticipantDTO {
  static Map<String, dynamic> toJson(Participant participant) {
    return {
      'bibNumber': participant.bibNumber,
      'firstName': participant.firstName,
      'lastName': participant.lastName,
      'raceId': participant.raceId,
    };
  }

  static Participant fromJson(Map<String, dynamic> json) {
    return Participant(
      bibNumber: json['bibNumber'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      raceId: json['raceId'],
    );
  }
} 