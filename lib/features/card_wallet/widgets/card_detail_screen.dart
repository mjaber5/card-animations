import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../services/motion_tracking_service.dart';
import 'card_widget.dart';
import 'transaction_list_view.dart';
import 'spending_analytics_view.dart';

class CardDetailScreen extends StatefulWidget {
  final CreditCard card;
  final List<Transaction> transactions;

  const CardDetailScreen({
    super.key,
    required this.card,
    required this.transactions,
  });

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late MotionTrackingService _motionTrackingService;

  // Device motion driven parallax effect
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();

    // Initialize motion tracking service for subtle iOS-like 3D effect
    _motionTrackingService = MotionTrackingService(
      onTiltUpdate: (tiltX, tiltY) {
        setState(() {
          _tiltX = tiltX;
          _tiltY = tiltY;
        });
      },
    );
    _motionTrackingService.startTracking();
  }

  @override
  void dispose() {
    _motionTrackingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Subtle iOS-like 3D parallax effect
    final parallaxX = _tiltX * 8.0;
    final parallaxY = _tiltY * 8.0;
    final parallaxRotateX = _tiltY * 0.15;
    final parallaxRotateY = -_tiltX * 0.15;
    final parallaxRotateZ = _tiltX * 0.03;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Card with Hero animation
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Hero(
                tag: 'card_${widget.card.id}',
                flightShuttleBuilder: (
                  BuildContext flightContext,
                  Animation<double> animation,
                  HeroFlightDirection flightDirection,
                  BuildContext fromHeroContext,
                  BuildContext toHeroContext,
                ) {
                  // Smooth Hero transition
                  return DefaultTextStyle(
                    style: DefaultTextStyle.of(toHeroContext).style,
                    child: toHeroContext.widget,
                  );
                },
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(parallaxRotateY)
                    ..rotateX(parallaxRotateX)
                    ..rotateZ(parallaxRotateZ),
                  child: Transform.translate(
                    offset: Offset(parallaxX, parallaxY),
                    child: Material(
                      color: Colors.transparent,
                      child: CardWidget(
                        card: widget.card,
                        elevation: 28.0,
                        motionOffset: Offset(_tiltX, _tiltY),
                        showDepth: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Detail content (transactions or analytics)
            Expanded(
              child: widget.card.hasSpendingAnalytics
                  ? SpendingAnalyticsView(
                      onClose: () => Navigator.of(context).pop(),
                    )
                  : TransactionListView(
                      transactions: widget.transactions,
                      onClose: () => Navigator.of(context).pop(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
