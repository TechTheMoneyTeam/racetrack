import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/race_provider.dart';
import '../../providers/participant_provider.dart';
import 'add_participant_screen.dart';
import '../../models/race.dart';

class RaceSetupScreen extends StatefulWidget {
  final void Function(String raceId)? onRaceCreated;

  const RaceSetupScreen({super.key, this.onRaceCreated});

  @override
  _RaceSetupScreenState createState() => _RaceSetupScreenState();
}

class _RaceSetupScreenState extends State<RaceSetupScreen> {
  bool _isInitialized = false;
  TextEditingController _searchController = TextEditingController();
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
        // If we have a current race, load its participants
        await raceProvider.loadRace(currentRaceId);
        _loadParticipantsForRace(currentRaceId);
      } else if (raceProvider.races.isNotEmpty) {
        // If no current race, but we have races, select the first one
        final firstRaceId = raceProvider.races.first.id;
        await raceProvider.setCurrentRace(firstRaceId);
        _loadParticipantsForRace(firstRaceId);
      } else {
        // No races at all, create one
        _initializeRace();
      }
    } catch (e) {
      print("Error loading existing races: $e");
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

  Future<void> _initializeRace() async {
    if (_isInitialized) return;

    final raceProvider = Provider.of<RaceProvider>(context, listen: false);

    if (raceProvider.currentRace != null) {
      print("Race already exists with ID: ${raceProvider.currentRace!.id}");

      if (mounted) {
        final participantProvider = Provider.of<ParticipantProvider>(
          context,
          listen: false,
        );
        participantProvider.loadParticipants(raceProvider.currentRace!.id);
      }

      setState(() {
        _isInitialized = true;
      });

      // Call the onRaceCreated callback if provided
      if (widget.onRaceCreated != null) {
        widget.onRaceCreated!(raceProvider.currentRace!.id);
      }

      return;
    }

    // Create a new race if none exists
    try {
      await raceProvider.createRace(['swim', 'bike', 'run']);
      if (!mounted) return;

      if (raceProvider.currentRace != null) {
        print("Race created with ID: ${raceProvider.currentRace!.id}");

        final participantProvider = Provider.of<ParticipantProvider>(
          context,
          listen: false,
        );
        participantProvider.loadParticipants(raceProvider.currentRace!.id);

        if (widget.onRaceCreated != null) {
          widget.onRaceCreated!(raceProvider.currentRace!.id);
        }

        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print("Error creating race: $e");
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

  void _navigateToAddParticipant() {
    final raceProvider = Provider.of<RaceProvider>(context, listen: false);
    final raceId = raceProvider.currentRaceId;

    if (raceId == null) {
      print("⚠️ Warning: Attempting to add participant without a race ID");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a race first or create a new one.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print("🚀 Navigating to AddParticipantScreen with raceId: $raceId");

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddParticipantScreen(raceId: raceId),
          ),
        )
        .then((result) {
          print("📍 Returned from AddParticipantScreen with result: $result");

          if (result == true) {
            print("🔄 Forcing reload of participants for race: $raceId");
            Provider.of<ParticipantProvider>(
              context,
              listen: false,
            ).loadParticipants(raceId);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Participant added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        })
        .catchError((error) {
          print("❌ Navigation error: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigation error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  Future<void> _createNewRace() async {
    try {
      final raceProvider = Provider.of<RaceProvider>(context, listen: false);
      await raceProvider.createRace(['swim', 'bike', 'run']);

      if (!mounted) return;

      if (raceProvider.currentRace != null) {
        print("New race created with ID: ${raceProvider.currentRace!.id}");

        final raceId = raceProvider.currentRace!.id;
        _loadParticipantsForRace(raceId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New race created: $raceId'),
            backgroundColor: const Color(0xFF0C3B5B),
          ),
        );
      }
    } catch (e) {
      print("Error creating new race: $e");
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
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Left side - Name and bib number
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
                ],
              ),
            ),
            // Right side - Gender and age
            Expanded(
              flex: 2,
              child: Text(
                'Participant',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            // Action buttons
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

  @override
  Widget build(BuildContext context) {
    return Consumer<RaceProvider>(
      builder: (context, raceProvider, _) {
        final currentRaceId = raceProvider.currentRaceId;

        print("🔍 RaceSetupScreen build with selectedRaceId: $currentRaceId");

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: Column(
            children: [
              // Header with title
              Container(
                color: const Color(0xFF0C3B5B),
                padding: const EdgeInsets.only(top: 40, bottom: 16),
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

              // Race Selection Dropdown
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child:
                          _isLoadingRaces
                              ? const Center(child: CircularProgressIndicator())
                              : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.0),
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
                                                  race.id == currentRaceId,
                                            )
                                            ? currentRaceId
                                            : null,
                                    hint: const Text('Select Race'),
                                    items:
                                        raceProvider.races.map((Race race) {
                                          return DropdownMenuItem<String>(
                                            value: race.id,
                                            child: Text(
                                              'Race ID: ${race.id}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null &&
                                          newValue != currentRaceId) {
                                        raceProvider.setCurrentRace(newValue);
                                        _loadParticipantsForRace(newValue);
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
                        onPressed: _createNewRace,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C3B5B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('New Race'),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                          ),
                          onChanged: (value) {
                            // This will rebuild with search applied
                            setState(() {});
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            // You can trigger search here as well
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Refreshing participants list'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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

              // Race info chip
              // if (currentRaceId != null)
              //   Padding(
              //     padding: const EdgeInsets.symmetric(horizontal: 12.0),
              //     child: Row(
              //       children: [
              //         Chip(
                      
              //           label: Text('Current race: $currentRaceId'),
              //           backgroundColor: const Color(0xFF0C3B5B),
              //           labelStyle: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
              //         ),
              //       ],
              //     ),
              //   ),

              // Participant list
              Expanded(
                child: Consumer<ParticipantProvider>(
                  builder: (context, participantProvider, child) {
                    if (participantProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
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
                            Text('Error: ${participantProvider.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (currentRaceId != null) {
                                  participantProvider.loadParticipants(
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
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add participants to get started',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    // Filter participants based on search text
                    final searchText = _searchController.text.toLowerCase();
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

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      itemCount: filteredParticipants.length,
                      itemBuilder: (context, index) {
                        final participant = filteredParticipants[index];
                        return _buildParticipantItem(participant);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
