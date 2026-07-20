import 'package:flutter/material.dart';

import '../config/app_colors.dart';

/// A shimmer loading placeholder that mimics a pharmacy card.
class ShimmerLoading extends StatefulWidget {
  final int itemCount;

  const ShimmerLoading({super.key, this.itemCount = 4});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: widget.itemCount,
          itemBuilder: (_, __) => _ShimmerCard(opacity: _animation.value),
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double opacity;

  const _ShimmerCard({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title line
            Row(
              children: [
                _ShimmerBox(width: 20, height: 20, opacity: opacity),
                const SizedBox(width: 8),
                _ShimmerBox(width: 160, height: 16, opacity: opacity),
                const Spacer(),
                _ShimmerBox(width: 40, height: 18, opacity: opacity),
              ],
            ),
            const SizedBox(height: 10),
            // Subtitle line
            _ShimmerBox(width: 100, height: 12, opacity: opacity),
            const SizedBox(height: 6),
            // Distance line
            _ShimmerBox(width: 80, height: 12, opacity: opacity),
            const SizedBox(height: 14),
            // Buttons row
            Row(
              children: [
                Expanded(
                  child: _ShimmerBox(width: double.infinity, height: 36, opacity: opacity),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ShimmerBox(width: double.infinity, height: 36, opacity: opacity),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider.withOpacity(opacity),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
