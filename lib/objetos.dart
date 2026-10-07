import 'package:flutter/material.dart';
import 'main.dart';

enum TipoPocion { vida, mana }

class Pocion {
  const Pocion({
    required this.nombre,
    required this.tipo,
    required this.porcentaje,
    required this.precio,
  });

  final String nombre;
  final TipoPocion tipo;
  final double porcentaje;
  final int precio;

  Color get color =>
      tipo == TipoPocion.vida ? Colors.red.shade400 : Colors.blue.shade400;

  double get tamanoIcono => 20 + porcentaje * 16;

  String get efecto {
    final recurso = tipo == TipoPocion.vida ? 'vida máxima' : 'maná máximo';
    return 'Recupera el ${(porcentaje * 100).round()} % de tu $recurso';
  }

  static const todas = [
    Pocion(nombre: 'Poción de vida pequeña', tipo: TipoPocion.vida, porcentaje: 0.3, precio: 15),
    Pocion(nombre: 'Poción de vida mediana', tipo: TipoPocion.vida, porcentaje: 0.6, precio: 30),
    Pocion(nombre: 'Poción de vida grande', tipo: TipoPocion.vida, porcentaje: 1.0, precio: 60),
    Pocion(nombre: 'Poción de maná pequeña', tipo: TipoPocion.mana, porcentaje: 0.3, precio: 15),
    Pocion(nombre: 'Poción de maná mediana', tipo: TipoPocion.mana, porcentaje: 0.6, precio: 30),
    Pocion(nombre: 'Poción de maná grande', tipo: TipoPocion.mana, porcentaje: 1.0, precio: 60),
  ];
}

Future<void> mostrarTiendaPociones(BuildContext context, JuegoRpg juego) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (_) => PanelTiendaPociones(juego: juego),
  );
}

class PanelTiendaPociones extends StatelessWidget {
  const PanelTiendaPociones({super.key, required this.juego});

  final JuegoRpg juego;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: juego,
      builder: (context, _) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              Text('Tienda', style: estilos.headlineSmall),
              const SizedBox(height: 4),
              Text('🪙 Oro: ${juego.oro}', style: estilos.titleMedium),
              const SizedBox(height: 12),
              for (final pocion in Pocion.todas)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Icon(
                      Icons.science,
                      color: pocion.color,
                      size: pocion.tamanoIcono,
                    ),
                    title: Text(pocion.nombre),
                    subtitle: Text(
                      '${pocion.efecto}\nTienes: ${juego.cantidadDe(pocion)}',
                    ),
                    isThreeLine: true,
                    trailing: FilledButton(
                      onPressed: juego.oro >= pocion.precio
                          ? () => juego.comprarPocion(pocion)
                          : null,
                      child: Text('🪙 ${pocion.precio}'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}