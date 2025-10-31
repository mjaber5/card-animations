import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../services/motion_tracking_service.dart';
import 'card_widget.dart';
import 'transaction_list_view.dart';
import 'spending_analytics_view.dart';

class CardListScreen extends StatefulWidget {
  final List<CreditCard> cards;
  final List<Transaction> transactions;

  const CardListScreen({
    super.key,
    required this.cards,
    required this.transactions,
  });

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen>
    with TickerProviderStateMixin {
  late AnimationController _expansionController;
  late AnimationController _detailController;
  late MotionTrackingService _motionTrackingService;

  CardViewState _viewState = CardViewState.collapsed;
  int? _selectedCardIndex;

  // Device motion driven parallax effect
  double _tiltX = 0.0;
  double _tiltY = 0.0;

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

    // Initialize motion tracking service
    _motionTrackingService = MotionTrackingService(
      onTiltUpdate: (tiltX, tiltY) {
        if (_viewState == CardViewState.detail) {
          setState(() {
            _tiltX = tiltX;
            _tiltY = tiltY;
          });
        } else if (_tiltX != 0.0 || _tiltY != 0.0) {
          setState(() {
            _tiltX = 0.0;
            _tiltY = 0.0;
          });
        }
      },
    );
    _motionTrackingService.startTracking();
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _detailController.dispose();
    _motionTrackingService.dispose();
    super.dispose();
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
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: _handleVerticalDrag,
          onVerticalDragEnd: _handleDragEnd,
          child: Stack(
            children: [
              ..._buildCardStack(),
              if (_viewState == CardViewState.detail) _buildDetailView(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCardStack() {
    // Initial: Only Gift Card visible on top
    // Expanded: All cards fan out showing Travel Card at top
    return List.generate(widget.cards.length, (index) {
      return _buildAnimatedCard(index);
    }).reversed.toList(); // Reversed - last card (Gift) renders last = on top
  }

  Widget _buildAnimatedCard(int index) {
    final card = widget.cards[index];
    final progress = _expansionController.value;
    final isSelected = _selectedCardIndex == index;
    final shouldHide = _selectedCardIndex != null && !isSelected;

    // Apply device motion driven parallax effect to the selected card
    final parallaxX = isSelected ? _tiltX * 18.0 : 0.0; // X offset
    final parallaxY = isSelected ? _tiltY * 18.0 : 0.0; // Y offset
    final parallaxRotateX = isSelected ? _tiltY * 0.35 : 0.0; // Tilt forward/back
    final parallaxRotateY = isSelected ? -_tiltX * 0.35 : 0.0; // Tilt left/right
    final parallaxRotateZ = isSelected ? _tiltX * 0.08 : 0.0; // Subtle twist

    const double baseTop = 300.0;

    // MATCHING YOUR IMAGES:
    // Image 1 (Collapsed): Only Gift Card visible (all cards perfectly stacked)
    // Image 2 (Expanded): Cards fan out - Travel on top, Gift at bottom

    final totalCards = widget.cards.length;
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
    final card = widget.cards[_selectedCardIndex!];
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
                      transactions: widget.transactions,
                      onClose: _handleBackFromDetail,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
