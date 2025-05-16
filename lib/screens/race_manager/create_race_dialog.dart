import 'package:flutter/material.dart';
import 'widgets/segment_card.dart';

class CreateRaceDialog extends StatefulWidget {
  const CreateRaceDialog({super.key});

  @override
  _CreateRaceDialogState createState() => _CreateRaceDialogState();
}

class _CreateRaceDialogState extends State<CreateRaceDialog> {
  final String selectedRaceType = 'Triathlon';
  final List<String> segments = ['swim', 'bike', 'run'];
  final Map<String, double> distances = {
    'swim': 1.0,
    'bike': 1.0,
    'run': 1.0,
  };
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Triathlon'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Race Type: Triathlon', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            const Text('Distance (km):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            _buildSegmentCard(
              'swim', 
              'Swimming', 
              Icons.pool, 
              Colors.blue.shade400
            ),
            
            _buildSegmentCard(
              'bike', 
              'Cycling', 
              Icons.directions_bike, 
              Colors.green.shade500
            ),
            
            _buildSegmentCard(
              'run', 
              'Running', 
              Icons.directions_run, 
              Colors.orange.shade400
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            final validatedDistances = <String, double>{};
            for (var segment in segments) {
              validatedDistances[segment] = distances[segment] ?? 1.0;
            }
            
            Navigator.of(context).pop({
              'raceType': selectedRaceType,
              'segments': segments,
              'distances': validatedDistances,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0C3B5B),
            foregroundColor: Colors.white,
          ),
          child: const Text('CREATE'),
        ),
      ],
    );
  }
  
  Widget _buildSegmentCard(String segment, String label, IconData icon, Color color) {
    return SegmentCard(
      segmentId: segment,
      segmentName: label,
      icon: icon,
      color: color,
      distance: distances[segment] ?? 1.0,
      onDistanceChanged: (segmentId, newValue) {
        setState(() {
          distances[segmentId] = newValue;
        });
      },
    );
  }
}
