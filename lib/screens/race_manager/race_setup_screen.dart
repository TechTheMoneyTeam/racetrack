import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/race_provider.dart';
import '../../providers/participant_provider.dart';
import '../participant/add_participant_screen.dart';
import '../../models/race.dart';
import 'create_race_dialog.dart';

class RaceSetupScreen extends StatefulWidget {
  final void Function(String raceId)? onRaceCreated;

  const RaceSetupScreen({super.key, this.onRaceCreated});

  @override
  _RaceSetupScreenState createState() => _RaceSetupScreenState();
}

class _RaceSetupScreenState extends State<RaceSetupScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingRaces = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingRaces();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRaces() async {
    setState(() {
      _isLoadingRaces = true;
    });

    try {
      final raceProvider = Provider.of<RaceProvider>(context, listen: false);
      await raceProvider.getAllRaces();

      if (!mounted) return;

      final currentRaceId = raceProvider.currentRaceId;
      if (currentRaceId != null) {
        await raceProvider.loadRace(currentRaceId);
        _loadParticipantsForRace(currentRaceId);
      } else if (raceProvider.races.isNotEmpty) {
        final firstRaceId = raceProvider.races.first.id;
        await raceProvider.setCurrentRace(firstRaceId);
        _loadParticipantsForRace(firstRaceId);
      }    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading races: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRaces = false;
        });
      }
    }
  }

  void _loadParticipantsForRace(String raceId) {
    final participantProvider = Provider.of<ParticipantProvider>(
      context,
      listen: false,
    );
    participantProvider.loadParticipants(raceId);
  }

  Future<void> _showCreateRaceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const CreateRaceDialog(),
    ).then((result) async {
      if (result != null) {
        try {
          final raceProvider = Provider.of<RaceProvider>(
            context,
            listen: false,
          );
          
          Map<String, double> distancesMap = {};
          if (result['distances'] != null) {
            final distancesData = result['distances'] as Map;
            distancesData.forEach((key, value) {
              if (key is String) {
                double doubleValue;
                if (value is double) {
                  doubleValue = value;
                } else if (value is int) {
                  doubleValue = value.toDouble();
                } else if (value is String) {
                  doubleValue = double.tryParse(value) ?? 0.0;
                } else {
                  doubleValue = 0.0;
                }
                distancesMap[key] = doubleValue;
              }
            });
          }
          
          await raceProvider.createRace(
            result['segments'],
            distances: distancesMap,
            raceType: result['raceType'],
          );

          if (!mounted) return;
          if (raceProvider.currentRace != null) {
            final raceId = raceProvider.currentRace!.id;
            _loadParticipantsForRace(raceId);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('New race created: $raceId'),
                backgroundColor: const Color(0xFF0C3B5B),
              ),
            );
            if (widget.onRaceCreated != null) {
              widget.onRaceCreated!(raceId);
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error creating race: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }

  void _navigateToAddParticipant() {
    final raceProvider = Provider.of<RaceProvider>(context, listen: false);
    final raceId = raceProvider.currentRaceId;    if (raceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a race first or create a new one.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddParticipantScreen(raceId: raceId),
          ),
        )        .then((result) {
          if (result == true) {
            Provider.of<ParticipantProvider>(
              context,
              listen: false,
            ).loadParticipants(raceId);


            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Participant added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        })        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigation error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  Widget _buildParticipantItem(participant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${participant.firstName} ${participant.lastName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '#${participant.bibNumber}',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Participant',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () async {
                    final raceProvider = Provider.of<RaceProvider>(
                      context,
                      listen: false,
                    );
                    final raceId = raceProvider.currentRaceId;
                    if (raceId == null) return;

                    try {
                      await Provider.of<ParticipantProvider>(
                        context,
                        listen: false,
                      ).deleteParticipant(participant.bibNumber, raceId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${participant.firstName} was removed',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting participant: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceCard(
    String title,
    IconData icon,
    double distance,
    String unit,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 5),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$distance $unit',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RaceProvider>(      builder: (context, raceProvider, _) {
        final currentRaceId = raceProvider.currentRaceId;
        final currentRace = raceProvider.currentRace;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  color: const Color(0xFF0C3B5B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  width: double.infinity,
                  child: const Text(
                    'Race Setup',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child:
                                    _isLoadingRaces
                                        ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                        : Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              isExpanded: true,
                                              value:
                                                  raceProvider.races.any(
                                                        (race) =>
                                                            race.id ==
                                                            currentRaceId,
                                                      )
                                                      ? currentRaceId
                                                      : null,
                                              hint: const Text('Select Race'),
                                              items:
                                                  raceProvider.races.map((
                                                    Race race,
                                                  ) {
                                                    String displayText =
                                                        'Race ID: ${race.id}';
                                                    if (race.raceType != null) {
                                                      displayText =
                                                          '${race.raceType} - $displayText';
                                                    }

                                                    return DropdownMenuItem<
                                                      String
                                                    >(
                                                      value: race.id,
                                                      child: Text(
                                                        displayText,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    );
                                                  }).toList(),
                                              onChanged: (String? newValue) {
                                                if (newValue != null &&
                                                    newValue != currentRaceId) {
                                                  raceProvider.setCurrentRace(
                                                    newValue,
                                                  );
                                                  _loadParticipantsForRace(
                                                    newValue,
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: ElevatedButton(
                                  onPressed: _showCreateRaceDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0C3B5B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('New Race'),
                                ),
                              ),
                            ],
                          ),
                        ),                        if (currentRace != null && currentRace.raceType != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0C3B5B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Race Type: ${currentRace.raceType}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (currentRace.distances != null)
                                    ...currentRace.segments.map((segment) {                                      String displaySegment = segment;
                                      if (segment == 'run' &&
                                          currentRace.segments
                                                  .where((s) => s == 'run')
                                                  .length >
                                              1 &&
                                          currentRace.segments.indexOf(
                                                segment,
                                              ) >
                                              0) {
                                        displaySegment = 'run_2';
                                      }

                                      double? distance =
                                          currentRace
                                              .distances?[displaySegment];
                                      if (distance != null) {
                                        return Text(
                                          '${segment[0].toUpperCase()}${segment.substring(1)}: $distance km',
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    }),
                                ],
                              ),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      hintText: 'Search participant',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                    ),                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: ElevatedButton(
                                  onPressed: _navigateToAddParticipant,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0C3B5B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Add Participant'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: OutlinedButton(
                                  onPressed: () {
                                    if (currentRaceId != null) {
                                      _loadParticipantsForRace(currentRaceId);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Refreshing participants list',
                                          ),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.grey),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    'Refresh',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (currentRace != null &&
                            currentRace.distances != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8.0,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(
                                    0xFF0C3B5B,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.sports,
                                        color: Color(0xFF0C3B5B),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'TRIATHLON DISTANCES',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 0.5,
                                          color: const Color(0xFF0C3B5B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildDistanceCard(
                                        'SWIM',
                                        Icons.pool,
                                        currentRace.distances?['swim'] ?? 0.0,
                                        'km',
                                        Colors.blue,
                                      ),
                                      _buildDistanceCard(
                                        'BIKE',
                                        Icons.directions_bike,
                                        currentRace.distances?['bike'] ?? 0.0,
                                        'km',
                                        Colors.green,
                                      ),
                                      _buildDistanceCard(
                                        'RUN',
                                        Icons.directions_run,
                                        currentRace.distances?['run'] ?? 0.0,
                                        'km',
                                        Colors.orange,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Consumer<ParticipantProvider>(
                            builder: (context, participantProvider, child) {
                              if (participantProvider.isLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (participantProvider.error != null) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Error: ${participantProvider.error}',
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (currentRaceId != null) {
                                            participantProvider
                                                .loadParticipants(
                                                  currentRaceId,
                                                );
                                          }
                                        },
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (participantProvider.participants.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.groups_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No participants yet',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add participants to get started',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final searchText =
                                  _searchController.text.toLowerCase();
                              final filteredParticipants =
                                  searchText.isEmpty
                                      ? participantProvider.participants
                                      : participantProvider.participants
                                          .where(
                                            (p) =>
                                                '${p.firstName} ${p.lastName}'
                                                    .toLowerCase()
                                                    .contains(searchText) ||
                                                p.bibNumber.toString().contains(
                                                  searchText,
                                                ),
                                          )
                                          .toList();

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                child: ListView.builder(
                                  itemCount: filteredParticipants.length,
                                  itemBuilder: (context, index) {
                                    final participant =
                                        filteredParticipants[index];
                                    return _buildParticipantItem(participant);
                                  },
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
