import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/participant.dart';
import '../../../providers/participant_provider.dart';

class ParticipantListItem extends StatelessWidget {
  final Participant participant;
  final String? raceId;
  
  const ParticipantListItem({
    super.key,
    required this.participant,
    this.raceId,
  });

  @override
  Widget build(BuildContext context) {
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
            Expanded(
              flex: 2,
              child: Text(
                'Participant',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () async {
                    final currentRaceId = raceId ?? participant.raceId;

                    try {
                      await Provider.of<ParticipantProvider>(
                        context,
                        listen: false,
                      ).deleteParticipant(participant.bibNumber, currentRaceId);
                      
                      if (context.mounted) {
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
                      if (context.mounted) {
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
}
