import '../../models/race.dart';

abstract class RaceRepository {
  Future<String> createRace(Race race);
  Stream<Race> getRace(String raceId);
  Future<List<Race>> getAllRaces(); 
  Future<void> startRace(String raceId);
  Future<void> finishRace(String raceId);
  Future<void> resetRace(String raceId);
}