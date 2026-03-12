import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Tokens (match your app's design tokens) ───────────────
const _raised  = Color(0xFF131313);
const _card    = Color(0xFF111111);
const _line    = Color(0xFF1C1C1C);
const _red     = Color(0xFFCC0000);
const _redDim  = Color(0xFF2A0000);

// ══════════════════════════════════════════════════════════
//  NOTIFICATION PREFERENCE HELPER  (same as your existing one,
//  just extended with a topic-subscription key)
// ══════════════════════════════════════════════════════════
class NotificationPreference {
  static const _statusKey      = 'notification_permission_status';
  static const _deniedCountKey = 'notification_denied_count';
  static const _topicKey       = 'notification_topic_cricket'; // NEW
  static const maxDeniedCount  = 3;

  static Future<void> saveGranted() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_statusKey, 'granted');
  }

  static Future<void> saveDenied() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_statusKey, 'denied');
    final c = p.getInt(_deniedCountKey) ?? 0;
    await p.setInt(_deniedCountKey, c + 1);
  }

  static Future<bool> isGranted() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_statusKey) == 'granted';
  }

  static Future<int> getDeniedCount() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_deniedCountKey) ?? 0;
  }

  static Future<bool> shouldShowPermissionScreen() async {
    final p = await SharedPreferences.getInstance();
    final status      = p.getString(_statusKey);
    final deniedCount = p.getInt(_deniedCountKey) ?? 0;
    if (status == 'granted') return false;
    if (deniedCount >= maxDeniedCount) return false;
    return true;
  }

  // ── Topic helpers ──────────────────────────────────────
  static Future<bool> isTopicSubscribed() async {
    final p = await SharedPreferences.getInstance();
    // Default true — subscribed by default when granted
    return p.getBool(_topicKey) ?? true;
  }

  static Future<void> saveTopicSubscribed(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_topicKey, value);
  }
}

// ══════════════════════════════════════════════════════════
//  PUBLIC ENTRY POINT
//  Call this from your Notifications tile's onTap:
//    onTap: () => showNotificationSettings(context),
// ══════════════════════════════════════════════════════════
Future<void> showNotificationSettings(BuildContext context) async {
  // Check actual system permission first
  final settings = await FirebaseMessaging.instance.getNotificationSettings();
  final isSystemGranted =
      settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NotificationSettingsSheet(
      isSystemGranted: isSystemGranted,
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  BOTTOM SHEET
// ══════════════════════════════════════════════════════════
class _NotificationSettingsSheet extends StatefulWidget {
  final bool isSystemGranted;
  const _NotificationSettingsSheet({required this.isSystemGranted});

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  bool _masterEnabled  = false;
  bool _cricketUpdates = true; // topic: cricket_notification
  bool _loading        = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final topicOn = await NotificationPreference.isTopicSubscribed();
    setState(() {
      _masterEnabled  = widget.isSystemGranted;
      _cricketUpdates = topicOn;
      _loading        = false;
    });
  }

  // ── Toggle cricket topic ────────────────────────────────
  Future<void> _toggleCricketUpdates(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _cricketUpdates = value);
    await NotificationPreference.saveTopicSubscribed(value);
    if (value) {
      await FirebaseMessaging.instance
          .subscribeToTopic('cricket_notification');
    } else {
      await FirebaseMessaging.instance
          .unsubscribeFromTopic('cricket_notification');
    }
  }

  // ── Request system permission ───────────────────────────
  Future<void> _requestPermission() async {
    final messaging = FirebaseMessaging.instance;
    final result    = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    final granted =
        result.authorizationStatus == AuthorizationStatus.authorized ||
            result.authorizationStatus == AuthorizationStatus.provisional;

    if (granted) {
      await NotificationPreference.saveGranted();
      // Re-subscribe to topic when granting
      await messaging.subscribeToTopic('cricket_notification');
      await NotificationPreference.saveTopicSubscribed(true);
    } else {
      await NotificationPreference.saveDenied();
    }

    setState(() {
      _masterEnabled  = granted;
      _cricketUpdates = granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return  SafeArea(bottom: true,
      child: Container(
        margin: EdgeInsets.only(bottom: bottom),
        decoration: const BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.bell,
                        size: 18, color: Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5)),
                      Text('Manage your alert preferences',
                          style: TextStyle(
                              color: Color(0x55FFFFFF),
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                    color: _red, strokeWidth: 2),
              )
            else ...[
              // ── Permission denied banner ─────────────────
              if (!_masterEnabled)
                _PermissionBanner(onEnable: _requestPermission),

              // ── Controls ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _raised,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _line),
                  ),
                  child: Column(
                    children: [
                      // Cricket Updates
                      _ToggleRow(
                        icon: LucideIcons.activity,
                        iconBg: _red,
                        title: 'Cricket Updates',
                        subtitle: 'Live scores, match alerts & news',
                        value: _masterEnabled && _cricketUpdates,
                        enabled: _masterEnabled,
                        onChanged: _masterEnabled
                            ? _toggleCricketUpdates
                            : null,
                      ),

                      Container(height: 1,
                          margin: const EdgeInsets.only(left: 60),
                          color: _line),

                      // Breaking News (static for now — extend as needed)
                      _ToggleRow(
                        icon: LucideIcons.newspaper,
                        iconBg: const Color(0xFF4B8BF5),
                        title: 'Breaking News',
                        subtitle: 'Transfer news & announcements',
                        value: _masterEnabled && _cricketUpdates,
                        enabled: _masterEnabled,
                        onChanged: _masterEnabled
                            ? _toggleCricketUpdates // reuse same topic for now
                            : null,
                      ),

                      Container(height: 1,
                          margin: const EdgeInsets.only(left: 60),
                          color: _line),

                      // Match Reminders
                      _ToggleRow(
                        icon: LucideIcons.calendarCheck,
                        iconBg: const Color(0xFF10B981),
                        title: 'Match Reminders',
                        subtitle: 'Get notified before matches start',
                        value: _masterEnabled && _cricketUpdates,
                        enabled: _masterEnabled,
                        onChanged: _masterEnabled
                            ? _toggleCricketUpdates
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              // ── System settings shortcut ─────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: GestureDetector(
                  onTap: () async {
                    await _launch('app-settings:');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: _raised,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _line),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.settings,
                            size: 16,
                            color: Colors.white.withAlpha(60)),
                        const SizedBox(width: 10),
                        Text('Open System Notification Settings',
                            style: TextStyle(
                                color: Colors.white.withAlpha(60),
                                fontSize: 13)),
                        const Spacer(),
                        Icon(LucideIcons.externalLink,
                            size: 14,
                            color: Colors.white.withAlpha(30)),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  PERMISSION DENIED BANNER
// ══════════════════════════════════════════════════════════
class _PermissionBanner extends StatelessWidget {
  final VoidCallback onEnable;
  const _PermissionBanner({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _redDim,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _red.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.bellOff, size: 18, color: _red.withAlpha(200)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notifications are off',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Enable to get match alerts',
                      style: TextStyle(
                          color: Colors.white.withAlpha(50),
                          fontSize: 11)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onEnable,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Enable',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  TOGGLE ROW
// ══════════════════════════════════════════════════════════
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconBg.withAlpha(220),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withAlpha(45),
                          fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: _red,
              inactiveThumbColor: Colors.white.withAlpha(80),
              inactiveTrackColor: Colors.white.withAlpha(20),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper ─────────────────────────────────────────────────
Future<void> _launch(String url) async {
  try {
    // ignore: deprecated_member_use
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}