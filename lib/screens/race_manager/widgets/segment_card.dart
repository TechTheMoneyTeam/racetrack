import 'package:flutter/material.dart';

class SegmentCard extends StatelessWidget {
  final String segmentId;
  final String segmentName;
  final IconData icon;
  final Color color;
  final double distance;
  final Function(String, double) onDistanceChanged;

  const SegmentCard({
    super.key,
    required this.segmentId,
    required this.segmentName,
    required this.icon,
    required this.color,
    required this.distance,
    required this.onDistanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segmentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Distance (km)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: distance.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final newValue = double.tryParse(value) ?? 0.0;
                  onDistanceChanged(segmentId, newValue);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
