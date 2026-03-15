import 'package:ballbyball/models/rank_caegory.dart';
import 'package:ballbyball/models/ranked_player.dart';
import 'package:ballbyball/service/ranking_service.dart';
import 'package:flutter/material.dart';

const _bg = Color(0xFF080808);
const _surface = Color(0xFF101010);
const _surf2 = Color(0xFF161616);
const _surf3 = Color(0xFF1C1C1C);
const _bdr = Color(0xFF202020);
const _bdr2 = Color(0xFF2C2C2C);
const _accent = Color(0xFFCC0000);
const _tp = Color(0xFFF0F0F0);
const _ts = Color(0xFF404040);
const _tm = Color(0xFF606060);

const _gold = Color(0xFFE8C84A);
const _goldD = Color(0xFF6B5A1A);
const _silver = Color(0xFFA8A8A8);
const _silverD = Color(0xFF484848);
const _bronze = Color(0xFFB87040);
const _bronzeD = Color(0xFF583018);

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});
  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  TournamentConfig? _tournament;
  bool _loaded = false;
  RankCategory _category = RankCategory.batsmen;

  @override
  void initState() {
    super.initState();
    RankingsService.streamCurrentTournament().listen((t) {
      if (!mounted) return;
      setState(() {
        _tournament = t;
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: _accent, strokeWidth: 1.5),
          ),
        ),
      );
    }

    final t = _tournament;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            if (t != null) _TournamentHeader(tournament: t),

            _CategoryTabs(
              selected: _category,
              onTap: (c) => setState(() => _category = c),
            ),

            Expanded(
              child: t == null
                  ? const _Empty(label: 'No active tournament')
                  : _TournamentList(
                      key: ValueKey('${t.id}_${_category.key}'),
                      tournament: t,
                      category: _category,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TournamentHeader extends StatelessWidget {
  final TournamentConfig tournament;
  const _TournamentHeader({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _bdr, width: 0.5)),
      ),
      child: Row(
        children: [
          // Logo
          if (tournament.logoUrl.isNotEmpty)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _surf2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _bdr2, width: 0.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  tournament.logoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.emoji_events_rounded,
                    color: _accent,
                    size: 18,
                  ),
                ),
              ),
            ),

          // Name + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.name,
                  style: const TextStyle(
                    color: _tp,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Player Rankings',
                  style: TextStyle(color: _ts, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  final RankCategory selected;
  final ValueChanged<RankCategory> onTap;
  const _CategoryTabs({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cats = [RankCategory.batsmen, RankCategory.bowlers];
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: cats.map((cat) {
          final sel = selected == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onTap(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: sel ? _accent : _surf2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cat.label,
                  style: TextStyle(
                    color: sel ? Colors.white : _tm,
                    fontSize: 11,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TournamentList extends StatelessWidget {
  final TournamentConfig tournament;
  final RankCategory category;
  const _TournamentList({
    super.key,
    required this.tournament,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RankedPlayer>>(
      stream: RankingsService.streamTournamentRankings(tournament.id, category),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Loader();
        }
        final players = snap.data ?? [];
        if (players.isEmpty) return _Empty(label: '${category.label} rankings');
        return _PlayerList(
          players: players,
          cacheKey: '${tournament.id}_${category.key}',
          category: category,
        );
      },
    );
  }
}

class _PlayerList extends StatelessWidget {
  final List<RankedPlayer> players;
  final String cacheKey;
  final RankCategory category;
  const _PlayerList({
    required this.players,
    required this.cacheKey,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 40),
      itemCount: players.length,
      itemBuilder: (_, i) {
        final p = players[i];
        return RepaintBoundary(
          key: ValueKey('${cacheKey}_${p.rank}'),
          child: p.rank <= 3
              ? _PodiumTile(player: p, category: category)
              : _RegularTile(player: p, category: category),
        );
      },
    );
  }
}

class _PodiumTile extends StatelessWidget {
  final RankedPlayer player;
  final RankCategory category;
  const _PodiumTile({required this.player, required this.category});

  bool get _isBat => category == RankCategory.batsmen;
  bool get _isFirst => player.rank == 1;

  Color get _medal {
    switch (player.rank) {
      case 1:
        return _gold;
      case 2:
        return _silver;
      case 3:
        return _bronze;
      default:
        return _ts;
    }
  }

  Color get _medalDim {
    switch (player.rank) {
      case 1:
        return _goldD;
      case 2:
        return _silverD;
      case 3:
        return _bronzeD;
      default:
        return _ts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _medal;
    final imgSize = _isFirst ? 52.0 : 44.0;

    return Container(
      margin: EdgeInsets.fromLTRB(16, _isFirst ? 4 : 3, 16, 3),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: _isFirst ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withAlpha(_isFirst ? 60 : 30), width: 0.5),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 20,
            child: Text(
              '${player.rank}',
              style: TextStyle(
                color: c,
                fontSize: _isFirst ? 15 : 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Flag circle
          Container(
            width: imgSize,
            height: imgSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _surf3,
              border: Border.all(color: c.withAlpha(70), width: 1),
            ),
            child: ClipOval(
              child: player.flagUrl.isNotEmpty
                  ? Image.network(
                      player.flagUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _avatar(player.name, c),
                    )
                  : _avatar(player.name, c),
            ),
          ),
          const SizedBox(width: 14),

          // Name
          Expanded(
            child: Text(
              player.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _tp,
                fontSize: _isFirst ? 14.5 : 13.5,
                fontWeight: _isFirst ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Stat
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _isBat ? '${player.runs}' : '${player.wickets}',
                style: TextStyle(
                  color: c,
                  fontSize: _isFirst ? 20 : 17,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                _isBat ? 'runs' : 'wkts',
                style: TextStyle(
                  color: _medalDim,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(String name, Color c) => Container(
    color: c.withAlpha(20),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _RegularTile extends StatelessWidget {
  final RankedPlayer player;
  final RankCategory category;
  const _RegularTile({required this.player, required this.category});

  bool get _isBat => category == RankCategory.batsmen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _bdr, width: 0.5)),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 24,
            child: Text(
              '${player.rank}',
              style: const TextStyle(
                color: _ts,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),

          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _surf3,
              border: Border.all(color: _bdr2, width: 0.5),
            ),
            child: ClipOval(
              child: player.flagUrl.isNotEmpty
                  ? Image.network(
                      player.flagUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallback(player.name),
                    )
                  : _fallback(player.name),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              player.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _tm,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.1,
              ),
            ),
          ),

          Row(
            children: [
              Text(
                _isBat ? '${player.runs}' : '${player.wickets}',
                style: const TextStyle(
                  color: _tp,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _isBat ? 'runs' : 'wkts',
                style: const TextStyle(color: _ts, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallback(String name) => Container(
    color: _surf3,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: _ts,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(color: _accent, strokeWidth: 1.5),
    ),
  );
}

class _Empty extends StatelessWidget {
  final String label;
  const _Empty({required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.leaderboard_outlined, color: _ts, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: _tm,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
