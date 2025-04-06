import 'package:flutter/material.dart';
import '../models/participant.dart';
import '../repositories/abstract/participant_repository.dart';
import 'dart:async';

class ParticipantProvider extends ChangeNotifier {
  final ParticipantRepository _repository;

  List<Participant> _participants = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Participant>>? _participantsSubscription;
  String? _currentRaceId;

  ParticipantProvider(this._repository);

  List<Participant> get participants => _participants;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentRaceId => _currentRaceId;

  @override
  void dispose() {
    _participantsSubscription?.cancel();
    super.dispose();
  }

  Future<void> addParticipant(Participant participant) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print(
        '[ParticipantProvider] Adding participant: ${participant.bibNumber} to race: ${participant.raceId}',
      );

      if (participant.raceId.isEmpty && _currentRaceId != null) {
        participant = Participant(
          bibNumber: participant.bibNumber,
          firstName: participant.firstName,
          lastName: participant.lastName,
          raceId: _currentRaceId!,

        );
      }

      await _repository.addParticipant(participant);

      print('[ParticipantProvider] Successfully added participant');

      if (_currentRaceId != null) {
        _participants.add(participant);
        notifyListeners();
      }
    } catch (e, stack) {
      print('[ParticipantProvider] Error adding participant: $e');
      print('[ParticipantProvider] Stack trace: $stack');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadParticipants(String raceId) {
    try {
      _participantsSubscription?.cancel();

      _isLoading = true;
      _error = null;
      _currentRaceId = raceId;
      notifyListeners();

      print('[ParticipantProvider] Loading participants for race: $raceId');

      _participantsSubscription = _repository
          .getParticipants(raceId)
          .listen(
            (participantsList) {
              _participants = participantsList;
              _isLoading = false;
              _error = null;
              print(
                '[ParticipantProvider] Received ${participantsList.length} participants',
              );
              notifyListeners();
            },
            onError: (e, stack) {
              print('[ParticipantProvider] Error loading participants: $e');
              print('[ParticipantProvider] Stack trace: $stack');
              _error = e.toString();
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e, stack) {
      print('[ParticipantProvider] Error setting up participants stream: $e');
      print('[ParticipantProvider] Stack trace: $stack');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteParticipant(String bibNumber, [String? raceId]) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('[ParticipantProvider] Deleting participant: $bibNumber');

      String? targetRaceId = raceId ?? _currentRaceId;
      if (targetRaceId == null) {
        final participant = _participants.firstWhere(
          (p) => p.bibNumber == bibNumber,
          orElse: () => throw Exception('Participant not found in local list'),
        );
        targetRaceId = participant.raceId;
      }
      await _repository.deleteParticipant(bibNumber, targetRaceId);
      print(
        '[ParticipantProvider] Successfully deleted participant: $bibNumber',
      );
      _participants.removeWhere((p) => p.bibNumber == bibNumber);
      notifyListeners();
    } catch (e) {
      print('[ParticipantProvider] Error deleting participant: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
