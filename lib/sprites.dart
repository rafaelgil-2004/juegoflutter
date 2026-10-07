import 'package:flutter/material.dart';

/// Animaciones disponibles para cada clase.
enum AnimSprite { standby, ataque, dano }

/// Tamaño de un frame dentro de las tiras PNG (ver slice_sprites.py).
const double anchoFrameSprite = 170;
const double altoFrameSprite = 156;

/// Cantidad de frames de cada tira. Debe coincidir con slice_sprites.py.
const Map<String, Map<AnimSprite, int>> _framesPorClase = {
  'guerrero': {AnimSprite.standby: 3, AnimSprite.ataque: 4, AnimSprite.dano: 3},
  'mago': {AnimSprite.standby: 3, AnimSprite.ataque: 4, AnimSprite.dano: 3},
  'arquero': {AnimSprite.standby: 3, AnimSprite.ataque: 3, AnimSprite.dano: 3},
  'picaro': {AnimSprite.standby: 3, AnimSprite.ataque: 4, AnimSprite.dano: 3},
};

/// 'Pícaro' -> 'picaro'. Devuelve null si la clase no tiene sprites.
String? idSpriteDeClase(String nombreClase) {
  final id = nombreClase
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
  return _framesPorClase.containsKey(id) ? id : null;
}

String _nombreArchivo(AnimSprite anim) =>
    anim == AnimSprite.dano ? 'dano' : anim.name;

/// Muestra un frame de una tira horizontal de sprites.
/// [progreso] va de 0 a 1 y elige el frame; en standby se hace en bucle
/// desde fuera con un AnimationController que repite.
class SpriteHoja extends StatelessWidget {
  const SpriteHoja({
    super.key,
    required this.sprite,
    required this.animacion,
    required this.progreso,
    required this.alto,
  });

  final String sprite;
  final AnimSprite animacion;
  final double progreso;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final frames = _framesPorClase[sprite]![animacion]!;
    final indice = (progreso * frames).floor().clamp(0, frames - 1);
    final ancho = alto * anchoFrameSprite / altoFrameSprite;

    return SizedBox(
      width: ancho,
      height: alto,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: ancho * frames,
          maxWidth: ancho * frames,
          child: Transform.translate(
            offset: Offset(-indice * ancho, 0),
            child: Image.asset(
              'assets/sprites/${sprite}_${_nombreArchivo(animacion)}.png',
              width: ancho * frames,
              height: alto,
              fit: BoxFit.fill,
              // pixel art: sin suavizado
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
      ),
    );
  }
}

// Pradera para el modo claro y cueva para el modo oscuro
const String fondoCombateClaro = 'assets/sprites/fondo_combate.png';
const String fondoCombateOscuro = 'assets/sprites/fondo_combate_cueva.png';

String fondoCombateSegunBrillo(Brightness brillo) =>
    brillo == Brightness.dark ? fondoCombateOscuro : fondoCombateClaro;
    
const String fondoTaberna = 'assets/sprites/taberna.jpeg';

/// Cómo ataca cada clase: embistiendo, con un hechizo o con un proyectil.
enum TipoAtaque { cuerpoACuerpo, magia, proyectil }

TipoAtaque tipoAtaqueDeSprite(String? sprite) => switch (sprite) {
      'mago' => TipoAtaque.magia,
      'arquero' => TipoAtaque.proyectil,
      _ => TipoAtaque.cuerpoACuerpo,
    };

const String imagenEfectoMagia = 'assets/sprites/efecto_magia.png';
const String imagenFlechas = 'assets/sprites/arquero_flechas.png';
const double anchoFrameFlecha = 77;
const double altoFrameFlecha = 20;

/// Un frame de una tira horizontal. [ancho] y [alto] son los del frame ya escalado.
class FrameDeTira extends StatelessWidget {
  const FrameDeTira({
    super.key,
    required this.asset,
    required this.frames,
    required this.indice,
    required this.ancho,
    required this.alto,
  });

  final String asset;
  final int frames;
  final int indice;
  final double ancho;
  final double alto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: alto,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: ancho * frames,
          maxWidth: ancho * frames,
          child: Transform.translate(
            offset: Offset(-indice * ancho, 0),
            child: Image.asset(
              asset,
              width: ancho * frames,
              height: alto,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
      ),
    );
  }
}