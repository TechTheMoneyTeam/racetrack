import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/race_provider.dart';
import '../../providers/participant_provider.dart';
import '../../providers/time_tracking_provider.dart';
import '../../models/race.dart';
import 'widgets/bib_number_input.dart';
import 'widgets/race_tab_view.dart';

class TimeTrackingScreen extends StatefulWidget {
  final String raceId;
  final String segment;

  const TimeTrackingScreen({
    super.key,
    required this.raceId,
    required this.segment,
  });

  @override
  _TimeTrackingScreenState createState() => _TimeTrackingScreenState();
}

class _TimeTrackingScreenState extends State<TimeTrackingScreen> {
  final TextEditingController _bibNumberController = TextEditingController();
  final FocusNode _bibNumberFocusNode = FocusNode();

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
      )
        ..setSegment(widget.segment)
        ..loadSegmentTimes(widget.raceId);
    });
  }

  @override
  void dispose() {
    _bibNumberController.dispose();
    _bibNumberFocusNode.dispose();
    super.dispose();
  }

  Future<void> _trackTime(List<String> segments) async {
    final bibNumber = _bibNumberController.text.trim();
    if (bibNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a BIB number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final timeTrackingProvider = Provider.of<TimeTrackingProvider>(
      context,
      listen: false,
    );

    try {
      await timeTrackingProvider.trackTime(bibNumber, segments);
      _bibNumberController.clear();
      _bibNumberFocusNode.requestFocus();
      
      if (timeTrackingProvider.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${timeTrackingProvider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Time recorded for BIB: $bibNumber'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C3B5B),
        title: Text(
          'Time Tracking - ${widget.segment.toUpperCase()}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer3<RaceProvider, ParticipantProvider, TimeTrackingProvider>(
        builder: (context, raceProvider, participantProvider, timeTrackingProvider, child) {
          if (raceProvider.isLoading ||
              participantProvider.isLoading ||
              timeTrackingProvider.isLoading) {
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
                'The race has been finished or reset.\nTime tracking is only available during an active race.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final participants = participantProvider.participants;
          timeTrackingProvider.setParticipants(participants);
          final participantTimes = timeTrackingProvider.participantTimes;

          final unfinishedParticipants =
              participants.where((participant) {
                final bibNumber = participant.bibNumber;
                return !participantTimes.containsKey(bibNumber) ||
                    !participantTimes[bibNumber]!.containsKey(widget.segment);
              }).toList();

          final finishedParticipants =
              participants.where((participant) {
                final bibNumber = participant.bibNumber;
                return participantTimes.containsKey(bibNumber) &&
                    participantTimes[bibNumber]!.containsKey(widget.segment);
              }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Track ${widget.segment.toUpperCase()} Time',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF0C3B5B),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    BibNumberInput(
                      controller: _bibNumberController,
                      focusNode: _bibNumberFocusNode,
                      onSubmitted: (_) => _trackTime(race.segments),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: RaceTabView(
                  unfinishedParticipants: unfinishedParticipants,
                  finishedParticipants: finishedParticipants,
                  raceStartTime: race.startTime,
                  timeTrackingProvider: timeTrackingProvider,
                  segments: race.segments,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
