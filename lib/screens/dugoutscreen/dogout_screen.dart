import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';

// ── Tokens ───────────────────────────────────────────────────
class _C {
  static const bg       = Color(0xFF0A0A0A);
  static const surface  = Color(0xFF111111);
  static const border   = Color(0xFF1C1C1C);
  static const red      = Color(0xFFE53935);
  static const redFade  = Color(0x1AE53935); // red @ 10%
  static const white    = Color(0xFFFFFFFF);
  static const t1       = Color(0xFFEEEEEE); // primary text
  static const t2       = Color(0xFF888888); // secondary
  static const t3       = Color(0xFF444444); // muted
}

// ─────────────────────────────────────────────────────────────
//  DugoutScreen
// ─────────────────────────────────────────────────────────────
class DugoutScreen extends StatefulWidget {
  const DugoutScreen({super.key});
  @override
  State<DugoutScreen> createState() => _DugoutScreenState();
}

class _DugoutScreenState extends State<DugoutScreen> {
  final _db = FirebaseFirestore.instance;
  late final Stream<DocumentSnapshot> _postStream;
  late final Stream<QuerySnapshot>    _commentsStream;

  DocumentReference   get _postRef      => _db.collection('dugout_post').doc('featured');
  CollectionReference get _commentsRef  => _postRef.collection('comments');
  CollectionReference get _reactionsRef => _postRef.collection('reactions');

  @override
  void initState() {
    super.initState();
    _postStream     = _postRef.snapshots();
    _commentsStream = _postRef.collection('comments').orderBy('createdAt', descending: true).snapshots();
    // Show rules popup only on first visit
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowRules());
  }

  Future<void> _maybeShowRules() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('dugout_rules_seen') ?? false;
    if (seen || !mounted) return;
    await prefs.setBool('dugout_rules_seen', true);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => const _RulesDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<AuthProvider, bool>((a) => a.isLoggedIn);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            _AppBar(isLoggedIn: isLoggedIn, onProfile: _openProfile),
            Expanded(
              child: _Body(
                postStream:     _postStream,
                commentsStream: _commentsStream,
                reactionsRef:   _reactionsRef,
                postRef:        _postRef,
                db:             _db,
              ),
            ),
            _InputBar(postRef: _postRef, commentsRef: _commentsRef),
          ],
        ),
      ),
    );
  }

  void _openProfile() {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(auth: auth),
    );
  }
}


class _AppBar extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onProfile;
  const _AppBar({required this.isLoggedIn, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: _C.bg,
      padding: EdgeInsets.fromLTRB(20, top + 12, 16, 12),
      child: Row(
        children: [
          // Title
          const Text(
            'Dugout',
            style: TextStyle(
              color: _C.t1,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(width: 6),
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: _C.red,
              shape: BoxShape.circle,
            ),
          ),
          const Spacer(),
          if (isLoggedIn) _AvatarBtn(onTap: onProfile),
          if (!isLoggedIn)
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => const _SignInSheet(),
              ),
              child: const Text(
                'Sign in',
                style: TextStyle(
                  color: _C.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AvatarBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = context.select<AuthProvider, String>((a) => a.userPhoto);
    final name  = context.select<AuthProvider, String>((a) => a.userName);
    return GestureDetector(
      onTap: onTap,
      child: _Avatar(photo: photo, name: name, r: 16),
    );
  }
}


class _Body extends StatelessWidget {
  final Stream<DocumentSnapshot> postStream;
  final Stream<QuerySnapshot>    commentsStream;
  final CollectionReference      reactionsRef;
  final DocumentReference        postRef;
  final FirebaseFirestore        db;

  const _Body({
    required this.postStream,
    required this.commentsStream,
    required this.reactionsRef,
    required this.postRef,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: postStream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                color: _C.red, strokeWidth: 1.5,
              ),
            ),
          );
        }
        if (!snap.data!.exists) {
          return const Center(
            child: Text('Nothing here yet.',
                style: TextStyle(color: _C.t3, fontSize: 14)),
          );
        }

        final d             = snap.data!.data() as Map<String, dynamic>;
        final reactions     = Map<String, dynamic>.from(d['reactions'] ?? {});
        final commentsCount = d['commentsCount'] ?? 0;
        final imageUrl      = d['imageUrl'] ?? '';
        final postText      = d['text'] ?? '';

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Post card
            SliverToBoxAdapter(
              child: _PostCard(
                text:          postText,
                imageUrl:      imageUrl,
                reactions:     reactions,
                commentsCount: commentsCount,
                reactionsRef:  reactionsRef,
                postRef:       postRef,
                db:            db,
              ),
            ),


            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: const TextStyle(
                        color: _C.t2,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· $commentsCount',
                      style: const TextStyle(color: _C.t3, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Comments
            _CommentsSliver(stream: commentsStream),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Post Card
// ─────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final String text, imageUrl;
  final Map<String, dynamic> reactions;
  final int commentsCount;
  final CollectionReference reactionsRef;
  final DocumentReference   postRef;
  final FirebaseFirestore   db;

  const _PostCard({
    required this.text,
    required this.imageUrl,
    required this.reactions,
    required this.commentsCount,
    required this.reactionsRef,
    required this.postRef,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
              ),
            ),

          if (imageUrl.isNotEmpty) const SizedBox(height: 14),

          // Featured label
          Row(
            children: [
              Container(
                width: 3, height: 12,
                decoration: BoxDecoration(
                  color: _C.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'FEATURED POST',
                style: TextStyle(
                  color: _C.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Post text
          Text(
            text,
            style: const TextStyle(
              color: _C.t1,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.6,
              letterSpacing: 0.1,
            ),
          ),

          const SizedBox(height: 16),

          // Reactions
          _ReactionsBar(
            reactions:     reactions,
            commentsCount: commentsCount,
            reactionsRef:  reactionsRef,
            postRef:       postRef,
            db:            db,
          ),

          const SizedBox(height: 20),
          const Divider(color: _C.border, height: 1, thickness: 0.5),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Reactions Bar — isolated StatefulWidget
// ─────────────────────────────────────────────────────────────
class _ReactionsBar extends StatefulWidget {
  final Map<String, dynamic> reactions;
  final int commentsCount;
  final CollectionReference reactionsRef;
  final DocumentReference   postRef;
  final FirebaseFirestore   db;

  const _ReactionsBar({
    required this.reactions,
    required this.commentsCount,
    required this.reactionsRef,
    required this.postRef,
    required this.db,
  });

  @override
  State<_ReactionsBar> createState() => _ReactionsBarState();
}

class _ReactionsBarState extends State<_ReactionsBar> {
  String? _sel;
  bool    _pending = false;

  static const _defs = [
    ('❤️', 'heart'),
    ('🔥', 'fire'),
    ('👏', 'clap'),
    ('😮', 'wow'),
    ('💯', 'hundred'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    final doc = await widget.reactionsRef.doc(auth.userId).get();
    if (!mounted || !doc.exists) return;
    setState(() =>
    _sel = (doc.data() as Map<String, dynamic>)['reaction'] as String?);
  }

  Future<void> _tap(String key) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const _SignInSheet(),
      );
      return;
    }
    if (_pending) return;

    final prev = _sel;
    final next = prev == key ? null : key;
    setState(() { _sel = next; _pending = true; });

    try {
      final uRef = widget.reactionsRef.doc(auth.userId);
      final uDoc = await uRef.get();
      await widget.db.runTransaction((tx) async {
        await tx.get(widget.postRef);
        if (uDoc.exists) {
          final ex = uDoc['reaction'] as String?;
          if (ex == key) {
            tx.update(widget.postRef, {'reactions.$ex': FieldValue.increment(-1)});
            tx.delete(uRef);
          } else {
            tx.update(widget.postRef, {
              if (ex != null) 'reactions.$ex': FieldValue.increment(-1),
              'reactions.$key': FieldValue.increment(1),
            });
            tx.set(uRef, {'reaction': key, 'reactedAt': FieldValue.serverTimestamp()});
          }
        } else {
          tx.update(widget.postRef, {'reactions.$key': FieldValue.increment(1)});
          tx.set(uRef, {'reaction': key, 'reactedAt': FieldValue.serverTimestamp()});
        }
      });
    } catch (_) {
      if (mounted) setState(() => _sel = prev);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ..._defs.map((def) {
          final (emoji, key) = def;
          final count = (widget.reactions[key] ?? 0) as int;
          final active = _sel == key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Pill(
              emoji: emoji,
              count: count,
              active: active,
              onTap: () => _tap(key),
            ),
          );
        }),
        const Spacer(),
        // Comment count
        Row(
          children: [
            const Icon(Icons.mode_comment_outlined,
                color: _C.t3, size: 14),
            const SizedBox(width: 4),
            Text('${widget.commentsCount}',
                style: const TextStyle(color: _C.t3, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Pill
// ─────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String emoji;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _Pill({
    required this.emoji,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active ? _C.redFade : _C.surface,
          border: Border.all(
            color: active ? _C.red : _C.border,
            width: active ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  color: active ? _C.red : _C.t3,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Comments Sliver
// ─────────────────────────────────────────────────────────────
class _CommentsSliver extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  const _CommentsSliver({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: _C.red, strokeWidth: 1.5),
                ),
              ),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'No comments yet. Be the first!',
                style: TextStyle(color: _C.t3, fontSize: 13),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (ctx, i) => RepaintBoundary(
                child: _CommentRow(
                  key: ValueKey(docs[i].id),
                  data: docs[i].data() as Map<String, dynamic>,
                ),
              ),
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Comment Row — ultra minimal
// ─────────────────────────────────────────────────────────────
class _CommentRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CommentRow({super.key, required this.data});

  String _ago(dynamic ts) {
    if (ts == null) return '';
    final dt = ts is Timestamp ? ts.toDate()
        : ts is String ? (DateTime.tryParse(ts) ?? DateTime.now())
        : DateTime.now();
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24)  return '${d.inHours}h';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final photo = data['userPhoto'] ?? '';
    final raw   = data['userName'];
    final name  = (raw is String && raw.trim().isNotEmpty) ? raw.trim() : 'Fan';
    final text  = data['text'] ?? '';
    final ago   = _ago(data['createdAt']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(photo: photo, name: name, r: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: const TextStyle(
                          color: _C.t1,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 6),
                    Text(ago,
                        style: const TextStyle(
                            color: _C.t3, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(text,
                    style: const TextStyle(
                      color: _C.t2,
                      fontSize: 13,
                      height: 1.5,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Input Bar — isolated, all state inside
// ─────────────────────────────────────────────────────────────
class _InputBar extends StatefulWidget {
  final DocumentReference   postRef;
  final CollectionReference commentsRef;
  const _InputBar({required this.postRef, required this.commentsRef});

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  final _ctrl = TextEditingController();
  bool   _posting   = false;
  int    _cooldown  = 0;
  Timer? _timer;
  bool   _hasText   = false;

  // ── Ban state ──────────────────────────────────────────
  String    _banStatus  = 'none'; // 'none' | 'banned' | 'timedOut'
  DateTime? _banUntil;
  static final _bannedRef =
  FirebaseFirestore.instance.collection('dugout_banned');

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final h = _ctrl.text.trim().isNotEmpty;
      if (h != _hasText) setState(() => _hasText = h);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) _checkBan(auth.userId);
    });
  }

  Future<void> _checkBan(String userId) async {
    final doc = await _bannedRef.doc(userId).get();
    if (!mounted) return;
    if (!doc.exists) { setState(() => _banStatus = 'none'); return; }

    final d    = doc.data() as Map<String, dynamic>;
    final type = d['type'] as String? ?? 'permanent';

    if (type == 'permanent') {
      setState(() => _banStatus = 'banned');
      return;
    }
    if (type == 'timeout') {
      final until = (d['timeoutUntil'] as Timestamp?)?.toDate();
      if (until == null || DateTime.now().isAfter(until)) {
        await _bannedRef.doc(userId).delete();
        setState(() => _banStatus = 'none');
      } else {
        setState(() { _banStatus = 'timedOut'; _banUntil = until; });
        // Auto-clear when timeout expires
        Future.delayed(until.difference(DateTime.now()), () {
          if (mounted) setState(() { _banStatus = 'none'; _banUntil = null; });
        });
      }
    }
  }

  String get _timeoutRemaining {
    if (_banUntil == null) return '';
    final diff = _banUntil!.difference(DateTime.now());
    if (diff.inMinutes < 1) return 'less than a minute';
    if (diff.inHours < 1)   return '${diff.inMinutes}m';
    final m = diff.inMinutes.remainder(60);
    return m > 0 ? '${diff.inHours}h ${m}m' : '${diff.inHours}h';
  }

  bool get _isBanned   => _banStatus == 'banned';
  bool get _isTimedOut => _banStatus == 'timedOut';
  bool get _busy => _posting || _cooldown > 0 || _isBanned || _isTimedOut;

  void _startCooldown() {
    _cooldown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) { _cooldown = 0; t.cancel(); }
      });
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _busy) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const _SignInSheet(),
      );
      return;
    }

    // Re-check ban before every post
    await _checkBan(auth.userId);
    if (!mounted) return; // ← await ke baad
    if (_isBanned || _isTimedOut) return;

    setState(() => _posting = true);
    try {
      await widget.commentsRef.add({
        'userId':    auth.userId,
        'userName':  auth.userName,
        'userPhoto': auth.userPhoto,
        'text':      text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await widget.postRef.update({'commentsCount': FieldValue.increment(1)});
      if (!mounted) return;
      _ctrl.clear();
      FocusScope.of(context).unfocus();
      _startCooldown();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post'),
            backgroundColor: _C.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<AuthProvider, bool>((a) => a.isLoggedIn);
    final photo      = context.select<AuthProvider, String>((a) => a.userPhoto);
    final name       = context.select<AuthProvider, String>((a) => a.userName);
    final canSend    = _hasText && !_busy && isLoggedIn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Ban / timeout banner ─────────────────────────
        if (_isBanned)
          _BanBanner(
            icon: Icons.block_rounded,
            message: 'You\'ve been banned from commenting.',
          ),
        if (_isTimedOut)
          _BanBanner(
            icon: Icons.timer_outlined,
            message: 'Timed out for $_timeoutRemaining.',
          ),

        // ── Input row ────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: _C.bg,
            border: Border(top: BorderSide(color: _C.border, width: 0.5)),
          ),
          padding: EdgeInsets.fromLTRB(
              16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(photo: isLoggedIn ? photo : '', name: name, r: 15),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: isLoggedIn
                      ? null
                      : () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const _SignInSheet(),
                  ),
                  child: AbsorbPointer(
                    absorbing: !isLoggedIn || _isBanned || _isTimedOut,
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      style: const TextStyle(
                          color: _C.t1, fontSize: 14, height: 1.4),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: _isBanned
                            ? 'Commenting disabled'
                            : _isTimedOut
                            ? 'Timed out for $_timeoutRemaining'
                            : _cooldown > 0
                            ? 'Wait ${_cooldown}s...'
                            : isLoggedIn
                            ? 'Add a comment...'
                            : 'Sign in to comment',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: (_isBanned || _isTimedOut)
                              ? _C.red.withValues(alpha: 0.45)
                              : _cooldown > 0
                              ? _C.red.withValues(alpha: 0.45)
                              : _C.t3,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: _busy ? null : (_) => _send(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Send button
              GestureDetector(
                onTap: canSend ? _send : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canSend ? _C.red : Colors.transparent,
                    border: Border.all(
                      color: canSend ? _C.red : _C.border,
                      width: 0.5,
                    ),
                  ),
                  child: Center(child: _btnChild(canSend)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _btnChild(bool active) {
    if (_posting) {
      return const SizedBox(
        width: 14, height: 14,
        child: CircularProgressIndicator(
            strokeWidth: 1.5, color: _C.t3),
      );
    }
    if (_cooldown > 0) {
      return Text('$_cooldown',
          style: const TextStyle(
              color: _C.t3, fontSize: 10, fontWeight: FontWeight.w700));
    }
    return Icon(Icons.arrow_upward_rounded,
        color: active ? _C.white : _C.t3, size: 15);
  }
}

// ─────────────────────────────────────────────────────────────
//  Rules Dialog — shown once on first visit
// ─────────────────────────────────────────────────────────────
class _RulesDialog extends StatelessWidget {
  const _RulesDialog();

  static const _rules = [
    ('🏏', 'Keep it cricket',      'Talk about the game. Stay on topic.'),
    ('🤝', 'Respect everyone',     'No hate, abuse, or personal attacks.'),
    ('🚫', 'No spam',              'Don\'t flood the chat or post links.'),
    ('⚠️',  'Violations = ban',    'Breaking rules may get you removed.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border, width: 0.5),
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon + title
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _C.redFade,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('📋', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Dugout Rules',
              style: TextStyle(
                color: _C.t1,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Read before you join the chat',
              style: TextStyle(color: _C.t3, fontSize: 12),
            ),

            const SizedBox(height: 22),

            // Rules list
            ..._rules.map((r) {
              final (emoji, title, sub) = r;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                color: _C.t1,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(height: 1),
                          Text(sub,
                              style: const TextStyle(
                                  color: _C.t3, fontSize: 12, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),
            const Divider(color: _C.border, height: 1, thickness: 0.5),
            const SizedBox(height: 14),

            // CTA
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: _C.red,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Got it, let\'s go!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Ban Banner — shown above input when user is banned/timed out
// ─────────────────────────────────────────────────────────────
class _BanBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  const _BanBanner({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: const BoxDecoration(
        color: Color(0x1AE53935), // red @ 10%
        border: Border(
          top: BorderSide(color: Color(0x33E53935), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: _C.red, size: 13),
          const SizedBox(width: 7),
          Text(
            message,
            style: const TextStyle(
              color: _C.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Profile Sheet
// ─────────────────────────────────────────────────────────────
class _ProfileSheet extends StatelessWidget {
  final AuthProvider auth;
  const _ProfileSheet({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: _C.border, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 32, height: 3,
            decoration: BoxDecoration(
              color: _C.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 24),
          _Avatar(photo: auth.userPhoto, name: auth.userName, r: 28),
          const SizedBox(height: 12),
          Text(
            auth.userName.isNotEmpty ? auth.userName : 'User',
            style: const TextStyle(
                color: _C.t1, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(auth.user?.email ?? '',
              style: const TextStyle(color: _C.t3, fontSize: 12)),
          const SizedBox(height: 24),
          const Divider(color: _C.border, height: 1, thickness: 0.5),
          const SizedBox(height: 4),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded, color: _C.red, size: 18),
            title: const Text('Sign out',
                style: TextStyle(
                    color: _C.red, fontSize: 14, fontWeight: FontWeight.w500)),
            onTap: () { Navigator.pop(context); auth.signOut(); },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Sign In Sheet
// ─────────────────────────────────────────────────────────────
class _SignInSheet extends StatelessWidget {
  const _SignInSheet();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: _C.border, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32, height: 3,
            decoration: BoxDecoration(
                color: _C.border, borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(height: 28),
          const Text('🏏', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 14),
          const Text('Join the Dugout',
              style: TextStyle(
                  color: _C.t1, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Sign in to react and comment',
              style: TextStyle(color: _C.t2, fontSize: 13)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await auth.signInWithGoogle();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.white,
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://www.google.com/favicon.ico',
                    width: 16, height: 16,
                    errorBuilder: (_, _, _) =>
                    const Icon(Icons.login, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text('Continue with Google',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe later',
                style: TextStyle(color: _C.t3, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Avatar
// ─────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String photo, name;
  final double r;
  const _Avatar({required this.photo, required this.name, required this.r});

  @override
  Widget build(BuildContext context) {
    final i = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: r,
      backgroundColor: _C.redFade,
      backgroundImage: photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null,
      child: photo.isEmpty
          ? Text(i,
          style: TextStyle(
              fontSize: r * 0.75,
              color: _C.red,
              fontWeight: FontWeight.w700))
          : null,
    );
  }
}