import 'package:flutter/material.dart';

class TimerCompleteDialog extends StatefulWidget {
  final String itemId;
  final String itemTitle;
  final VoidCallback onDismiss;
  final VoidCallback onStopAlarm; // Add this callback

  const TimerCompleteDialog({
    super.key,
    required this.itemId,
    required this.itemTitle,
    required this.onDismiss,
    required this.onStopAlarm, // Make it required
  });

  @override
  State<TimerCompleteDialog> createState() => _TimerCompleteDialogState();
}

class _TimerCompleteDialogState extends State<TimerCompleteDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, double scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.alarm,
                      color: Colors.orange,
                      size: 64,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              '⏰ Timer Complete!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Item name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '"${widget.itemTitle}"',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // OK Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onStopAlarm(); // Stop the alarm first
                  widget.onDismiss(); // Then dismiss
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
