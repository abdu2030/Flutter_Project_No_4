import 'package:flutter/material.dart';
import 'package:eduvox/shared/theme/app_theme.dart'; // Adjust path if needed

class RatingDialog extends StatefulWidget {
  final Function(double) onSubmitted;

  const RatingDialog({super.key, required this.onSubmitted});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate this Course'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How would you rate your experience?'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    _rating = index + 1.0;
                  });
                },
                icon: Icon(
                  index < _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 32,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            _rating > 0 ? '$_rating Stars' : 'Tap a star',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _rating == 0
              ? null
              : () {
                  widget.onSubmitted(_rating);
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
