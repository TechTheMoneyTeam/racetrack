class Participant {
  final String bibNumber;
  final String firstName;
  final String lastName;
  final String raceId;

  Participant({
    required this.bibNumber,
    required this.firstName,
    required this.lastName,
    required this.raceId,

  });

  Map<String, dynamic> toJson() {
    return {
      'bibNumber': bibNumber,
      'firstName': firstName,
      'lastName': lastName,
      'raceId': raceId,
    };
  }

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      bibNumber: json['bibNumber'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      raceId: json['raceId'],
    );
  }
}