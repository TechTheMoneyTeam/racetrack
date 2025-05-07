import 'package:flutter/material.dart';
import 'widgets/segment_card.dart';

class CreateRaceDialog extends StatefulWidget {
  final String raceType;
  final List<String> segments;
  final Map<String, double> initialDistances;
  final Map<String, String> segmentLabels;
  final Map<String, IconData> segmentIcons;
  final Map<String, Color> segmentColors;

  const CreateRaceDialog({
    super.key,
    this.raceType = 'Triathlon',
    this.segments = const ['swim', 'bike', 'run'],
    this.initialDistances = const {'swim': 1.0, 'bike': 1.0, 'run': 1.0},
    this.segmentLabels = const {
      'swim': 'Swimming',
      'bike': 'Cycling',
      'run': 'Running',
    },
    this.segmentIcons = const {
      'swim': Icons.pool,
      'bike': Icons.directions_bike,
      'run': Icons.directions_run,
    },
    this.segmentColors = const {
      'swim': Colors.blue,
      'bike': Colors.green,
      'run': Colors.orange,
    },
  });

  @override
  State<CreateRaceDialog> createState() => _CreateRaceDialogState();
}

class _CreateRaceDialogState extends State<CreateRaceDialog> {
  late Map<String, double> distances;

  @override
  void initState() {
    super.initState();
    // Initialize with default or provided distances
    distances = Map.from(widget.initialDistances);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create New ${widget.raceType}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Race Type: ${widget.raceType}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Distance (km):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...widget.segments.map(
              (segment) => _buildSegmentCard(
                segment,
                widget.segmentLabels[segment] ?? segment,
                widget.segmentIcons[segment] ?? Icons.flag,
                widget.segmentColors[segment] ?? Colors.grey,
              ),
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
            Navigator.of(context).pop({
              'raceType': widget.raceType,
              'segments': widget.segments,
              'distances': distances,
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

  Widget _buildSegmentCard(
    String segment,
    String label,
    IconData icon,
    Color color,
  ) {
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
