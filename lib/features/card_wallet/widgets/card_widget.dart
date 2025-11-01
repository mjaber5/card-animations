import 'package:flutter/material.dart';
import '../models/credit_card.dart';

class CardWidget extends StatelessWidget {
  final CreditCard card;
  final double elevation;
  final Offset motionOffset;
  final bool showDepth;

  const CardWidget({
    super.key,
    required this.card,
    required this.elevation,
    this.motionOffset = Offset.zero,
    this.showDepth = false,
  });

  @override
  Widget build(BuildContext context) {
    final double dx = motionOffset.dx.clamp(-1.0, 1.0);
    final double dy = motionOffset.dy.clamp(-1.0, 1.0);
    final double motionMagnitude = (dx.abs() + dy.abs()).clamp(0.0, 1.6);

    final Alignment glareAlignment = Alignment(-dx * 0.9, -1.2 + dy * 0.4);
    final Alignment shadowAlignment = Alignment(dx * 0.7, 1.1 + dy * 0.3);

    final Color gradientStart = _shiftCardColor(
      card.color,
      lightness: 0.12,
      saturation: 0.05,
    );
    final Color gradientEnd = _shiftCardColor(
      card.color,
      lightness: -0.08,
      saturation: -0.03,
    );

    // Subtle iOS-like content drift (reduced sensitivity)
    final Offset contentDrift = Offset(dx * 4.0, dy * 3.0);
    final Offset ribbonDrift = Offset(dx * -6.0, dy * -4.5);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: elevation * 1.7,
            offset: Offset(0, elevation * 0.7),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: elevation * 3.4,
            offset: Offset(0, elevation),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [gradientStart, gradientEnd],
                  ),
                ),
              ),
            ),
            if (showDepth)
              // Lift highlight: mimic specular shine that follows device tilt.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: glareAlignment,
                        radius: 1.2 + motionMagnitude * 0.25,
                        colors: [
                          Colors.white.withValues(
                            alpha: 0.14 + motionMagnitude * 0.1,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (showDepth)
              // Edge shading: deepen the opposite side for more perspective.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: shadowAlignment,
                        end: Alignment(-shadowAlignment.x, -shadowAlignment.y),
                        colors: [
                          Colors.black.withValues(
                            alpha: 0.12 + motionMagnitude * 0.12,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (showDepth)
              // Floating ribbon layer adds a premium laminated feel.
              Positioned(
                right: -120 + ribbonDrift.dx * 6,
                top: -40 + ribbonDrift.dy * 4,
                child: Transform.rotate(
                  angle: dx * 0.08,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Transform.translate(
                offset: contentDrift,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card.name,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        letterSpacing: 2.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'JOD ${card.balance}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(dx * -14.0, dy * -12.0),
                          child: MastercardLogo(
                            intensity: showDepth ? motionMagnitude : 0.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _shiftCardColor(Color color, {double lightness = 0, double saturation = 0}) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + lightness).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + saturation).clamp(0.0, 1.0))
        .toColor();
  }
}

class MastercardLogo extends StatelessWidget {
  final double intensity;

  const MastercardLogo({super.key, this.intensity = 0.0});

  @override
  Widget build(BuildContext context) {
    final double glowBoost = (0.2 * intensity).clamp(0.0, 0.25);
    final double scale = 1.0 + intensity * 0.06;

    return Transform.scale(
      scale: scale,
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 50,
        height: 32,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.78 + glowBoost),
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.58 + glowBoost * 0.6),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.6, -0.2),
                      radius: 1.4,
                      colors: [
                        Colors.white.withValues(alpha: 0.12 + glowBoost * 0.8),
                        Colors.transparent,
                      ],
                    ),
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
