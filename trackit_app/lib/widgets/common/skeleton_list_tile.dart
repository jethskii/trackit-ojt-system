import 'package:flutter/material.dart';
import 'shimmer_box.dart';

/// A shimmering placeholder shaped like a typical list row (avatar +
/// two lines of text), used while a screen's first fetch is in flight.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: 44,
            height: 44,
            borderRadius: BorderRadius.circular(22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(height: 14),
                const SizedBox(height: 8),
                ShimmerBox(
                  height: 12,
                  width: MediaQuery.sizeOf(context).width * 0.4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A list of [count] skeleton rows, for use as a screen's loading state.
class SkeletonList extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.count = 5,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: count,
      itemBuilder: (context, index) => const SkeletonListTile(),
    );
  }
}
