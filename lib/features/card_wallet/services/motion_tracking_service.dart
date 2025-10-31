import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

class MotionTrackingService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  double _tiltX = 0.0;
  double _tiltY = 0.0;
  double _targetTiltX = 0.0;
  double _targetTiltY = 0.0;

  double get tiltX => _tiltX;
  double get tiltY => _tiltY;

  final void Function(double tiltX, double tiltY) onTiltUpdate;

  MotionTrackingService({required this.onTiltUpdate});

  void startTracking() {
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 16),
    ).listen((AccelerometerEvent event) {
      final double gx = event.x;
      final double gy = event.y;
      final double gz = event.z;

      // Convert to pitch and roll (in radians)
      final double roll = math.atan2(gy, gz);
      final double pitch = math.atan2(-gx, math.sqrt(gy * gy + gz * gz));

      // Low-pass filter for smooth motion (iOS-like smoothing)
      const double filterStrength = 0.18;
      _targetTiltX = pitch;
      _targetTiltY = roll;

      _tiltX = _tiltX * (1.0 - filterStrength) + _targetTiltX * filterStrength;
      _tiltY = _tiltY * (1.0 - filterStrength) + _targetTiltY * filterStrength;

      // Notify listeners
      onTiltUpdate(_tiltX, _tiltY);
    });
  }

  void stopTracking() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  void dispose() {
    stopTracking();
  }
}
