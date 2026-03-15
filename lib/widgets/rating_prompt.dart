import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

import '../models/rating_config_model.dart';
import '../service/appremoteconfigservice.dart';

class RatingPrompt {
  static Future<void> checkAndShow(BuildContext context) async {
    final should = await AppRemoteConfigService.shouldShowRating();
    if (!should || !context.mounted) return;

    final config = await AppRemoteConfigService.getRatingConfig();
    if (!context.mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(179), // 0.7
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, _) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: anim,
            child: _RatingDialog(config: config),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
//  RATING DIALOG
// ════════════════════════════════════════════════════════════
class _RatingDialog extends StatefulWidget {
  final RatingConfig config;
  const _RatingDialog({required this.config});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _starController;
  int _hoveredStar = 0;
  int _selectedStar = 0;
  bool _loading = false;

  static const _bg = Color(0xFF111111);
  static const _border = Color(0xFF2A2A2A);
  static const _textPrimary = Color(0xFFF0F0F0);
  static const _textSecondary = Color(0xFF888888);
  static const _packageId = 'com.ballbyball.app';

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  Future<void> _onRate() async {
    if (_selectedStar == 0) return;
    setState(() => _loading = true);

    try {
      await AppRemoteConfigService.markRatingShown(widget.config.campaignId);
      if (!mounted) return;
      Navigator.of(context).pop();

      if (_selectedStar >= 4) {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        } else {
          await review.openStoreListing(appStoreId: _packageId);
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _onLater() async {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(153), // 0.6
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.amber.withAlpha(10), // 0.04
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Top glow strip ──────────────────────
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      Colors.amber.withAlpha(153), // 0.6
                      Colors.transparent,
                    ]),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                  child: Column(
                    children: [
                      _AnimatedStarIcon(controller: _starController),
                      const SizedBox(height: 20),

                      Text(
                        widget.config.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        widget.config.body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _StarPicker(
                        selected: _selectedStar,
                        hovered: _hoveredStar,
                        onHover: (i) => setState(() => _hoveredStar = i),
                        onTap: (i) => setState(() => _selectedStar = i),
                      ),

                      const SizedBox(height: 8),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _starLabel(_selectedStar),
                          key: ValueKey(_selectedStar),
                          style: TextStyle(
                            color: _selectedStar > 0
                                ? Colors.amber
                                : _textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      _RateButton(
                        label: widget.config.buttonText,
                        enabled: _selectedStar > 0,
                        loading: _loading,
                        onTap: _onRate,
                      ),

                      const SizedBox(height: 10),

                      GestureDetector(
                        onTap: _onLater,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            widget.config.cancelText,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _starLabel(int stars) {
    switch (stars) {
      case 1: return 'Terrible 😞';
      case 2: return 'Not great 😕';
      case 3: return "It's okay 😐";
      case 4: return 'Pretty good 😊';
      case 5: return 'Love it! 🏏🔥';
      default: return 'Tap a star to rate';
    }
  }
}

// ════════════════════════════════════════════════════════════
//  STAR PICKER
// ════════════════════════════════════════════════════════════
class _StarPicker extends StatelessWidget {
  final int selected, hovered;
  final ValueChanged<int> onHover, onTap;

  const _StarPicker({
    required this.selected,
    required this.hovered,
    required this.onHover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= (hovered > 0 ? hovered : selected);
        return MouseRegion(
          onEnter: (_) => onHover(star),
          onExit: (_) => onHover(0),
          child: GestureDetector(
            onTap: () => onTap(star),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedScale(
                scale: filled ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled ? Colors.amber : const Color(0xFF3A3A3A),
                  size: 38,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ANIMATED STAR ICON
// ════════════════════════════════════════════════════════════
class _AnimatedStarIcon extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedStarIcon({required this.controller});

  @override
  Widget build(BuildContext context) {
    // ── scale deprecated fix: use ScaleTransition instead ──
    final scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.elasticOut),
    );

    return ScaleTransition(
      scale: scaleAnim,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.amber.withAlpha(26),   // 0.1
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.amber.withAlpha(51), // 0.2
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withAlpha(38), // 0.15
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.star_rounded,
          color: Colors.amber,
          size: 36,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  RATE BUTTON
// ════════════════════════════════════════════════════════════
class _RateButton extends StatefulWidget {
  final String label;
  final bool enabled, loading;
  final VoidCallback onTap;

  const _RateButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  State<_RateButton> createState() => _RateButtonState();
}

class _RateButtonState extends State<_RateButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.enabled && !widget.loading ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        // ── scale deprecated fix: use transform with AnimatedContainer ──
        transform: _pressed
            ? (Matrix4.diagonal3Values(0.97, 0.97, 1.0))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: widget.enabled
              ? const LinearGradient(
            colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: widget.enabled ? null : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.enabled
                ? Colors.transparent
                : const Color(0xFF2A2A2A),
          ),
          boxShadow: widget.enabled
              ? [
            BoxShadow(
              color: Colors.amber.withAlpha(77), // 0.3
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
              : null,
        ),
        child: Center(
          child: widget.loading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2.5,
            ),
          )
              : Text(
            widget.label,
            style: TextStyle(
              color: widget.enabled
                  ? Colors.black
                  : const Color(0xFF3A3A3A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}