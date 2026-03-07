import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SermonCardSkeleton extends StatelessWidget {
  const SermonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badges
              Row(
                children: [
                  Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12))),
                  const SizedBox(width: 8),
                  Container(
                      width: 80,
                      height: 20,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12))),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Container(
                  width: double.infinity, height: 18, color: Colors.white),
              const SizedBox(height: 6),
              Container(width: 150, height: 18, color: Colors.white),
              const SizedBox(height: 8),
              // Description
              Container(
                  width: double.infinity, height: 12, color: Colors.white),
              const SizedBox(height: 4),
              Container(width: 200, height: 12, color: Colors.white),
              const SizedBox(height: 16),
              // Meta Row
              Row(
                children: [
                  Container(width: 14, height: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Container(width: 60, height: 10, color: Colors.white),
                ],
              ),
              const SizedBox(height: 16),
              // Button
              Container(
                width: double.infinity,
                height: 45,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
