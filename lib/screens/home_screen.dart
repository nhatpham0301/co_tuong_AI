import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shirne_dialog/shirne_dialog.dart';
import 'package:universal_html/html.dart' as html;

import '../global.dart';
import '../models/play_mode.dart';

// ---------------------------------------------------------------------------
// Palette Ã¢â‚¬â€ matches the reference design
// ---------------------------------------------------------------------------
const _bgDark = Color(0xFF0B2A18); // top of screen
const _bgMid = Color(0xFF1D6640); // radial center glow
const _bgEdge = Color(0xFF0E3320); // edges / bottom

const _goldDark = Color(0xFF9A6C08);
const _goldMid = Color(0xFFCC9518);
const _goldLight = Color(0xFFEDBC50);
const _goldGlow = Color(0xFFFFD86E);

const _orbitR = 120.0; // satellite orbit radius (px)

// ---------------------------------------------------------------------------
// Home Screen
// ---------------------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background (radial glow Ã¢â‚¬â€ brighter centre, dark edges)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, 0.1),
                radius: 0.78,
                colors: [_bgMid, _bgEdge],
              ),
            ),
          ),
          // 2. Side chess-piece decorations
          const _SidePieces(),
          // 3. Corner knot decorations
          const _CornerKnots(),
          // 4. Main content
          SafeArea(
            child: Column(
              children: [
                _TopBar(),
                Expanded(child: _RadialMenu()),
                const _BannerSlot(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 34,
            height: 34,
            color: Colors.white70,
          ),
          const SizedBox(width: 10),
          Text(
            context.l10n.appTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          _TopIconBtn(
            icon: Icons.person_outline,
            tooltip: 'Profile',
            onTap: () {},
          ),
          const SizedBox(width: 8),
          if (kIsWeb)
            _TopIconBtn(
              icon: Icons.android,
              tooltip: 'Download APK',
              onTap: () {
                var link = html.window.document.getElementById('download-apk');
                if (link == null) {
                  link = html.window.document.createElement('a');
                  link.style.display = 'none';
                  link.setAttribute('id', 'download-apk');
                  link.setAttribute('target', '_blank');
                  link.setAttribute('href', 'chinese-chess.apk');
                  html.window.document
                      .getElementsByTagName('body')[0]
                      .append(link);
                }
                link.click();
              },
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Radial menu  (8 golden satellite buttons + central PLAY)
// ---------------------------------------------------------------------------
class _RadialMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // 8 buttons at 45Ã‚Â° intervals, starting -90Ã‚Â° (straight up)
    final items = <_Item>[
      _Item(
        Icons.smart_toy_outlined,
        l10n.modeRobot,
        -90,
        () => context.go('/game', extra: PlayMode.modeRobot),
      ),
      _Item(
        Icons.people_outline,
        l10n.modeOnline,
        -45,
        () =>
            MyDialog.toast(l10n.featureNotAvailable, iconType: IconType.error),
      ),
      _Item(
        Icons.tune,
        l10n.setting,
        0,
        () => context.push('/settings'),
      ),
      _Item(
        Icons.emoji_events_outlined,
        'Rankings',
        45,
        () =>
            MyDialog.toast(l10n.featureNotAvailable, iconType: IconType.error),
      ),
      _Item(
        Icons.history,
        'History',
        90,
        () =>
            MyDialog.toast(l10n.featureNotAvailable, iconType: IconType.error),
      ),
      _Item(
        Icons.grid_on,
        l10n.modeFree,
        135,
        () => context.go('/game', extra: PlayMode.modeFree),
      ),
      _Item(
        Icons.live_tv,
        l10n.liveMatch,
        180,
        () => context.push('/live'),
      ),
      _Item(
        Icons.person_pin_outlined,
        'Profile',
        225,
        () =>
            MyDialog.toast(l10n.featureNotAvailable, iconType: IconType.error),
      ),
    ];

    return LayoutBuilder(
      builder: (context, bc) {
        final menuD = math.min(bc.maxWidth, bc.maxHeight).clamp(0.0, 420.0);
        return Center(
          child: SizedBox(
            width: menuD,
            height: menuD,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Orbit ring
                CustomPaint(
                  size: Size(menuD, menuD),
                  painter: _OrbitPainter(radius: _orbitR),
                ),
                // Satellites
                ...items.map((item) {
                  final rad = item.angleDeg * math.pi / 180.0;
                  return Transform.translate(
                    offset: Offset(
                      _orbitR * math.cos(rad),
                      _orbitR * math.sin(rad),
                    ),
                    child: _SatelliteBtn(item: item),
                  );
                }),
                // Central PLAY
                _PlayBtn(onTap: () => _showModeSheet(context)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showModeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ModeSheet(),
    );
  }
}

// ---------------------------------------------------------------------------
// Central PLAY button
// ---------------------------------------------------------------------------
class _PlayBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_goldGlow, _goldMid, _goldDark],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: _goldMid.withValues(alpha: 0.65),
              blurRadius: 28,
              spreadRadius: 6,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 42),
            SizedBox(height: 1),
            Text(
              'Play',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Satellite button  (golden circle + label)
// ---------------------------------------------------------------------------
class _SatelliteBtn extends StatelessWidget {
  final _Item item;
  const _SatelliteBtn({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_goldLight, _goldMid, _goldDark],
                stops: [0.0, 0.45, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: _goldDark.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(item.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 62,
            child: Text(
              item.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet Ã¢â‚¬â€ mode selection
// ---------------------------------------------------------------------------
class _ModeSheet extends StatelessWidget {
  const _ModeSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: _goldMid.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'ChÃ¡Â»Ân ChÃ¡ÂºÂ¿ Ã„ÂÃ¡Â»â„¢',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          _SheetRow(
            icon: Icons.smart_toy_outlined,
            label: l10n.modeRobot,
            sub: 'ChÃ†Â¡i vÃ¡Â»â€ºi AI',
            onTap: () {
              Navigator.pop(context);
              context.go('/game', extra: PlayMode.modeRobot);
            },
          ),
          const SizedBox(height: 10),
          _SheetRow(
            icon: Icons.people_outline,
            label: l10n.modeOnline,
            sub: 'GhÃƒÂ©p trÃ¡ÂºÂ­n trÃ¡Â»Â±c tuyÃ¡ÂºÂ¿n',
            onTap: () {
              Navigator.pop(context);
              MyDialog.toast(
                l10n.featureNotAvailable,
                iconType: IconType.error,
              );
            },
          ),
          const SizedBox(height: 10),
          _SheetRow(
            icon: Icons.grid_on,
            label: l10n.modeFree,
            sub: 'ChÃ†Â¡i bÃƒÂ n cÃ¡Â»Â tÃ¡Â»Â± do',
            onTap: () {
              Navigator.pop(context);
              context.go('/game', extra: PlayMode.modeFree);
            },
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1D5C38),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_goldLight, _goldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      sub,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Side chess-piece decorations
// ---------------------------------------------------------------------------
class _SidePieces extends StatelessWidget {
  const _SidePieces();

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Left Ã¢â‚¬â€ cannon (Ã§Â Â²)
        Positioned(
          left: -30,
          bottom: h * 0.08,
          child: Opacity(
            opacity: 0.18,
            child: Image.asset(
              'assets/skins/woods/rc.png',
              width: 180,
              height: 180,
            ),
          ),
        ),
        // Right Ã¢â‚¬â€ chariot (Ã¨Â»Å )
        Positioned(
          right: -30,
          bottom: h * 0.08,
          child: Opacity(
            opacity: 0.18,
            child: Image.asset(
              'assets/skins/woods/rr.png',
              width: 180,
              height: 180,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Corner knot decorations  (painted arcs that suggest a Chinese knot)
// ---------------------------------------------------------------------------
class _CornerKnots extends StatelessWidget {
  const _CornerKnots();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _KnotPainter(),
    );
  }
}

class _KnotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _goldMid.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Top-left knot
    _drawKnot(canvas, paint, const Offset(0, 0), 60);
    // Top-right knot
    _drawKnot(canvas, paint, Offset(size.width, 0), 60, flipX: true);
  }

  void _drawKnot(
    Canvas canvas,
    Paint paint,
    Offset origin,
    double r, {
    bool flipX = false,
  }) {
    final dx = flipX ? -1 : 1;
    final cx = origin.dx + dx * r;
    final cy = origin.dy + r;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(Offset(cx, cy), r * i * 0.28, paint);
    }
    // Two diagonal arcs
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 1.6, height: r * 1.6),
      -math.pi / 4,
      math.pi / 2,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx - dx * r * 0.3, cy - r * 0.3),
        width: r * 1.2,
        height: r * 1.2,
      ),
      math.pi - math.pi / 6,
      -math.pi / 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_KnotPainter _) => false;
}

// ---------------------------------------------------------------------------
// Orbit ring painter
// ---------------------------------------------------------------------------
class _OrbitPainter extends CustomPainter {
  final double radius;
  const _OrbitPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _goldMid.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.radius != radius;
}

// ---------------------------------------------------------------------------
// Banner slot
// ---------------------------------------------------------------------------
class _BannerSlot extends StatelessWidget {
  const _BannerSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(color: _goldMid.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.ad_units, color: Colors.white24, size: 16),
          const SizedBox(width: 8),
          Text(
            'QUÃ¡ÂºÂ¢NG CÃƒÂO BANNER TRÃƒÅ N LAYOUT', // Phase 2 Ã¢â€ â€™ BannerAdWidget
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.18), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small icon button in top bar
// ---------------------------------------------------------------------------
class _TopIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _TopIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: _goldMid.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data class
// ---------------------------------------------------------------------------
class _Item {
  final IconData icon;
  final String label;
  final double angleDeg;
  final VoidCallback onTap;

  const _Item(this.icon, this.label, this.angleDeg, this.onTap);
}
