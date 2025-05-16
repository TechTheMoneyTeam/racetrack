enum RaceStatus { notStarted, started, finished }

class Race {
  final String id;
  RaceStatus status;
  DateTime? startTime;
  DateTime? endTime;
  final List<String> segments; 
  final Map<String, double>? distances; 
  final String? raceType;
  
  Race({
    required this.id,
    this.status = RaceStatus.notStarted,
    this.startTime,
    this.endTime,
    required this.segments,
    this.distances,
    this.raceType,
  });
}