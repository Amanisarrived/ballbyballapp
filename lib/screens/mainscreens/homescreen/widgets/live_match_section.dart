import 'package:ballbyball/models/live_score_match.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/live_match_card.dart';
import 'package:ballbyball/service/live_match_service.dart';
import 'package:flutter/material.dart';

class LiveMatchSection extends StatefulWidget {
  const LiveMatchSection({super.key});

  @override
  State<LiveMatchSection> createState() => _LiveMatchSectionState();
}

class _LiveMatchSectionState extends State<LiveMatchSection> {
  late final Stream<FeaturedMatch?> _stream = LiveMatchService.instance
      .streamFeaturedMatch();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FeaturedMatch?>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        return LiveMatchCard(
          key: const ValueKey('live_match_card'),
          match: snapshot.data!,
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Column(
        children: [
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(6),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(child: _teamSkeleton()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(10),
                    ),
                  ),
                ),
                Expanded(child: _teamSkeleton()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamSkeleton() {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(15),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 50,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 60,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
