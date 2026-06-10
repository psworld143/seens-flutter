import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class HIDScannerService {
  static final HIDScannerService _instance = HIDScannerService._internal();
  factory HIDScannerService() => _instance;
  HIDScannerService._internal();

  final StreamController<String> _scanController =
      StreamController<String>.broadcast();
  Stream<String> get scanStream => _scanController.stream;

  final FocusNode _focusNode = FocusNode();
  FocusNode get focusNode => _focusNode;

  String _buffer = '';
  Timer? _inputTimer;
  DateTime? _lastInputTime;

  // Configuration
  static const Duration _inputTimeout = Duration(milliseconds: 100);
  static const int _minScanLength = 8;
  static const int _maxScanLength = 50;

  bool _isListening = false;
  bool get isListening => _isListening;

  void startListening() {
    if (_isListening) return;

    _isListening = true;
    _focusNode.requestFocus();
    _focusNode.addListener(_onFocusChange);

    // Attach keyboard listener
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  void stopListening() {
    if (!_isListening) return;

    _isListening = false;
    _focusNode.removeListener(_onFocusChange);
    HardwareKeyboard.instance.removeHandler(_onKey);
    _inputTimer?.cancel();
    _buffer = '';
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isListening) {
      // Regain focus if lost
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isListening) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  bool _onKey(KeyEvent event) {
    if (!_isListening || event is! KeyDownEvent) return false;

    final now = DateTime.now();

    // Check if this is likely scanner input (fast typing)
    if (_lastInputTime != null) {
      final timeDiff = now.difference(_lastInputTime!);
      if (timeDiff > _inputTimeout) {
        // Too slow, clear buffer
        _buffer = '';
      }
    }
    _lastInputTime = now;

    // Cancel existing timer
    _inputTimer?.cancel();

    // Handle key input
    final keyLabel = event.logicalKey.keyLabel;

    if (keyLabel.isNotEmpty &&
        keyLabel.length == 1 &&
        !keyLabel.startsWith('Key')) {
      _buffer += keyLabel;
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      _processScan();
      return false;
    }

    _scheduleTimeout();
    return false;
  }

  void _scheduleTimeout() {
    _inputTimer = Timer(_inputTimeout, () {
      _processScan();
    });
  }

  void _processScan() {
    _inputTimer?.cancel();
    _lastInputTime = null;

    if (_buffer.length >= _minScanLength && _buffer.length <= _maxScanLength) {
      // Valid scan detected
      _scanController.add(_buffer);
      _buffer = '';
    } else {
      // Invalid or incomplete scan
      _buffer = '';
    }
  }

  void dispose() {
    stopListening();
    _scanController.close();
  }
}

class HIDScannerDetector {
  static bool isLikelyScannerInput(String input, Duration timeSpan) {
    // Heuristics to detect scanner input vs manual typing
    if (input.length < 8) return false;

    // Check for common QR/RFID patterns
    if (_containsQRPattern(input)) return true;
    if (_containsRFIDPattern(input)) return true;

    // Check typing speed (scanners are very fast)
    final charsPerSecond = input.length / timeSpan.inMilliseconds * 1000;
    return charsPerSecond >
        15; // More than 15 chars per second suggests scanner
  }

  static bool _containsQRPattern(String input) {
    // Common QR code patterns
    final qrPatterns = [
      RegExp(r'^[A-Z0-9]{8,}$'), // Alphanumeric codes
      RegExp(r'^\d{10,}$'), // Numeric codes
      RegExp(r'^[A-Z]{2}\d{6,}$'), // Format like AB123456
    ];

    return qrPatterns.any((pattern) => pattern.hasMatch(input));
  }

  static bool _containsRFIDPattern(String input) {
    // Common RFID patterns
    final rfidPatterns = [
      RegExp(r'^[0-9A-F]{8,}$'), // Hexadecimal
      RegExp(r'^\d{12,}$'), // Long numeric
      RegExp(r'^[A-F0-9]{4,}-[A-F0-9]{4,}-[A-F0-9]{4,}$'), // UUID-like
    ];

    return rfidPatterns.any((pattern) => pattern.hasMatch(input));
  }
}
