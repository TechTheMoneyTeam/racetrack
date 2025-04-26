import 'package:flutter/material.dart';

class TimeStampButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String segment;
  final bool isActive;

  const TimeStampButton({
    super.key,
    required this.onPressed,
    required this.segment,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isActive ? onPressed : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        backgroundColor: _getSegmentColor(segment),
        disabledBackgroundColor: Colors.grey.shade300,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getSegmentIcon(segment)),
          const SizedBox(width: 8),
          Text(
            'Track ${segment.toUpperCase()}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  IconData _getSegmentIcon(String segment) {
    switch (segment.toLowerCase()) {
      case 'swim':
        return Icons.pool;
      case 'bike':
        return Icons.directions_bike;
      case 'run':
        return Icons.directions_run;
      default:
        return Icons.timer;
    }
  }

  Color _getSegmentColor(String segment) {
    switch (segment.toLowerCase()) {
      case 'swim':
        return Colors.blue;
      case 'bike':
        return Colors.green;
      case 'run':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}