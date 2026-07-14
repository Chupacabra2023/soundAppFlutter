import 'package:flutter/material.dart';

/// Small dismissible bottom banner asking the user to rate the app.
/// Tapping any of the 5 stars triggers the platform's native in-app rating
/// flow (the user picks the actual star count there and it submits
/// automatically — stores don't allow apps to submit a rating themselves).
class RateAppBanner extends StatelessWidget {
  const RateAppBanner({
    super.key,
    required this.message,
    required this.onRate,
    required this.onDismiss,
  });

  final String message;
  final ValueChanged<int> onRate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          color: Colors.blueGrey[800],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          final starValue = index + 1;
                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => onRate(starValue),
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(Icons.star_rounded, color: Colors.amber, size: 26),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
