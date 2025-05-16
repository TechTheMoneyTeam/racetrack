import 'package:flutter/material.dart';
import '../../../models/race.dart';

class RaceInfoHeader extends StatelessWidget {
  final Race race;

  const RaceInfoHeader({
    super.key,
    required this.race,
  });
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
  
  Color _getStatusColor(RaceStatus status) {
    switch (status) {
      case RaceStatus.notStarted:
        return Colors.orange;
      case RaceStatus.started:
        return Colors.green;
      case RaceStatus.finished:
        return Colors.blue;
    }
  }
  
  void _showRaceDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Race Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Race ID: ${race.id}'),
              const SizedBox(height: 8),
              Text('Race Type: ${race.raceType ?? 'Not specified'}'),
              const SizedBox(height: 8),
              Text('Status: ${race.status.toString().split('.').last}'),
              const SizedBox(height: 8),
              Text('Segments: ${race.segments.join(', ')}'),
              if (race.distances != null) ...[
                const SizedBox(height: 16),
                const Text('Segment Distances:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...race.segments.map((segment) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('$segment: ${race.distances![segment] ?? 0} km'),
                )),
              ],
              if (race.startTime != null) ...[
                const SizedBox(height: 8),
                Text('Started: ${_formatDateTime(race.startTime!)}'),
              ],
              if (race.endTime != null) ...[
                const SizedBox(height: 8),
                Text('Ended: ${_formatDateTime(race.endTime!)}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRaceDetails(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Race: ${race.raceType ?? 'Unknown Type'}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C3B5B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              race.startTime != null
                  ? 'Date: ${_formatDateTime(race.startTime!)}'
                  : 'Not started yet',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Race ID: ${race.id}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Status: ${race.status.toString().split('.').last}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(race.status),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Segments: ${race.segments.join(' → ')}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
