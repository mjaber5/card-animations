import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

void main() => runApp(const CardWalletApp());

class CardWalletApp extends StatelessWidget {
  const CardWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'SF Pro',
      ),
      home: const AllCardsScreen(),
    );
  }
}

Color _shiftCardColor(
  Color color, {
  double lightness = 0.0,
  double saturation = 0.0,
}) {
  final hsl = HSLColor.fromColor(color);
  final double l = (hsl.lightness + lightness).clamp(0.0, 1.0);
  final double s = (hsl.saturation + saturation).clamp(0.0, 1.0);
  return hsl.withLightness(l).withSaturation(s).toColor();
}

// ============================================================================
// MODELS
// ============================================================================

class CreditCard {
  final String id;
  final String name;
  final String balance;
  final Color color;
  final bool hasTransactions;
  final bool hasSpendingAnalytics;

  const CreditCard({
    required this.id,
    required this.name,
    required this.balance,
    required this.color,
    this.hasTransactions = true,
    this.hasSpendingAnalytics = false,
  });
}

class Transaction {
  final String title;
  final String date;
  final double amount;
  final TransactionType type;

  const Transaction({
    required this.title,
    required this.date,
    required this.amount,
    required this.type,
  });
}

enum TransactionType { debit, credit }

enum CardViewState { collapsed, expanded, detail }

// ============================================================================
// MAIN SCREEN
// ============================================================================

class AllCardsScreen extends StatefulWidget {
  const AllCardsScreen({super.key});

  @override
  State<AllCardsScreen> createState() => _AllCardsScreenState();
}

class _AllCardsScreenState extends State<AllCardsScreen>
    with TickerProviderStateMixin {
  late AnimationController _expansionController;
  late AnimationController _detailController;

  CardViewState _viewState = CardViewState.collapsed;
  int? _selectedCardIndex;

  // Device motion driven parallax effect
  StreamSubscription<AccelerometerEvent>? _motionSubscription;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  double _targetTiltX = 0.0;
  double _targetTiltY = 0.0;

  // Card data matching the screenshots
  final List<CreditCard> cards = const [
    CreditCard(
      id: '1',
      name: 'TRAVEL CARD',
      balance: '453',
      color: Color(0xFF2D2D2D),
    ),
    CreditCard(
      id: '2',
      name: 'MUJEER WALYT',
      balance: '999',
      color: Color.fromARGB(255, 0, 85, 159),
    ),
    CreditCard(
      id: '3',
      name: 'FOOD CARD',
      balance: '127',
      color: Color(0xFF090915),
    ),
    CreditCard(
      id: '4',
      name: 'GIFT CARD',
      balance: '745',
      color: Color.fromARGB(255, 20, 0, 92),
      hasSpendingAnalytics: true,
    ),
  ];

  final List<Transaction> transactions = const [
    Transaction(
      title: 'Spent at Kayak',
      date: '19 October, 1:32 PM',
      amount: -120,
      type: TransactionType.debit,
    ),
    Transaction(
      title: 'Cashback Received',
      date: '28 August, 7:13 AM',
      amount: 7,
      type: TransactionType.credit,
    ),
    Transaction(
      title: 'Money Added',
      date: '19 October, 1:32 PM',
      amount: 120,
      type: TransactionType.credit,
    ),
    Transaction(
      title: 'Cashback Received',
      date: '28 August, 7:13 AM',
      amount: 7,
      type: TransactionType.credit,
    ),
    Transaction(
      title: 'Paid for order #11538',
      date: '27 August, 11:35 AM',
      amount: -60,
      type: TransactionType.debit,
    ),
    Transaction(
      title: 'Paid at Tesco',
      date: '19 October, 1:45 PM',
      amount: -80,
      type: TransactionType.debit,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _expansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _detailController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );

    // Start listening to device motion for the detail card parallax effect
    _startMotionTracking();
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _detailController.dispose();
    _motionSubscription?.cancel();
    super.dispose();
  }

  void _startMotionTracking() {
    _motionSubscription =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 16),
        ).listen((AccelerometerEvent event) {
          // Only react while in detail view so normal card stack remains flat
          if (_viewState != CardViewState.detail) {
            if (_tiltX != 0.0 || _tiltY != 0.0) {
              setState(() {
                _tiltX = 0.0;
                _tiltY = 0.0;
                _targetTiltX = 0.0;
                _targetTiltY = 0.0;
              });
            }
            return;
          }

          // Convert raw accelerometer values into an intuitive pitch/roll signal.
          final double gx = event.x;
          final double gy = event.y;
          final double gz = event.z == 0 ? 0.0001 : event.z;

          final double roll = math.atan2(gy, gz); // left/right tilt
          final double pitch = math.atan2(
            -gx,
            math.sqrt(gy * gy + gz * gz),
          ); // forward/back tilt

          // Map to a comfortable range and smooth with a lightweight low-pass filter.
          const double maxTiltRadians = 0.45; // ~25 degrees
          const double filterStrength = 0.18;

          _targetTiltX = (roll / maxTiltRadians).clamp(-1.0, 1.0);
          _targetTiltY = (pitch / maxTiltRadians).clamp(-1.0, 1.0);

          final double nextTiltX =
              _tiltX + (_targetTiltX - _tiltX) * filterStrength;
          final double nextTiltY =
              _tiltY + (_targetTiltY - _tiltY) * filterStrength;

          if ((nextTiltX - _tiltX).abs() > 0.0005 ||
              (nextTiltY - _tiltY).abs() > 0.0005) {
            setState(() {
              _tiltX = nextTiltX;
              _tiltY = nextTiltY;
            });
          }
        });
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    if (_viewState == CardViewState.detail) return;

    setState(() {
      // More sensitive drag - lower divisor = more responsive
      _expansionController.value =
          (_expansionController.value + details.primaryDelta! / 200.0).clamp(
            0.0,
            1.0,
          );
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_viewState == CardViewState.detail) return;

    final velocity = details.primaryVelocity ?? 0;
    final shouldExpand = _expansionController.value > 0.3 || velocity > 200;

    if (shouldExpand) {
      _expansionController.animateTo(1.0, curve: Curves.easeOutCubic);
      setState(() => _viewState = CardViewState.expanded);
    } else {
      _expansionController.animateTo(0.0, curve: Curves.easeOutCubic);
      setState(() => _viewState = CardViewState.collapsed);
    }
  }

  void _handleCardTap(int index) {
    if (_viewState == CardViewState.collapsed) {
      _expansionController.animateTo(1.0, curve: Curves.easeOut);
      setState(() => _viewState = CardViewState.expanded);
    } else if (_viewState == CardViewState.expanded) {
      setState(() {
        _selectedCardIndex = index;
        _viewState = CardViewState.detail;
      });
      _detailController.forward();
    }
  }

  void _handleBackFromDetail() {
    _detailController.reverse().then((_) {
      setState(() {
        _selectedCardIndex = null;
        _viewState = CardViewState.expanded;
        _tiltX = 0.0;
        _tiltY = 0.0;
        _targetTiltX = 0.0;
        _targetTiltY = 0.0;
      });
    });
  }

  Color get _backgroundColor {
    if (_viewState == CardViewState.detail && _selectedCardIndex != null) {
      return cards[_selectedCardIndex!].color;
    }
    return const Color(0xFFF5F5F5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onVerticalDragUpdate: _handleVerticalDrag,
                onVerticalDragEnd: _handleDragEnd,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _expansionController,
                    _detailController,
                  ]),
                  builder: (context, _) {
                    return Stack(
                      children: [
                        // Down arrow hint
                        if (_viewState == CardViewState.collapsed)
                          _buildDownArrowHint(),

                        // Card stack
                        ..._buildCardStack(),

                        // Detail view overlay
                        if (_viewState == CardViewState.detail &&
                            _selectedCardIndex != null)
                          _buildDetailView(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownArrowHint() {
    return Positioned(
      top: 300, // Position below the stacked cards
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _expansionController.value < 0.1 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: const Center(
          child: Icon(
            Icons.keyboard_arrow_down,
            size: 32,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCardStack() {
    // Render cards REVERSED so Gift Card (last) renders last (appears on top with highest Z-index)
    // Initial: Only Gift Card visible on top
    // Expanded: All cards fan out showing Travel Card at top
    return List.generate(cards.length, (index) {
      return _buildAnimatedCard(index);
    }).reversed.toList(); // Reversed - last card (Gift) renders last = on top
  }

  Widget _buildAnimatedCard(int index) {
    final card = cards[index];
    final progress = _expansionController.value;
    final isSelected = _selectedCardIndex == index;
    final shouldHide = _selectedCardIndex != null && !isSelected;

    // Apply device motion driven parallax effect to the selected card
    final parallaxX = isSelected ? _tiltX * 18.0 : 0.0; // X offset
    final parallaxY = isSelected ? _tiltY * 18.0 : 0.0; // Y offset
    final parallaxRotateX = isSelected
        ? _tiltY * 0.35
        : 0.0; // Tilt forward/back
    final parallaxRotateY = isSelected
        ? -_tiltX * 0.35
        : 0.0; // Tilt left/right
    final parallaxRotateZ = isSelected ? _tiltX * 0.08 : 0.0; // Subtle twist

    const double baseTop = 300.0;

    // MATCHING YOUR IMAGES:
    // Image 1 (Collapsed): Only Gift Card visible (all cards perfectly stacked)
    // Image 2 (Expanded): Cards fan out - Travel on top, Gift at bottom

    final totalCards = cards.length;
    final reversedIndex = totalCards - 1 - index;

    // EXPANDED STATE: Sequential scrolling - first card scrolls MOST to bottom
    // Travel Card (index 0) scrolls most, Gift Card (index 3) scrolls least
    // Each card scrolls progressively less than the previous one
    final cardScrollFactor = reversedIndex
        .toDouble(); // Higher for Travel, lower for Gift
    final maxScroll = 50.0; // Maximum scroll distance per card
    final expandedY = index * -50.0 + (cardScrollFactor * maxScroll * progress);

    final currentYOffset = expandedY;

    // Z-AXIS TILT: Cards tilt when expanding
    // Lower index cards (Travel) tilt more to reveal cards behind
    final cardDepthFactor = reversedIndex.toDouble();
    final maxRotationRadians = 0.30; // ~17 degrees max
    final rotationX = cardDepthFactor * maxRotationRadians * progress;

    // Compensate for rotation Y-displacement
    final rotationCompensation = cardDepthFactor * progress;

    // Calculate elevation for shadows
    final baseElevation = 8.0 - (index * 1.2);
    final dynamicElevation = baseElevation + (progress * cardDepthFactor * 2.0);

    return Positioned(
      top: isSelected
          ? 70.0 + parallaxY
          : baseTop + currentYOffset - rotationCompensation,
      left: isSelected ? 20 + parallaxX : 20,
      right: isSelected ? 20 - parallaxX : 20,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: shouldHide ? 0.0 : 1.0,
        child: Transform(
          alignment: Alignment.center,
          // Apply parallax rotation when selected, otherwise normal card rotation
          transform: Matrix4.identity()
            ..setEntry(3, 2, isSelected ? 0.0015 : 0.001)
            ..rotateY(isSelected ? parallaxRotateY : 0.0)
            ..rotateX(isSelected ? parallaxRotateX : rotationX)
            ..rotateZ(isSelected ? parallaxRotateZ : 0.0),
          child: GestureDetector(
            onTap: () => _handleCardTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CardWidget(
                card: card,
                elevation: isSelected ? 28.0 : dynamicElevation,
                motionOffset: isSelected ? Offset(_tiltX, _tiltY) : Offset.zero,
                showDepth: isSelected,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    final card = cards[_selectedCardIndex!];
    final offset = Offset(0, 600 * (1 - _detailController.value));

    return Positioned.fill(
      child: Column(
        children: [
          const SizedBox(height: 280),
          Expanded(
            child: Transform.translate(
              offset: offset,
              child: card.hasSpendingAnalytics
                  ? SpendingAnalyticsView(onClose: _handleBackFromDetail)
                  : TransactionListView(
                      transactions: transactions,
                      onClose: _handleBackFromDetail,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CARD WIDGET
// ============================================================================

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

    final Offset contentDrift = Offset(dx * 8.0, dy * 6.0);
    final Offset ribbonDrift = Offset(dx * -12.0, dy * -9.0);

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

// ============================================================================
// TRANSACTION LIST VIEW
// ============================================================================

class TransactionListView extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onClose;

  const TransactionListView({
    super.key,
    required this.transactions,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                FilterChipWidget(label: 'All', isSelected: true),
                SizedBox(width: 8),
                FilterChipWidget(label: 'Debit', isSelected: false),
                SizedBox(width: 8),
                FilterChipWidget(label: 'Credit', isSelected: false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                return TransactionItem(transaction: transactions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey[300]!,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.amount > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'} £${transaction.amount.abs().toInt()}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isCredit
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFE57373),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SPENDING ANALYTICS VIEW
// ============================================================================

class SpendingAnalyticsView extends StatelessWidget {
  final VoidCallback onClose;

  const SpendingAnalyticsView({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spends',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Expanded(child: LimitCard()),
                      SizedBox(width: 12),
                      Expanded(child: WeeklySpendCard()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const PeakSpendCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LimitCard extends StatelessWidget {
  const LimitCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR LIMIT',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '£9100',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: 0.17,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFE89547),
                      ),
                    ),
                  ),
                  const Text(
                    '17%\nRemaining',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklySpendCard extends StatelessWidget {
  const WeeklySpendCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS WEEK',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '£7570',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                BarChart(height: 50, color: Color(0xFF5B4E8C)),
                BarChart(height: 65, color: Color(0xFF6BA5D6)),
                BarChart(height: 90, color: Color(0xFF5BC4E8)),
                BarChart(height: 60, color: Color(0xFFE88DB4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BarChart extends StatelessWidget {
  final double height;
  final Color color;

  const BarChart({super.key, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}

class PeakSpendCard extends StatelessWidget {
  const PeakSpendCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PEAK',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '£768',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 70,
            child: CustomPaint(
              painter: WaveChartPainter(),
              size: const Size(double.infinity, 70),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE88DB4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final points = <Offset>[];

    // Generate smooth wave data
    for (int i = 0; i <= 40; i++) {
      final x = size.width * (i / 40);
      final normalizedI = i / 40;
      final y =
          size.height * 0.5 +
          math.sin(normalizedI * math.pi * 4) * size.height * 0.28 +
          math.sin(normalizedI * math.pi * 2 + 0.5) * size.height * 0.15;
      points.add(Offset(x, y));
    }

    // Draw smooth curve through points
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, controlPoint.dx, controlPoint.dy);
    }

    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
