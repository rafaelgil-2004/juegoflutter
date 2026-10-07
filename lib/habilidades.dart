import 'package:flutter/material.dart';
import 'main.dart';

class NodoHabilidad {
  // Nivel 1: sin habilidad previa
  const NodoHabilidad.inicial({
    required this.id,
    required this.rama,
    required this.habilidad,
    required this.estadistica,
    required this.valorMinimo,
  })  : costoXp = 30,
        costoDiamantes = 8,
        requiere = null;

  // Nivel 2: requiere haber aprendido el nodo previo de su rama
  const NodoHabilidad.avanzado({
    required this.id,
    required this.rama,
    required this.habilidad,
    required this.estadistica,
    required this.valorMinimo,
    required this.requiere,
  })  : costoXp = 60,
        costoDiamantes = 15;

  final String id;
  final String rama;
  final Habilidad habilidad;
  final TipoEstadistica estadistica;
  final int valorMinimo;
  final int costoXp;
  final int costoDiamantes;
  final String? requiere;
}

const arbolesPorClase = <String, List<NodoHabilidad>>{
  'Guerrero': [
    NodoHabilidad.inicial(
      id: 'guerrero_grito',
      rama: 'Furia',
      habilidad: Habilidad(
        nombre: 'Grito de guerra',
        descripcion: '🔥 +40 % de ataque durante 3 turnos.',
        costoMana: 8,
        efecto: EfectoHabilidad(
          tipo: TipoEfecto.furia,
          turnos: 3,
          valor: 0.4,
          sobreSiMismo: true,
        ),
      ),
      estadistica: TipoEstadistica.vitalidad,
      valorMinimo: 22,
    ),
    NodoHabilidad.avanzado(
      id: 'guerrero_furia',
      rama: 'Furia',
      habilidad: Habilidad(
        nombre: 'Furia desatada',
        descripcion: 'Daño ×3. Te curas el 40 % del daño que haces.',
        costoMana: 16,
        multiplicadorDanio: 3.0,
        robaVida: 0.4,
      ),
      estadistica: TipoEstadistica.vitalidad,
      valorMinimo: 26,
      requiere: 'guerrero_grito',
    ),
    NodoHabilidad.inicial(
      id: 'guerrero_postura',
      rama: 'Honor',
      habilidad: Habilidad(
        nombre: 'Postura defensiva',
        descripcion: '🛡️ Reduce un 40 % el daño recibido durante 2 turnos.',
        costoMana: 8,
        efecto: EfectoHabilidad(
          tipo: TipoEfecto.escudo,
          turnos: 2,
          valor: 0.4,
          sobreSiMismo: true,
        ),
      ),
      estadistica: TipoEstadistica.vitalidad,
      valorMinimo: 22,
    ),
    NodoHabilidad.avanzado(
      id: 'guerrero_aturdir',
      rama: 'Honor',
      habilidad: Habilidad(
        nombre: 'Golpe aturdidor',
        descripcion: 'Daño ×2. 💫 Aturde al rival 1 turno.',
        costoMana: 16,
        multiplicadorDanio: 2.0,
        efecto: EfectoHabilidad(tipo: TipoEfecto.aturdimiento, turnos: 1),
      ),
      estadistica: TipoEstadistica.vitalidad,
      valorMinimo: 26,
      requiere: 'guerrero_postura',
    ),
  ],
  'Mago': [
    NodoHabilidad.inicial(
      id: 'mago_bola_fuego',
      rama: 'Fuego',
      habilidad: Habilidad(
        nombre: 'Bola de fuego',
        descripcion: 'Daño ×2,5.',
        costoMana: 15,
        multiplicadorDanio: 2.5,
      ),
      estadistica: TipoEstadistica.inteligencia,
      valorMinimo: 20,
    ),
    NodoHabilidad.avanzado(
      id: 'mago_meteoros',
      rama: 'Fuego',
      habilidad: Habilidad(
        nombre: 'Lluvia de meteoros',
        descripcion: '3 golpes de daño ×1,5 cada uno.',
        costoMana: 30,
        multiplicadorDanio: 1.5,
        golpes: 3,
      ),
      estadistica: TipoEstadistica.inteligencia,
      valorMinimo: 24,
      requiere: 'mago_bola_fuego',
    ),
    NodoHabilidad.inicial(
      id: 'mago_absorber',
      rama: 'Arcana',
      habilidad: Habilidad(
        nombre: 'Absorber maná',
        descripcion: 'Daño ×1,5. Recuperas 12 PM.',
        costoMana: 6,
        multiplicadorDanio: 1.5,
        robaMana: 12,
      ),
      estadistica: TipoEstadistica.inteligencia,
      valorMinimo: 20,
    ),
    NodoHabilidad.avanzado(
      id: 'mago_escudo',
      rama: 'Arcana',
      habilidad: Habilidad(
        nombre: 'Escudo arcano',
        descripcion: '🛡️ Reduce un 50 % el daño recibido 2 turnos y te curas el 20 % de tu vida.',
        costoMana: 20,
        curaPorcentaje: 0.2,
        efecto: EfectoHabilidad(
          tipo: TipoEfecto.escudo,
          turnos: 2,
          valor: 0.5,
          sobreSiMismo: true,
        ),
      ),
      estadistica: TipoEstadistica.inteligencia,
      valorMinimo: 24,
      requiere: 'mago_absorber',
    ),
  ],
  'Arquero': [
    NodoHabilidad.inicial(
      id: 'arquero_certero',
      rama: 'Precisión',
      habilidad: Habilidad(
        nombre: 'Disparo certero',
        descripcion: 'Daño ×1,8. Crítico garantizado.',
        costoMana: 8,
        multiplicadorDanio: 1.8,
        criticoGarantizado: true,
      ),
      estadistica: TipoEstadistica.destreza,
      valorMinimo: 18,
    ),
    NodoHabilidad.avanzado(
      id: 'arquero_mortal',
      rama: 'Precisión',
      habilidad: Habilidad(
        nombre: 'Tiro mortal',
        descripcion: 'Daño ×2,5. Crítico garantizado.',
        costoMana: 16,
        multiplicadorDanio: 2.5,
        criticoGarantizado: true,
      ),
      estadistica: TipoEstadistica.destreza,
      valorMinimo: 22,
      requiere: 'arquero_certero',
    ),
    NodoHabilidad.inicial(
      id: 'arquero_envenenada',
      rama: 'Ráfaga',
      habilidad: Habilidad(
        nombre: 'Flecha envenenada',
        descripcion: 'Daño ×1,5. ☠️ Veneno durante 3 turnos.',
        costoMana: 8,
        multiplicadorDanio: 1.5,
        efecto: EfectoHabilidad(tipo: TipoEfecto.veneno, turnos: 3, valor: 0.4),
      ),
      estadistica: TipoEstadistica.destreza,
      valorMinimo: 18,
    ),
    NodoHabilidad.avanzado(
      id: 'arquero_lluvia',
      rama: 'Ráfaga',
      habilidad: Habilidad(
        nombre: 'Lluvia de flechas',
        descripcion: '3 golpes de daño ×1,2 cada uno.',
        costoMana: 16,
        multiplicadorDanio: 1.2,
        golpes: 3,
      ),
      estadistica: TipoEstadistica.destreza,
      valorMinimo: 22,
      requiere: 'arquero_envenenada',
    ),
  ],
  'Pícaro': [
    NodoHabilidad.inicial(
      id: 'picaro_venenosa',
      rama: 'Sombras',
      habilidad: Habilidad(
        nombre: 'Puñalada venenosa',
        descripcion: 'Daño ×1,6. ☠️ Veneno durante 3 turnos.',
        costoMana: 8,
        multiplicadorDanio: 1.6,
        efecto: EfectoHabilidad(tipo: TipoEfecto.veneno, turnos: 3, valor: 0.5),
      ),
      estadistica: TipoEstadistica.agilidad,
      valorMinimo: 21,
    ),
    NodoHabilidad.avanzado(
      id: 'picaro_gracia',
      rama: 'Sombras',
      habilidad: Habilidad(
        nombre: 'Golpe de gracia',
        descripcion: 'Daño ×3,6.',
        costoMana: 16,
        multiplicadorDanio: 3.6,
      ),
      estadistica: TipoEstadistica.agilidad,
      valorMinimo: 25,
      requiere: 'picaro_venenosa',
    ),
    NodoHabilidad.inicial(
      id: 'picaro_tajo',
      rama: 'Viento',
      habilidad: Habilidad(
        nombre: 'Tajo veloz',
        descripcion: '2 golpes de daño ×1,2 cada uno.',
        costoMana: 6,
        multiplicadorDanio: 1.2,
        golpes: 2,
      ),
      estadistica: TipoEstadistica.agilidad,
      valorMinimo: 21,
    ),
    NodoHabilidad.avanzado(
      id: 'picaro_humo',
      rama: 'Viento',
      habilidad: Habilidad(
        nombre: 'Bomba de humo',
        descripcion: 'Daño ×1,5. 💫 Aturde al rival 1 turno.',
        costoMana: 14,
        multiplicadorDanio: 1.5,
        efecto: EfectoHabilidad(tipo: TipoEfecto.aturdimiento, turnos: 1),
      ),
      estadistica: TipoEstadistica.agilidad,
      valorMinimo: 25,
      requiere: 'picaro_tajo',
    ),
  ],
};

class ListaArbolHabilidades extends StatelessWidget {
  const ListaArbolHabilidades({super.key, required this.juego});

  final JuegoRpg juego;

  @override
  Widget build(BuildContext context) {
    final nodos = juego.arbolActual;
    // El Set conserva el orden de aparición de cada rama
    final ramas = nodos.map((nodo) => nodo.rama).toSet();
    final estilos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final rama in ramas) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Rama $rama', style: estilos.titleLarge),
          ),
          for (final nodo in nodos.where((n) => n.rama == rama))
            _TarjetaNodo(juego: juego, nodo: nodo),
        ],
      ],
    );
  }
}

class _TarjetaNodo extends StatelessWidget {
  const _TarjetaNodo({required this.juego, required this.nodo});

  final JuegoRpg juego;
  final NodoHabilidad nodo;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final habilidad = nodo.habilidad;
    final aprendida = juego.aprendio(nodo);
    final bloqueo = juego.motivoBloqueo(nodo);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${habilidad.nombre}  ·  🔷 ${habilidad.costoMana}',
              style: estilos.titleMedium,
            ),
            Text(habilidad.descripcion, style: estilos.bodySmall),
            const SizedBox(height: 8),
            if (aprendida)
              const Chip(label: Text('Aprendida ✓'))
            else if (bloqueo != null)
              Text('🔒 $bloqueo', style: estilos.bodySmall)
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: juego.experiencia >= nodo.costoXp
                          ? () => juego.aprenderHabilidad(nodo, conDiamantes: false)
                          : null,
                      child: Text('✨ ${nodo.costoXp} XP'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: juego.diamantes >= nodo.costoDiamantes
                          ? () => juego.aprenderHabilidad(nodo, conDiamantes: true)
                          : null,
                      child: Text('💎 ${nodo.costoDiamantes}'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}