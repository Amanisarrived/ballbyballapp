import 'package:ballbyball/screens/mainscreens/homescreen/widgets/banner_container.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/live_match_section.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/trending_section.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/upcoming_section.dart';
import 'package:flutter/material.dart';

class ForYouScreen extends StatelessWidget {
  final ScrollController? scrollController;

  const ForYouScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController, // 👈 attached here
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 25),
                child: BannerContainer(height: 120),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: LiveMatchSection(),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: UpcomingSection(),
              ),
              const SizedBox(height: 24),
              TrendingSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}