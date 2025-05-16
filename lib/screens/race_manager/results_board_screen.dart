import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/race_provider.dart';
import '../../providers/participant_provider.dart';
import '../../providers/time_tracking_provider.dart';

class ResultsBoardScreen extends StatefulWidget {
  final String raceId;

  const ResultsBoardScreen({super.key, required this.raceId});

  @override
  _ResultsBoardScreenState createState() => _ResultsBoardScreenState();
}

class _ResultsBoardScreenState extends State<ResultsBoardScreen> {
  bool _showSeconds = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RaceProvider>(context, listen: false).loadRace(widget.raceId);
      Provider.of<ParticipantProvider>(
        context,
        listen: false,
      ).loadParticipants(widget.raceId);
      Provider.of<TimeTrackingProvider>(
        context,
        listen: false,
      ).loadSegmentTimes(widget.raceId);
    });
  }

  String _formatTimeOfDay(DateTime dateTime) {
    final hours = dateTime.hour.toString().padLeft(2, '0');
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    final seconds = dateTime.second.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            color: const Color(0xFF0C3B5B),
            padding: const EdgeInsets.only(top: 40, bottom: 16),
            width: double.infinity,
            child: const Text(
              'Leaderboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Show in:'),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Seconds'),
                  selected: _showSeconds,
                  onSelected: (selected) {
                    setState(() {
                      _showSeconds = true;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Minutes'),
                  selected: !_showSeconds,
                  onSelected: (selected) {
                    setState(() {
                      _showSeconds = false;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer3<
              RaceProvider,
              ParticipantProvider,
              TimeTrackingProvider
            >(
              builder: (
                context,
                raceProvider,
                participantProvider,
                timeTrackingProvider,
                child,
              ) {
                if (raceProvider.isLoading ||
                    participantProvider.isLoading ||
                    timeTrackingProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (raceProvider.error != null) {
                  return Center(child: Text('Error: ${raceProvider.error}'));
                }

                final race = raceProvider.currentRace;
                if (race == null || race.startTime == null) {
                  return const Center(child: Text('Race not started yet'));
                }

                final participants = participantProvider.participants;
                final participantTimes = timeTrackingProvider.participantTimes;

                List<Map<String, dynamic>> overallResults = [];
                for (final participant in participants) {
                  final bibNumber = participant.bibNumber;
                  bool finishedAll = race.segments.every(
                    (segment) =>
                        participantTimes.containsKey(bibNumber) &&
                        participantTimes[bibNumber]!.containsKey(segment),
                  );

                  if (finishedAll) {
                    int totalSeconds = 0;

                    final bikeIndex = race.segments.indexOf('bike');
                    final runIndex = race.segments.indexOf('run');
                    if (bikeIndex != -1 && runIndex != -1) {
                      DateTime bikeFinish =
                          participantTimes[bibNumber]![race
                              .segments[bikeIndex]]!;
                      DateTime bikeStart =
                          bikeIndex == 0
                              ? race.startTime!
                              : participantTimes[bibNumber]![race
                                  .segments[bikeIndex - 1]]!;
                      totalSeconds +=
                          bikeFinish.difference(bikeStart).inSeconds;

                      DateTime runFinish =
                          participantTimes[bibNumber]![race
                              .segments[runIndex]]!;
                      DateTime runStart =
                          runIndex == 0
                              ? race.startTime!
                              : participantTimes[bibNumber]![race
                                  .segments[runIndex - 1]]!;
                      totalSeconds += runFinish.difference(runStart).inSeconds;
                    }
                    overallResults.add({
                      'participant': participant,
                      'segmentTimes': participantTimes[bibNumber]!,
                      'totalSeconds': totalSeconds,
                    });
                  }
                }

                overallResults.sort(
                  (a, b) => a['totalSeconds'].compareTo(b['totalSeconds']),
                );

                Map<String, List<Map<String, dynamic>>> segmentResults = {};
                for (final segment in race.segments) {
                  List<Map<String, dynamic>> segmentList = [];
                  for (final participant in participants) {
                    final bibNumber = participant.bibNumber;
                    if (participantTimes.containsKey(bibNumber) &&
                        participantTimes[bibNumber]!.containsKey(segment)) {
                      DateTime segmentTime =
                          participantTimes[bibNumber]![segment]!;
                      DateTime? segmentStart;
                      final segmentIndex = race.segments.indexOf(segment);
                      if (segmentIndex == 0) {
                        segmentStart = race.startTime;
                      } else {
                        final prevSegment = race.segments[segmentIndex - 1];
                        segmentStart =
                            participantTimes[bibNumber]![prevSegment];
                      }
                      if (segmentStart != null) {
                        final duration = segmentTime.difference(segmentStart);
                        segmentList.add({
                          'participant': participant,
                          'duration': duration,
                          'segmentTimes': participantTimes[bibNumber]!,
                        });
                      }
                    }
                  }

                  segmentList.sort(
                    (a, b) => a['duration'].compareTo(b['duration']),
                  );
                  segmentResults[segment] = segmentList;
                }

                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Overall Rankings',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 1,
                            child: Text(
                              'Rank',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Expanded(
                            flex: 1,
                            child: Text(
                              'BIB',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Expanded(
                            flex: 2,
                            child: Text(
                              'Name',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),

                          ...race.segments.map(
                            (segment) => Expanded(
                              flex: 1,
                              child: Text(
                                segment.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const Expanded(
                            flex: 1,
                            child: Text(
                              'Total Time',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0C3B5B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...overallResults.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final data = entry.value;
                      final participant = data['participant'];
                      final segmentTimes =
                          data['segmentTimes'] as Map<String, DateTime>;
                      final totalSeconds = data['totalSeconds'] as int;

                      List<Duration> segmentDurations = [];
                      for (int i = 0; i < race.segments.length; i++) {
                        final segment = race.segments[i];
                        DateTime segmentFinishTime = segmentTimes[segment]!;
                        DateTime segmentStartTime;

                        if (i == 0) {
                          segmentStartTime = race.startTime!;
                        } else {
                          segmentStartTime =
                              segmentTimes[race.segments[i - 1]]!;
                        }

                        segmentDurations.add(
                          segmentFinishTime.difference(segmentStartTime),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color:
                              idx % 2 == 0
                                  ? Colors.amber[100]
                                  : Colors.brown[100],
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                '#${idx + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Expanded(
                              flex: 1,
                              child: Text(
                                '${participant.bibNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Expanded(
                              flex: 2,
                              child: Text(
                                '${participant.firstName} ${participant.lastName?.substring(0, 1) ?? ""}',
                              ),
                            ),

                            ...race.segments.map((segment) {
                              final checkpointTime = segmentTimes[segment]!;
                              return Expanded(
                                flex: 1,
                                child: Text(
                                  _formatTimeOfDay(checkpointTime),
                                ),
                              );
                            }),

                            Expanded(
                              flex: 1,
                              child: Text(
                                _showSeconds
                                    ? '$totalSeconds s'
                                    : '${(totalSeconds / 60).toStringAsFixed(2)} min',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0C3B5B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Segment Rankings',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    ...race.segments.map((segment) {
                      final segmentList = segmentResults[segment]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8,
                            ),
                            child: Text(
                              segment.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (segmentList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 4,
                              ),
                              child: Text('No results yet.'),
                            ),
                          if (segmentList.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Row(
                                children: const [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Rank',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'BIB',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Name',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Segment Time',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ...segmentList.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final data = entry.value;
                            final participant = data['participant'];
                            final duration = data['duration'] as Duration;
                            final segmentTimes =
                                data['segmentTimes'] as Map<String, DateTime>;

                            return Container(
                              decoration: BoxDecoration(
                                color:
                                    idx % 2 == 0
                                        ? Colors.amber[100]
                                        : Colors.brown[100],
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 16.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '#${idx + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${participant.bibNumber}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '${participant.firstName} ${participant.lastName?.substring(0, 1) ?? ""}',
                                    ),
                                  ),

                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Time: ${_formatTimeOfDay(segmentTimes[segment]!)}',
                                        ),
                                        if (segment.toLowerCase() != 'swim')
                                          Text(
                                            _showSeconds
                                                ? 'Duration: ${duration.inSeconds} s'
                                                : 'Duration: ${(duration.inMinutes + (duration.inSeconds % 60) / 60).toStringAsFixed(2)} min',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
