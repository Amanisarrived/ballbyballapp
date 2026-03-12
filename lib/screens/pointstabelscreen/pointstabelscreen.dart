import 'package:ballbyball/models/pointes_tabel_model.dart';
import 'package:ballbyball/service/pointstableservice.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const _surface = Color(0xFF0F0F0F);
const _line    = Color(0xFF1A1A1A);
const _red     = Color(0xFFCC0000);

class Pointstabelscreen extends StatelessWidget {
  const Pointstabelscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: PointsTableService.stream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }

        if (!snap.hasData || snap.data?.data() == null) {
          return const _EmptyState();
        }

        final table = PointsTable.fromDoc(snap.data!);
        if (!table.isVisible) return const _InactiveState();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TournamentHeader(name: table.tournamentName),
            const SizedBox(height: 20,),
            ...table.groups.map((group) => _GroupTable(
              group: group,
              showGroupName: table.isGroupStage,
            )),
          ],
        );
      },
    );
  }
}

class _InactiveState extends StatelessWidget {
  const _InactiveState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _red.withAlpha(10),
                    border: Border.all(color: _red.withAlpha(30)),
                  ),
                ),
                const Icon(
                  Icons.sports_cricket_rounded,
                  color: _red,
                  size: 26,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Tournament Not Started',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The points table will be available\nonce the tournament begins.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(45),
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: Container(height: 1, color: _line)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'STAY TUNED',
                    style: TextStyle(
                      color: Colors.white.withAlpha(20),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Expanded(child: Container(height: 1, color: _line)),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(5),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.white.withAlpha(10)),
              ),
              child: Text(
                'Check Upcoming Matches →',
                style: TextStyle(
                  color: Colors.white.withAlpha(50),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: _red,
                strokeWidth: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Loading standings...',
              style: TextStyle(
                color: Colors.white.withAlpha(30),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TournamentHeader extends StatelessWidget {
  final String name;
  const _TournamentHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Container(
            width: 2, height: 12,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _red,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withAlpha(160),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTable extends StatelessWidget {
  final TableGroup group;
  final bool showGroupName;

  const _GroupTable({required this.group, required this.showGroupName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showGroupName && group.groupName.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _line)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 2, height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _red,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Text(
                    group.groupName.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withAlpha(50),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          _TableHeader(),
          Container(height: 1, color: _line),
          if (group.teams.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No standings yet',
                    style: TextStyle(
                        color: Colors.white.withAlpha(20), fontSize: 13)),
              ),
            )
          else
            ...group.teams.asMap().entries.map((e) {
              return _TeamRow(
                team: e.value,
                position: e.key + 1,
                isLast: e.key == group.teams.length - 1,
              );
            }),
        ],
      ),
    );
  }
}


class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 18),
          const SizedBox(width: 10),
          const SizedBox(width: 30),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('TEAM',
                style: TextStyle(
                    color: Colors.white24,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3)),
          ),
          ...[
            _ColW(' P',  28),
            _ColW(' W',  28),
            _ColW(' L',  28),
            _ColW('PTS', 32),
            _ColW('NRR', 46),
          ].map((c) => SizedBox(
            width: c.width,
            child: Text(c.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0)),
          )),
        ],
      ),
    );
  }
}

class _ColW {
  final String label;
  final double width;
  const _ColW(this.label, this.width);
}


class _TeamRow extends StatelessWidget {
  final TeamStanding team;
  final int position;
  final bool isLast;

  const _TeamRow({
    required this.team,
    required this.position,
    required this.isLast,
  });

  bool get _qualifies => position <= 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: _qualifies ? _red.withAlpha(8) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: Text('$position',
                    style: TextStyle(
                        color: _qualifies ? _red : Colors.white.withAlpha(22),
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(5),
                  border: Border.all(
                    color: _qualifies ? _red.withAlpha(55) : Colors.white.withAlpha(14),
                    width: _qualifies ? 1.5 : 1,
                  ),
                  boxShadow: _qualifies
                      ? [BoxShadow(color: _red.withAlpha(25), blurRadius: 8)]
                      : [],
                ),
                child: ClipOval(
                  child: team.logo.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: team.logo,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _LogoFb(name: team.name),
                  )
                      : _LogoFb(name: team.name),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(team.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withAlpha(_qualifies ? 230 : 130),
                        fontSize: 12,
                        fontWeight: _qualifies ? FontWeight.w700 : FontWeight.w500)),
              ),
              ...[team.played, team.won, team.lost]
                  .map((v) => SizedBox(
                width: 28,
                child: Text(v.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withAlpha(45),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              )),
              SizedBox(
                width: 32,
                child: Text(team.points.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _qualifies ? Colors.white : Colors.white.withAlpha(160),
                        fontSize: 13,
                        fontWeight: FontWeight.w900)),
              ),
              SizedBox(
                width: 46,
                child: Text(
                  team.nrr >= 0
                      ? '+${team.nrr.toStringAsFixed(3)}'
                      : team.nrr.toStringAsFixed(3),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: team.nrr >= 0
                          ? Colors.greenAccent.withAlpha(170)
                          : Colors.redAccent.withAlpha(170),
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Container(height: 1, color: _line),
      ],
    );
  }
}


class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _line),
              ),
              child: Icon(Icons.table_chart_rounded,
                  color: Colors.white.withAlpha(20), size: 28),
            ),
            const SizedBox(height: 16),
            Text('No standings yet',
                style: TextStyle(
                    color: Colors.white.withAlpha(40),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Check back during a tournament',
                style: TextStyle(
                    color: Colors.white.withAlpha(20), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}


class _LogoFb extends StatelessWidget {
  final String name;
  const _LogoFb({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withAlpha(6),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}