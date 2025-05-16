import 'package:flutter/material.dart';
import '../../../providers/time_tracking_provider.dart';
import '../../../models/participant.dart';
import 'participant_time_list.dart';

class RaceTabView extends StatelessWidget {
  final List<Participant> unfinishedParticipants;
  final List<Participant> finishedParticipants;
  final DateTime? raceStartTime;
  final TimeTrackingProvider timeTrackingProvider;
  final List<String> segments;
  
  const RaceTabView({
    super.key,
    required this.unfinishedParticipants,
    required this.finishedParticipants,
    required this.raceStartTime,
    required this.timeTrackingProvider,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0C3B5B),
            ),
            child: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Not Finished'),
                Tab(text: 'Finished'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ParticipantTimeList(
                  participants: unfinishedParticipants,
                  raceStartTime: raceStartTime,
                  timeTrackingProvider: timeTrackingProvider,
                  finished: false,
                  segments: segments,
                ),
                ParticipantTimeList(
                  participants: finishedParticipants,
                  raceStartTime: raceStartTime,
                  timeTrackingProvider: timeTrackingProvider,
                  finished: true,
                  segments: segments,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
