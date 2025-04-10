import '../../models/participant.dart';

abstract class ParticipantRepository {
  Future<void> addParticipant(Participant participant);
  Stream<List<Participant>> getParticipants(String raceId);
  Future<void> updateParticipant(Participant participant);
  Future<void> deleteParticipant(String bibNumber, String raceId);
}
