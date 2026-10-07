import 'package:flutter/material.dart';

/// Modo elegido desde el header. Arranca siguiendo al sistema.
final modoTema = ValueNotifier<ThemeMode>(ThemeMode.system);

// Modo claro: pradera. surfaceContainer pinta el header y la botonera,
// surfaceContainerHigh el panel de acciones del combate.
final ThemeData temaClaro = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4C8C2B)).copyWith(
    surface: const Color(0xFFF7F9EE),
    surfaceContainerLow: const Color(0xFFEEF3DF),
    surfaceContainer: const Color(0xFFDDE8C4),
    surfaceContainerHigh: const Color(0xFFD0DEB0),
    surfaceContainerHighest: const Color(0xFFC3D49F),
  ),
);

// Modo oscuro: cueva, con acento ámbar de antorcha
final ThemeData temaOscuro = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFE0A030),
    brightness: Brightness.dark,
  ).copyWith(
    surface: const Color(0xFF14121C),
    surfaceContainerLow: const Color(0xFF1B1826),
    surfaceContainer: const Color(0xFF221F30),
    surfaceContainerHigh: const Color(0xFF2B2740),
    surfaceContainerHighest: const Color(0xFF353050),
  ),
);

class BotonTema extends StatelessWidget {
  const BotonTema({super.key});

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return IconButton(
      tooltip: esOscuro ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
      visualDensity: VisualDensity.compact,
      onPressed: () => modoTema.value = esOscuro ? ThemeMode.light : ThemeMode.dark,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (hijo, animacion) =>
            ScaleTransition(scale: animacion, child: hijo),
        child: Icon(
          esOscuro ? Icons.light_mode : Icons.dark_mode,
          key: ValueKey(esOscuro),
        ),
      ),
    );
  }
}