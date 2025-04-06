import 'package:flutter/foundation.dart';
import '../models/race.dart';
import '../repositories/abstract/race_repository.dart';

class RaceProvider extends ChangeNotifier {
  final RaceRepository _raceRepository;
  Race? _currentRace;
  bool _isLoading = false;
  String? _error;
  String? _currentRaceId;
  List<Race> _races = [];

  Race? get currentRace => _currentRace;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveRace => _currentRace != null;
  bool get isRaceStarted => _currentRace?.status == RaceStatus.started;
  bool get isRaceFinished => _currentRace?.status == RaceStatus.finished;
  String? get currentRaceId => _currentRaceId;
  List<Race> get races => _races;

  RaceProvider(this._raceRepository);

  Future<List<Race>> getAllRaces() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _races = await _raceRepository.getAllRaces();
      return _races;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCurrentRace(String raceId) async {
    if (_currentRaceId == raceId) return;

    try {
      _isLoading = true;
      _error = null;
      _currentRaceId = raceId;
      notifyListeners();

      _setupRaceListener(raceId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createRace(List<String> segments) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final race = Race(
        id: '',
        segments: segments,
        status: RaceStatus.notStarted,
      );

      final raceId = await _raceRepository.createRace(race);
      _currentRaceId = raceId;
      _setupRaceListener(raceId);

      await getAllRaces();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRace(String raceId) async {
    _currentRaceId = raceId;
    _setupRaceListener(raceId);
    notifyListeners();
  }

  void setCurrentRaceId(String raceId) {
    _currentRaceId = raceId;
    notifyListeners();
  }

  void _setupRaceListener(String raceId) {
    _raceRepository
        .getRace(raceId)
        .listen(
          (race) {
            _currentRace = race;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  Future<void> startRace() async {
    if (_currentRace == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _raceRepository.startRace(_currentRace!.id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> finishRace() async {
    if (_currentRace == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _raceRepository.finishRace(_currentRace!.id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetRace() async {
    if (_currentRace == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _raceRepository.resetRace(_currentRace!.id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentRace() {
    _currentRace = null;
    _currentRaceId = null;
    notifyListeners();
  }
}
