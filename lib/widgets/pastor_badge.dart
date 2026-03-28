import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class SeniorPastorBadge extends StatelessWidget {
  final String speaker;

  const SeniorPastorBadge({super.key, required this.speaker});

  @override
  Widget build(BuildContext context) {
    if (speaker != AppConstants.seniorPastorName) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800), // Bright yellow/gold
        borderRadius: BorderRadius.circular(20), // Pill shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium, // Crown icon
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            AppConstants.seniorPastorTitle.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900, // Replaced .black with .w900
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
