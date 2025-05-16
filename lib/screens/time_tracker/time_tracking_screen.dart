import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/race_provider.dart';
import '../../providers/participant_provider.dart';
import '../../providers/time_tracking_provider.dart';
import '../../models/race.dart';

class TimeTrackingScreen extends StatefulWidget {
  final String raceId;
  final String segment;

  const TimeTrackingScreen({
    Key? key,
    required this.raceId,
    required this.segment,
  }) : super(key: key);

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
      ).loadSegmentTimes(widget.raceId);
      Provider.of<TimeTrackingProvider>(
        context,
        listen: false,
      ).setSegment(widget.segment); 
    });
  }

  @override
  void dispose() {
    _bibNumberController.dispose();
    _bibNumberFocusNode.dispose();
    super.dispose();
  }

  void _trackTime(List<String> segments) {
    if (_bibNumberController.text.isNotEmpty) {
      Provider.of<TimeTrackingProvider>(
        context,
        listen: false,
      ).trackTime(_bibNumberController.text, segments);
      _bibNumberController.clear();
      _bibNumberFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C3B5B),
        title: Text(
          '${widget.segment.toUpperCase()} Time Tracking',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: Consumer3<RaceProvider, ParticipantProvider, TimeTrackingProvider>(
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
                padding: const EdgeInsets.all(15.0),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bibNumberController,
                            focusNode: _bibNumberFocusNode,
                            decoration: InputDecoration(
                              labelText: 'BIB Number',
                              labelStyle: const TextStyle(color: Color(0xFF0C3B5B)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: const BorderSide(color: Color(0xFF0C3B5B)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF0C3B5B), width: 2),
                              ),
                              prefixIcon: const Icon(Icons.numbers, color: Color(0xFF0C3B5B)),
                            ),
                            keyboardType: TextInputType.number,
                            onSubmitted: (_) => _trackTime(race.segments),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => _trackTime(race.segments),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C3B5B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            elevation: 2,
                          ),
                          child: const Text('Search Participant'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF0C3B5B),
                          // borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                            _buildParticipantList(
                              unfinishedParticipants,
                              race.startTime,
                              timeTrackingProvider,
                              false,
                            ),

                            _buildParticipantList(
                              finishedParticipants,
                              race.startTime,
                              timeTrackingProvider,
                              true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParticipantList(
    List<dynamic> participants,
    DateTime? raceStartTime,
    TimeTrackingProvider timeTrackingProvider,
    bool finished,
  ) {
    final raceProvider = Provider.of<RaceProvider>(context, listen: false);
    final race = raceProvider.currentRace;
    final segments = race?.segments ?? [];
    final currentSegmentIndex = segments.indexOf(widget.segment);
    final previousSegment = currentSegmentIndex > 0 ? segments[currentSegmentIndex - 1] : null;

    if (participants.isEmpty) {
      return Center(
        child: Text(
          finished
              ? 'No participants have finished this segment yet'
              : 'All participants have finished this segment',
          style: const TextStyle(color: Color(0xFF0C3B5B), fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.builder(
      itemCount: participants.length,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemBuilder: (context, index) {
        final participant = participants[index];
        final bibNumber = participant.bibNumber;
        final participantTimes = timeTrackingProvider.participantTimes;

        // Determine if previous segment is finished
        bool prevSegmentFinished = true;
        DateTime? segmentStartTime = raceStartTime;
        if (previousSegment != null) {
          prevSegmentFinished = participantTimes.containsKey(bibNumber) &&
            participantTimes[bibNumber]!.containsKey(previousSegment);
          if (prevSegmentFinished) {
            segmentStartTime = participantTimes[bibNumber]![previousSegment];
          }
        }

        String? timeElapsed;
        if (finished && segmentStartTime != null) {
          timeElapsed = timeTrackingProvider.getFormattedTime(
            bibNumber,
            widget.segment,
            segmentStartTime,
          );
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF0C3B5B), width: 0.2),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0C3B5B),
              foregroundColor: Colors.white,
              child: Text(
                participant.bibNumber.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              '${participant.firstName} ${participant.lastName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: finished && timeElapsed != null
                ? Text('Time: $timeElapsed', style: const TextStyle(color: Color(0xFF0C3B5B)))
                : null,
            trailing: finished
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(timeElapsed ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.restore, color: Colors.red),
                        tooltip: 'Untrack',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Untrack Time'),
                              content: Text(
                                'Are you sure you want to remove the tracked time for \\${participant.firstName} \\${participant.lastName} (BIB: \\${participant.bibNumber})?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('CANCEL'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    timeTrackingProvider.deleteTime(bibNumber);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('UNTRACK', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: prevSegmentFinished
                        ? () {
                            timeTrackingProvider.trackTime(bibNumber, segments);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C3B5B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text('TRACK'),
                  ),
          ),
        );
      },
    );
  }
}
