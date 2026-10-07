import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

const anchoMinimoPantallaAncha = 800.0;
const ladoCortoMinimoEscritorio = 600.0;

/// true en computadoras y tablets. Un teléfono acostado es ancho pero su lado
/// corto sigue siendo chico, por eso no alcanza con mirar solo el ancho.
bool esPantallaAncha(BuildContext context) {
  final tamano = MediaQuery.sizeOf(context);
  return tamano.width >= anchoMinimoPantallaAncha &&
      tamano.shortestSide >= ladoCortoMinimoEscritorio;
}

class Anuncio {
  const Anuncio({
    required this.emoji,
    required this.titulo,
    required this.texto,
    required this.color,
  });

  final String emoji;
  final String titulo;
  final String texto;
  final Color color;

  static const todos = [
    Anuncio(
      emoji: '🧸',
      titulo: 'Juguetería Arcoíris',
      texto: '¡Los mejores juguetes con 20% de descuento!',
      color: Colors.deepOrange,
    ),
    Anuncio(
      emoji: '🍦',
      titulo: 'Helados Polar',
      texto: 'Tu helado favorito, ahora con topping gratis.',
      color: Colors.pink,
    ),
    Anuncio(
      emoji: '🚲',
      titulo: 'Super Bici',
      texto: 'Aventuras sobre ruedas para toda la familia.',
      color: Colors.teal,
    ),
    Anuncio(
      emoji: '📚',
      titulo: 'Libros Mágicos',
      texto: 'Cuentos que cobran vida. ¡Descúbrelos!',
      color: Colors.indigo,
    ),
  ];
}

class _TarjetaAnuncio extends StatelessWidget {
  const _TarjetaAnuncio({super.key, required this.anuncio});

  final Anuncio anuncio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: anuncio.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(anuncio.emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 12),
          Text(
            anuncio.titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            anuncio.texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class BannerPublicidad extends StatefulWidget {
  const BannerPublicidad({super.key});

  @override
  State<BannerPublicidad> createState() => _EstadoBannerPublicidad();
}

class _EstadoBannerPublicidad extends State<BannerPublicidad> {
  int _indice = 0;
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer.periodic(const Duration(seconds: 8), (_) {
      setState(() => _indice = (_indice + 1) % Anuncio.todos.length);
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SizedBox(
        width: 280,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('PUBLICIDAD', style: estilos.labelSmall),
              const SizedBox(height: 8),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  // La key distinta por anuncio hace que AnimatedSwitcher anime el cambio
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _TarjetaAnuncio(
                      key: ValueKey(_indice),
                      anuncio: Anuncio.todos[_indice],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Con la cuenta PRO no verás anuncios',
                textAlign: TextAlign.center,
                style: estilos.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnuncioIntersticial extends StatefulWidget {
  const AnuncioIntersticial({super.key});

  @override
  State<AnuncioIntersticial> createState() => _EstadoAnuncioIntersticial();
}

class _EstadoAnuncioIntersticial extends State<AnuncioIntersticial> {
  static const _segundosEspera = 5;

  final _anuncio = Anuncio.todos[Random().nextInt(Anuncio.todos.length)];
  int _segundosRestantes = _segundosEspera;
  Timer? _temporizador;

  bool get _puedeSaltar => _segundosRestantes <= 0;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer.periodic(const Duration(seconds: 1), (temporizador) {
      setState(() => _segundosRestantes--);
      if (_segundosRestantes <= 0) temporizador.cancel();
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PopScope(canPop: false) bloquea el botón/gesto de atrás de Android;
    // el pop() programático del botón Saltar sí funciona.
    return PopScope(
      canPop: false,
      child: Dialog.fullscreen(
        backgroundColor: _anuncio.color,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PUBLICIDAD',
                        style: TextStyle(color: Colors.white70, letterSpacing: 2),
                      ),
                      const SizedBox(height: 24),
                      Text(_anuncio.emoji, style: const TextStyle(fontSize: 120)),
                      const SizedBox(height: 16),
                      Text(
                        _anuncio.titulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _anuncio.texto,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _anuncio.color,
                        ),
                        child: const Text('Ver más'),
                      ),
                    ],
                  ),
                ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _puedeSaltar
                    ? FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Saltar'),
                      )
                    : Chip(label: Text('Saltar en $_segundosRestantes s')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}