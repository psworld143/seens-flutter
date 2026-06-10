import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';

class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final Logger _logger = Logger();
  final AudioPlayer _player = AudioPlayer();

  static const String _grantedAsset = 'sounds/Access Granted.mp3';
  static const String _deniedAsset = 'sounds/Access Denied.mp3';

  Future<void> playGranted() async {
    await _playAsset(_grantedAsset);
  }

  Future<void> playDenied() async {
    await _playAsset(_deniedAsset);
  }

  Future<void> _playAsset(String assetPath) async {
    try {
      _logger.i('Playing sound asset: $assetPath');
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      _logger.e('Failed to play sound ($assetPath): $e');
    }
  }
}
