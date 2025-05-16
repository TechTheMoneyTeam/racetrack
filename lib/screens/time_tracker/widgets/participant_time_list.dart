import 'package:flutter/material.dart';
import '../../../models/participant.dart';
import '../../../providers/time_tracking_provider.dart';

class ParticipantTimeList extends StatelessWidget {
  final List<Participant> participants;
  final DateTime? raceStartTime;
  final TimeTrackingProvider timeTrackingProvider;
  final bool finished;
  final List<String> segments;

  const ParticipantTimeList({
    super.key,
    required this.participants,
    required this.raceStartTime,
    required this.timeTrackingProvider,
    required this.finished,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return Center(
        child: Text(
          finished ? 'No finished participants yet' : 'No participants yet',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: participants.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final participant = participants[index];
        final String bibNumber = participant.bibNumber;
        final String? currentSegment = timeTrackingProvider.currentSegment;
        
        DateTime? segmentTime;
        
        if (currentSegment != null && 
            timeTrackingProvider.participantTimes.containsKey(bibNumber) &&
            timeTrackingProvider.participantTimes[bibNumber] != null) {
          
          final Map<String, DateTime>? times = timeTrackingProvider.participantTimes[bibNumber];
          if (times != null && times.containsKey(currentSegment)) {
            segmentTime = times[currentSegment];
          }
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0C3B5B),
              child: Text(
                participant.bibNumber,
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              '${participant.firstName} ${participant.lastName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: segmentTime != null && raceStartTime != null
              ? Text(
                  'Time: ${_formatDuration(segmentTime.difference(raceStartTime!))}',
                  style: const TextStyle(color: Colors.green),
                )
              : const Text('Not tracked yet', style: TextStyle(color: Colors.orange)),
            trailing: finished
              ? const Icon(Icons.check_circle, color: Colors.green)
              : IconButton(
                  icon: const Icon(Icons.timer, color: Color(0xFF0C3B5B)),
                  onPressed: () {
                    if (timeTrackingProvider.currentSegment != null) {
                      timeTrackingProvider.trackTime(
                        participant.bibNumber,
                        segments,
                      );
                    }
                  },
                ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}
