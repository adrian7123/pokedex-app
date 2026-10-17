import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

enum StampState { empty, stamped, shiny }

/// Anel de carimbo da cartela: vazio (pontilhado), entintado na cor do tipo ou em ouro (shiny).
///
/// A rotação e o desalinhamento da tinta são determinísticos por [seed], como uma borracha real
/// que nunca cai duas vezes igual, mas sempre cai igual para o mesmo Pokémon.
class StampSlot extends StatefulWidget {
  const StampSlot({
    super.key,
    required this.seed,
    required this.ink,
    required this.state,
    this.size = 52,
    this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
  });

  final int seed;
  final Color ink;
  final StampState state;
  final double size;
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;

  @override
  State<StampSlot> createState() => _StampSlotState();
}

class _StampSlotState extends State<StampSlot> with TickerProviderStateMixin {
  late final AnimationController _ink = AnimationController(
    vsync: this,
    duration: Motion.long,
    value: widget.state == StampState.empty ? 0 : 1,
  );
  late final AnimationController _press = AnimationController(vsync: this, duration: Motion.short);
  late final AnimationController _sparkle = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  StampState _shown = StampState.empty;

  @override
  void initState() {
    super.initState();
    _shown = widget.state;
  }

  @override
  void didUpdateWidget(StampSlot old) {
    super.didUpdateWidget(old);
    if (old.state == widget.state) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.state == StampState.empty) {
      if (reduce) {
        _ink.value = 0;
        setState(() => _shown = StampState.empty);
      } else {
        _ink.reverse().whenComplete(() {
          if (mounted && widget.state == StampState.empty) setState(() => _shown = StampState.empty);
        });
      }
      return;
    }
    setState(() => _shown = widget.state);
    HapticFeedback.mediumImpact();
    if (reduce) {
      _ink.value = 1;
      return;
    }
    _press.forward(from: 0).whenComplete(() => _press.reverse());
    _ink.forward(from: 0);
    if (widget.state == StampState.shiny) _sparkle.forward(from: 0);
  }

  @override
  void dispose() {
    _ink.dispose();
    _press.dispose();
    _sparkle.dispose();
    super.dispose();
  }

  double get _angle {
    final r = math.Random(widget.seed);
    return (r.nextDouble() * 16 - 8) * math.pi / 180;
  }

  Offset get _offset {
    final r = math.Random(widget.seed * 7 + 3);
    return Offset(r.nextDouble() * 2 - 1, r.nextDouble() * 2 - 1);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final color = _shown == StampState.shiny ? Gold.ink : widget.ink;
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: SizedBox.square(
          dimension: math.max(size, 48),
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_ink, _press, _sparkle]),
              builder: (context, _) {
                final t = Motion.emphasized.transform(_ink.value);
                final press = 1 - .06 * Curves.easeOut.transform(_press.value);
                final blur = (1 - t) * 6;
                return Transform.scale(
                  scale: press,
                  child: SizedBox.square(
                    dimension: size,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(size: Size.square(size), painter: _DashedRing(opacity: 1 - t)),
                        if (t > 0)
                          ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                            child: Opacity(
                              opacity: t,
                              child: Transform.scale(
                                scale: 1.12 - .12 * t,
                                child: CustomPaint(
                                  size: Size.square(size),
                                  painter: _InkRing(color: color, angle: _angle, offset: _offset),
                                ),
                              ),
                            ),
                          ),
                        if (widget.child != null)
                          SizedBox.square(dimension: size * .78, child: widget.child),
                        if (_sparkle.isAnimating)
                          CustomPaint(size: Size.square(size), painter: _Sparkle(progress: _sparkle.value)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRing extends CustomPainter {
  _DashedRing({required this.opacity});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final paint = Paint()
      ..color = Ramp.n4.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final r = size.width / 2 - 1;
    final c = size.center(Offset.zero);
    const dashes = 22;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * sweep, sweep * .55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) => old.opacity != opacity;
}

class _InkRing extends CustomPainter {
  _InkRing({required this.color, required this.angle, required this.offset});
  final Color color;
  final double angle;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero) + offset;
    final r = size.width / 2;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    // Fundo da tinta, bem lavado.
    canvas.drawCircle(Offset.zero, r - 2, Paint()..color = Color.lerp(Ramp.paper, color, .16)!);
    // Anel externo: tinta mais carregada de um lado, como borracha pressionada torta.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .13
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: .95), color.withValues(alpha: .62), color.withValues(alpha: .9)],
        stops: const [0, .55, 1],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r - r * .07, ring);
    // Anel interno fino.
    canvas.drawCircle(
      Offset.zero,
      r * .76,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: .5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InkRing old) => old.color != color || old.angle != angle || old.offset != offset;
}

/// Brilho curto do shiny: quatro estrelas de quatro pontas que saem do anel e somem.
class _Sparkle extends CustomPainter {
  _Sparkle({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final t = Curves.easeOutCubic.transform(progress);
    final fade = 1 - Curves.easeIn.transform(progress);
    final paint = Paint()..color = Gold.ink.withValues(alpha: fade);
    const angles = [-.9, -.2, .7, 2.4];
    for (var i = 0; i < angles.length; i++) {
      final dist = size.width * (.42 + .22 * t);
      final p = c + Offset(math.cos(angles[i]), math.sin(angles[i])) * dist;
      final s = (i.isEven ? 5.0 : 3.5) * (1 - .4 * t);
      final path = Path()
        ..moveTo(p.dx, p.dy - s)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + s, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + s)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - s, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - s)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_Sparkle old) => old.progress != progress;
}
