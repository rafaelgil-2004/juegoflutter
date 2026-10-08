import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  static bool _isPlaying = false;

  /// Inicia la música de fondo en bucle
  static Future<void> playBgm(String assetPath) async {
    if (_isPlaying) return;

    // Configura para que la música se repita indefinidamente
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);

    // Reproduce el archivo desde los assets
    await _bgmPlayer.play(AssetSource(assetPath));
    _isPlaying = true;
  }

  /// Pausa la música de fondo
  static Future<void> pauseBgm() async {
    await _bgmPlayer.pause();
    _isPlaying = false;
  }

  /// Reanuda la música de fondo
  static Future<void> resumeBgm() async {
    await _bgmPlayer.resume();
    _isPlaying = true;
  }

  /// Detiene la música completamente
  static Future<void> stopBgm() async {
    await _bgmPlayer.stop();
    _isPlaying = false;
  }

  /// Ajusta el volumen (de 0.0 a 1.0)
  static Future<void> setVolume(double volume) async {
    await _bgmPlayer.setVolume(volume);
  }
}