import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/race.dart';
import '../../providers/race_provider.dart';
import '../../providers/time_tracking_provider.dart';

class RaceControlScreen extends StatefulWidget {
  final String raceId;

  const RaceControlScreen({super.key, required this.raceId});

  @override
  _RaceControlScreenState createState() => _RaceControlScreenState();
}

class _RaceControlScreenState extends State<RaceControlScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RaceProvider>(context, listen: false).loadRace(widget.raceId);
      Provider.of<TimeTrackingProvider>(
        context,
        listen: false,
      ).loadSegmentTimes(widget.raceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C3B5B),
        title: const Text(
          'Timer Control',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      body: Consumer<RaceProvider>(
        builder: (context, raceProvider, child) {
          if (raceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (raceProvider.error != null) {
            return Center(child: Text('Error: ${raceProvider.error}'));
          }

          final race = raceProvider.currentRace;
          if (race == null) {
            return const Center(child: Text('Race not found'));
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flag),
                  const SizedBox(width: 8),
                  Text(
                    'Race Status: ${_getStatusText(race.status)}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (race.startTime != null) ...[
                Text(
                  'Start Time: ${_formatDateTime(race.startTime!)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
              ],
              if (race.status == RaceStatus.started) ...[
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    final now = DateTime.now();
                    final duration = now.difference(race.startTime!);
                    final hours = duration.inHours.toString().padLeft(2, '0');
                    final minutes = (duration.inMinutes % 60)
                        .toString()
                        .padLeft(2, '0');
                    final seconds = (duration.inSeconds % 60)
                        .toString()
                        .padLeft(2, '0');
                    return Text(
                      'Elapsed Time: $hours:$minutes:$seconds',
                      style: Theme.of(context).textTheme.titleLarge,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (race.status == RaceStatus.notStarted)
                    ElevatedButton(
                      onPressed: () => raceProvider.startRace(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C3B5B),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'START RACE',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (race.status == RaceStatus.started)
                    ElevatedButton(
                      onPressed: () => raceProvider.finishRace(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'FINISH RACE',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  if (race.status != RaceStatus.notStarted)
                    ElevatedButton(
                      onPressed:
                          () => _showResetConfirmation(context, raceProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'RESET RACE',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, RaceProvider raceProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Race'),
            content: const Text(
              'Are you sure you want to reset the race? This will clear all times and set the race status to "Not Started".',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  raceProvider.resetRace();
                  Navigator.of(context).pop();
                },
                child: const Text('RESET'),
              ),
            ],
          ),
    );
  }

  String _getStatusText(RaceStatus status) {
    switch (status) {
      case RaceStatus.notStarted:
        return 'Not Started';
      case RaceStatus.started:
        return 'Started';
      case RaceStatus.finished:
        return 'Finished';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}
