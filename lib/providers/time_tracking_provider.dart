import 'package:flutter/foundation.dart';
import '../models/participant.dart';
import '../models/segment_time.dart';
import '../repositories/abstract/segment_time_repository.dart';

class TimeTrackingProvider extends ChangeNotifier {
  final SegmentTimeRepository _segmentTimeRepository;
  String? _currentRaceId;
  String? _currentSegment;
  List<SegmentTime> _segmentTimes = [];
  Map<String, Map<String, DateTime>> _participantTimes = {};
  bool _isLoading = false;
  String? _error;
  List<Participant> _participants = [];

  String? get currentSegment => _currentSegment;
  List<SegmentTime> get segmentTimes => _segmentTimes;
  Map<String, Map<String, DateTime>> get participantTimes => _participantTimes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TimeTrackingProvider(this._segmentTimeRepository);

  void setParticipants(List<Participant> participants) {
    _participants = participants;
  }

  void setSegment(String segment) {
    print('[TimeTrackingProvider] Setting segment to: $segment');
    _currentSegment = segment;
    notifyListeners();
  }

  void loadSegmentTimes(String raceId) {
    print('[TimeTrackingProvider] Loading segment times for race: $raceId');
    _currentRaceId = raceId;
    _setupSegmentTimesListener(raceId);
  }

  void _setupSegmentTimesListener(String raceId) {
    _segmentTimeRepository
        .getSegmentTimes(raceId)
        .listen(
          (segmentTimes) {
            print(
              '[TimeTrackingProvider] Received ${segmentTimes.length} segment times',
            );
            _segmentTimes = segmentTimes;
            _updateParticipantTimesMap(segmentTimes);
            notifyListeners();
          },
          onError: (error) {
            print(
              '[TimeTrackingProvider] Error receiving segment times: $error',
            );
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  void _updateParticipantTimesMap(List<SegmentTime> segmentTimes) {
    _participantTimes = {};

    for (var time in segmentTimes) {
      if (!_participantTimes.containsKey(time.bibNumber)) {
        _participantTimes[time.bibNumber] = {};
      }

      _participantTimes[time.bibNumber]![time.segment] = time.timeStamp;
    }
    print(
      '[TimeTrackingProvider] Updated participant times map with ${_participantTimes.length} participants',
    );
  }

  Future<void> trackTime(String bibNumber, List<String> segments) async {
    if (_currentRaceId == null || _currentSegment == null) {
      _error = 'No race or segment selected';
      notifyListeners();
      return;
    }

    final participantExists = _participants.any(
      (p) => p.bibNumber == bibNumber,
    );
    if (!participantExists) {
      _error = 'Participant with BIB number $bibNumber not found';
      notifyListeners();
      return;
    }

    final currentSegmentIndex = segments.indexOf(_currentSegment!);
    if (currentSegmentIndex > 0) {
      final previousSegment = segments[currentSegmentIndex - 1];
      final prevFinished =
          _participantTimes.containsKey(bibNumber) &&
          _participantTimes[bibNumber]!.containsKey(previousSegment);
      if (!prevFinished) {
        _error =
            'Cannot track this segment until previous segment ("$previousSegment") is finished.';
        notifyListeners();
        return;
      }
    }

    if (_participantTimes.containsKey(bibNumber) &&
        _participantTimes[bibNumber]!.containsKey(_currentSegment)) {
      _error = 'Time already recorded for this segment';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print(
        '[TimeTrackingProvider] Recording time for participant $bibNumber in segment $_currentSegment',
      );
      final segmentTime = SegmentTime(
        bibNumber: bibNumber,
        segment: _currentSegment!,
        timeStamp: DateTime.now(),
        raceId: _currentRaceId!,
      );

      await _segmentTimeRepository.recordTime(segmentTime);
      print('[TimeTrackingProvider] Successfully recorded time');
    } catch (e) {
      print('[TimeTrackingProvider] Error recording time: $e');
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTime(String bibNumber) async {
    if (_currentRaceId == null || _currentSegment == null) {
      _error = 'No race or segment selected';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print(
        '[TimeTrackingProvider] Deleting time for participant $bibNumber in segment $_currentSegment',
      );
      await _segmentTimeRepository.deleteSegmentTime(
        bibNumber,
        _currentSegment!,
        _currentRaceId!,
      );
      print('[TimeTrackingProvider] Successfully deleted time');
    } catch (e) {
      print('[TimeTrackingProvider] Error deleting time: $e');
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? getFormattedTime(
    String bibNumber,
    String segment,
    DateTime raceStartTime,
  ) {
    if (!_participantTimes.containsKey(bibNumber) ||
        !_participantTimes[bibNumber]!.containsKey(segment)) {
      return null;
    }

    final segmentTime = _participantTimes[bibNumber]![segment]!;
    final duration = segmentTime.difference(raceStartTime);

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }
}
