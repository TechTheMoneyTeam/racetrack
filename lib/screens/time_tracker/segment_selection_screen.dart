import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/race_provider.dart';
import '../../models/race.dart'; 
import '../../providers/time_tracking_provider.dart';
import 'time_tracking_screen.dart';


class SegmentSelectionScreen extends StatelessWidget {
  final String raceId;

  const SegmentSelectionScreen({Key? key, required this.raceId}) : super(key: key);

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
              'Segment Selection',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Consumer<RaceProvider>(
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

                if (race.status != RaceStatus.started) {
                  return const Center(
                    child: Text(
                      'The race has not started yet or has already finished.\nTime tracking is only available during an active race.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: race.segments.length,
                  itemBuilder: (context, index) {
                    final segment = race.segments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          segment.toUpperCase(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Track participants completing the $segment segment'),
                        leading: _getSegmentIcon(segment),
                        onTap: () {
                          Provider.of<TimeTrackingProvider>(context, listen: false)
                              .setSegment(segment);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TimeTrackingScreen(
                                raceId: raceId,
                                segment: segment,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSegmentIcon(String segment) {
    IconData iconData;
    Color iconColor;

    switch (segment.toLowerCase()) {
      case 'swim':
        iconData = Icons.pool;
        iconColor = Colors.blue;
        break;
      case 'bike':
        iconData = Icons.directions_bike;
        iconColor = Colors.green;
        break;
      case 'run':
        iconData = Icons.directions_run;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.timer;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.2),
      child: Icon(iconData, color: iconColor),
    );
  }
}