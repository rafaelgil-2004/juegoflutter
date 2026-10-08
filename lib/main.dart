import 'dart:math';
import 'package:flutter/material.dart';
import 'anuncios.dart';
import 'tienda.dart';
import 'objetos.dart';
import 'habilidades.dart';
import 'sprites.dart';
import 'tema.dart';
import 'audio_flutter.dart';

void main() => runApp(const AplicacionRpg());

class Estadisticas {
  const Estadisticas({
    required this.vitalidad,
    required this.ataque,
    required this.inteligencia,
    required this.destreza,
    required this.agilidad,
  });

  final int vitalidad;
  final int ataque;
  final int inteligencia;
  final int destreza;
  final int agilidad;

  int get vidaMaxima => 20 + vitalidad * 5;
  int get manaMaximo => 10 + inteligencia * 3;
  double get probabilidadCritico => min(0.6, destreza * 0.015);
  double get probabilidadEsquivar => min(0.5, agilidad * 0.01);

  String get resumen =>'❤️ $vitalidad   ⚔️ $ataque   🔷 $inteligencia   🎯 $destreza   💨 $agilidad';

    int valorDe(TipoEstadistica tipo) => switch (tipo) {
        TipoEstadistica.vitalidad => vitalidad,
        TipoEstadistica.ataque => ataque,
        TipoEstadistica.inteligencia => inteligencia,
        TipoEstadistica.destreza => destreza,
        TipoEstadistica.agilidad => agilidad,
      };

  Estadisticas conUnPuntoMas(TipoEstadistica tipo) => Estadisticas(
        vitalidad: vitalidad + (tipo == TipoEstadistica.vitalidad ? 1 : 0),
        ataque: ataque + (tipo == TipoEstadistica.ataque ? 1 : 0),
        inteligencia: inteligencia + (tipo == TipoEstadistica.inteligencia ? 1 : 0),
        destreza: destreza + (tipo == TipoEstadistica.destreza ? 1 : 0),
        agilidad: agilidad + (tipo == TipoEstadistica.agilidad ? 1 : 0),
      );
}

enum TipoEfecto {
  veneno('Veneno', '☠️'),
  aturdimiento('Aturdimiento', '💫'),
  escudo('Escudo', '🛡️'),
  furia('Furia', '🔥');

  const TipoEfecto(this.nombre, this.emoji);

  final String nombre;
  final String emoji;
}

// Efecto que trae una habilidad. El significado de `valor` depende del tipo:
// veneno = fracción de tu ataque que daña por turno, escudo = fracción de daño
// que bloquea, furia = fracción extra de ataque.
class EfectoHabilidad {
  const EfectoHabilidad({
    required this.tipo,
    required this.turnos,
    this.valor = 0,
    this.sobreSiMismo = false,
  });

  final TipoEfecto tipo;
  final int turnos;
  final double valor;
  final bool sobreSiMismo;
}

// Efecto ya aplicado a un combatiente
class EfectoActivo {
  EfectoActivo({
    required this.tipo,
    required this.turnosRestantes,
    required this.valor,
  });

  final TipoEfecto tipo;
  int turnosRestantes;
  final double valor;
}

class Habilidad {
  const Habilidad({
    required this.nombre,
    required this.descripcion,
    required this.costoMana,
    this.multiplicadorDanio = 0,
    this.golpes = 1,
    this.criticoGarantizado = false,
    this.robaVida = 0,
    this.robaMana = 0,
    this.curaPorcentaje = 0,
    this.efecto,
  });

  final String nombre;
  final String descripcion;
  final int costoMana;
  final double multiplicadorDanio;
  final int golpes;
  final bool criticoGarantizado;
  final double robaVida;
  final int robaMana;
  final double curaPorcentaje;
  final EfectoHabilidad? efecto;

  bool get haceDanio => multiplicadorDanio > 0;

  static const golpePoderoso = Habilidad(
    nombre: 'Golpe poderoso',
    descripcion: 'Un ataque con el doble de daño.',
    costoMana: 10,
    multiplicadorDanio: 2.0,
  );
}

class Combatiente {
  Combatiente({
    required this.nombre,
    required this.emoji,
    required this.arma,
    required this.estadisticas,
    this.sprite,
    this.habilidades = const [],
    this.experienciaQueOtorga = 0,
    this.oroQueOtorga = 0,
  })  : vida = estadisticas.vidaMaxima,
        mana = estadisticas.manaMaximo;

  final String nombre;
  final String emoji;
  final String arma;
  // Id de los sprites (guerrero, mago...). null = se dibuja con emojis.
  final String? sprite;
  final List<Habilidad> habilidades;
  final int experienciaQueOtorga;
  final int oroQueOtorga;
  Estadisticas estadisticas;
  int vida;
  int mana;

  int get vidaMaxima => estadisticas.vidaMaxima;
  int get manaMaximo => estadisticas.manaMaximo;
  bool get estaVivo => vida > 0;

  bool puedeUsar(Habilidad habilidad) => mana >= habilidad.costoMana;

  void recibirDanio(int cantidad) => vida = max(0, vida - cantidad);
  void curar(int cantidad) => vida = min(vidaMaxima, vida + cantidad);
  void recuperarMana(int cantidad) => mana = min(manaMaximo, mana + cantidad);

  final List<EfectoActivo> efectos = [];

  EfectoActivo? efecto(TipoEfecto tipo) {
    for (final activo in efectos) {
      if (activo.tipo == tipo) return activo;
    }
    return null;
  }

  bool tiene(TipoEfecto tipo) => efecto(tipo) != null;

  // Volver a aplicar el mismo efecto lo reemplaza (refresca la duración)
  void aplicarEfecto(EfectoActivo nuevo) {
    efectos.removeWhere((activo) => activo.tipo == nuevo.tipo);
    efectos.add(nuevo);
  }

  int get ataqueEfectivo {
    final furia = efecto(TipoEfecto.furia);
    if (furia == null) return estadisticas.ataque;
    return (estadisticas.ataque * (1 + furia.valor)).round();
  }
}

enum Pantalla { seleccion, combate, taberna, derrota }

enum TipoCuenta { basic, pro }

enum EstadoPartida { detenida, enCurso, pausada }

enum TipoEstadistica {
  vitalidad('Vitalidad', '❤️', '+5 de vida máxima'),
  ataque('Ataque', '⚔️', '+1 de daño base'),
  inteligencia('Inteligencia', '🔷', '+3 de maná máximo'),
  destreza('Destreza', '🎯', '+1,5 % de probabilidad de crítico'),
  agilidad('Agilidad', '💨', '+1 % de esquive y más velocidad de turno');

  const TipoEstadistica(this.nombre, this.emoji, this.efecto);

  final String nombre;
  final String emoji;
  final String efecto;
}

class ClasePersonaje {
  const ClasePersonaje({
    required this.nombre,
    required this.emoji,
    required this.arma,
    required this.descripcion,
    required this.estadisticas,
    required this.habilidades,
  });

  final String nombre;
  final String emoji;
  final String arma;
  final String descripcion;
  final Estadisticas estadisticas;
  final List<Habilidad> habilidades;

  static const todas = [
    ClasePersonaje(
      nombre: 'Guerrero',
      emoji: '🤺',
      arma: '⚔️',
      descripcion: 'Resistente, aguanta muchos golpes.',
      estadisticas: Estadisticas(
        vitalidad: 22,
        ataque: 10,
        inteligencia: 6,
        destreza: 8,
        agilidad: 10,
      ),
      habilidades: [Habilidad.golpePoderoso],
    ),
    ClasePersonaje(
      nombre: 'Mago',
      emoji: '🧙',
      arma: '🪄',
      descripcion: 'Frágil, pero con mucho maná y poder.',
      estadisticas: Estadisticas(
        vitalidad: 8,
        ataque: 14,
        inteligencia: 20,
        destreza: 6,
        agilidad: 8,
      ),
      habilidades: [Habilidad.golpePoderoso],
    ),
    ClasePersonaje(
      nombre: 'Arquero',
      emoji: '🧝',
      arma: '🏹',
      descripcion: 'Puntería certera, golpes críticos frecuentes.',
      estadisticas: Estadisticas(
        vitalidad: 10,
        ataque: 16,
        inteligencia: 6,
        destreza: 18,
        agilidad: 6,
      ),
      habilidades: [Habilidad.golpePoderoso],
    ),
    ClasePersonaje(
      nombre: 'Pícaro',
      emoji: '🥷',
      arma: '🗡️',
      descripcion: 'Veloz, esquiva y siempre ataca primero.',
      estadisticas: Estadisticas(
        vitalidad: 8,
        ataque: 13,
        inteligencia: 6,
        destreza: 8,
        agilidad: 21,
      ),
      habilidades: [Habilidad.golpePoderoso],
    ),
  ];
}

class JuegoRpg extends ChangeNotifier {
  static const _bestiario = [
    ('Ogro', '👹', '🪓'),
    ('Lobo', '🐺', '🦷'),
    ('Zombi', '🧟', '🦴'),
    ('Fantasma', '👻', '💀'),
    ('Dragón', '🐉', '🔥'),
  ];

  final _azar = Random();

  late Combatiente jugador;
  late Combatiente monstruo;
  ClasePersonaje? claseActual;
  int ronda = 1;
  int rondasSuperadas = 0;
  Pantalla pantalla = Pantalla.seleccion;
  String ultimoMensaje = '';

  EstadoPartida estadoPartida = EstadoPartida.detenida;
  int idPartida = 0;

  bool get enCurso => estadoPartida == EstadoPartida.enCurso;

  // Datos de cuenta (simulados): viven fuera de la partida
  String nombreUsuario = 'Jugador123';
  TipoCuenta tipoCuenta = TipoCuenta.basic;
  int diamantes = 0;

  static const combatesEntreAnuncios = 3;
  int combatesDesdeUltimoAnuncio = 0;

  bool get mostrarPublicidad => tipoCuenta == TipoCuenta.basic;
  bool get tocaAnuncio =>
      mostrarPublicidad && combatesDesdeUltimoAnuncio >= combatesEntreAnuncios;

  void anuncioMostrado() => combatesDesdeUltimoAnuncio = 0;

    int experiencia = 0;
  int entrenamientosRealizados = 0;

  int get costoEntrenamientoXp => 20 + 5 * entrenamientosRealizados;
  int get costoEntrenamientoDiamantes => 5 + entrenamientosRealizados;
  bool get alcanzaXp => experiencia >= costoEntrenamientoXp;
  bool get alcanzanDiamantes => diamantes >= costoEntrenamientoDiamantes;

  String _avisoPrevio = '';

  void _publicarMensaje(String texto) {
    ultimoMensaje = _avisoPrevio.isEmpty ? texto : '$_avisoPrevio $texto';
    _avisoPrevio = '';
  }

  bool entrenar(TipoEstadistica tipo, {required bool conDiamantes}) {
    if (conDiamantes) {
      if (!alcanzanDiamantes) return false;
      diamantes -= costoEntrenamientoDiamantes;
    } else {
      if (!alcanzaXp) return false;
      experiencia -= costoEntrenamientoXp;
    }

    final vidaAntes = jugador.vidaMaxima;
    final manaAntes = jugador.manaMaximo;
    jugador.estadisticas = jugador.estadisticas.conUnPuntoMas(tipo);
    // Lo que sube el máximo también se suma al valor actual
    jugador.vida += jugador.vidaMaxima - vidaAntes;
    jugador.mana += jugador.manaMaximo - manaAntes;

    entrenamientosRealizados++;
    ultimoMensaje =
        '${tipo.nombre} aumentó a ${jugador.estadisticas.valorDe(tipo)}.';
    notifyListeners();
    return true;
  }

  final Set<String> habilidadesAprendidas = {};

  List<NodoHabilidad> get arbolActual =>
      arbolesPorClase[claseActual?.nombre] ?? const [];

  bool aprendio(NodoHabilidad nodo) => habilidadesAprendidas.contains(nodo.id);

  // Devuelve por qué el nodo todavía no se puede aprender (null si cumple los requisitos)
  String? motivoBloqueo(NodoHabilidad nodo) {
    final previo = nodo.requiere;
    if (previo != null && !habilidadesAprendidas.contains(previo)) {
      final nombrePrevio =
          arbolActual.firstWhere((n) => n.id == previo).habilidad.nombre;
      return 'Requiere aprender $nombrePrevio';
    }
    final actual = jugador.estadisticas.valorDe(nodo.estadistica);
    if (actual < nodo.valorMinimo) {
      return 'Requiere ${nodo.estadistica.nombre} ${nodo.valorMinimo} (tienes $actual)';
    }
    return null;
  }

  bool aprenderHabilidad(NodoHabilidad nodo, {required bool conDiamantes}) {
    if (aprendio(nodo) || motivoBloqueo(nodo) != null) return false;

    if (conDiamantes) {
      if (diamantes < nodo.costoDiamantes) return false;
      diamantes -= nodo.costoDiamantes;
    } else {
      if (experiencia < nodo.costoXp) return false;
      experiencia -= nodo.costoXp;
    }

    habilidadesAprendidas.add(nodo.id);
    jugador.habilidades.add(nodo.habilidad);
    ultimoMensaje = 'Aprendiste ${nodo.habilidad.nombre}.';
    notifyListeners();
    return true;
  }

  int oro = 0;
  final Map<Pocion, int> inventario = {};

  int cantidadDe(Pocion pocion) => inventario[pocion] ?? 0;

  bool puedeUsarPocion(Pocion pocion) {
    if (cantidadDe(pocion) == 0) return false;
    return switch (pocion.tipo) {
      TipoPocion.vida => jugador.vida < jugador.vidaMaxima,
      TipoPocion.mana => jugador.mana < jugador.manaMaximo,
    };
  }

  bool comprarPocion(Pocion pocion) {
    if (oro < pocion.precio) return false;
    oro -= pocion.precio;
    inventario[pocion] = cantidadDe(pocion) + 1;
    ultimoMensaje = 'Compraste ${pocion.nombre}.';
    notifyListeners();
    return true;
  }

  // Devuelve true para encajar con las demás acciones del jugador
  bool usarPocion(Pocion pocion) {
    inventario[pocion] = cantidadDe(pocion) - 1;

    final esVida = pocion.tipo == TipoPocion.vida;
    final maximo = esVida ? jugador.vidaMaxima : jugador.manaMaximo;
    final recuperado = (maximo * pocion.porcentaje).round();
    if (esVida) {
      jugador.curar(recuperado);
    } else {
      jugador.recuperarMana(recuperado);
    }

    final unidad = esVida ? 'PV' : 'PM';
    ultimoMensaje = '${jugador.nombre} usó ${pocion.nombre}: +$recuperado $unidad.';
    notifyListeners();
    return true;
  }

  void elegirClase(ClasePersonaje clase) {
    claseActual = clase;
    jugador = Combatiente(
      nombre: clase.nombre,
      emoji: clase.emoji,
      arma: clase.arma,
      sprite: idSpriteDeClase(clase.nombre),
      estadisticas: clase.estadisticas,
      habilidades: List.of(clase.habilidades),
    );
    ronda = 1;
    rondasSuperadas = 0;
    monstruo = _generarMonstruo();
    pantalla = Pantalla.combate;
    ultimoMensaje = '¡Un ${monstruo.nombre} aparece!';
    estadoPartida = EstadoPartida.enCurso;
    idPartida++;
    combatesDesdeUltimoAnuncio = 0;
    experiencia = 0;
    entrenamientosRealizados = 0;
    oro = 0;
    inventario.clear();
    habilidadesAprendidas.clear();
    notifyListeners();
  }

  void volverASeleccion() {
    claseActual = null;
    pantalla = Pantalla.seleccion;
    estadoPartida = EstadoPartida.detenida;
    notifyListeners();
  }

  // Solo queda detenida tras una derrota: iniciar vuelve a jugar con la misma clase
  void iniciar() {
    if (pantalla == Pantalla.derrota) {
      reiniciarPartida();
      return;
    }
    estadoPartida = EstadoPartida.enCurso;
    notifyListeners();
  }

  void alternarPausa() {
    if (estadoPartida == EstadoPartida.detenida) return;
    estadoPartida = enCurso ? EstadoPartida.pausada : EstadoPartida.enCurso;
    notifyListeners();
  }

  void reiniciarPartida() {
    final clase = claseActual;
    if (clase == null) return;
    elegirClase(clase);
  }

  void comprar(ProductoTienda producto) {
    diamantes += producto.diamantes;
    if (producto.esPro) tipoCuenta = TipoCuenta.pro;
    notifyListeners();
  }

    Combatiente _generarMonstruo() {
    final (nombre, emoji, arma) = _bestiario[(ronda - 1) % _bestiario.length];
    return Combatiente(
      nombre: '$nombre nv. $ronda',
      emoji: emoji,
      arma: arma,
      estadisticas: Estadisticas(
        vitalidad: 2 + 2 * ronda,
        ataque: 6 + 2 * ronda,
        inteligencia: 0,
        destreza: 2 + ronda,
        agilidad: 4 + ronda,
      ),
      experienciaQueOtorga: 10 + 5 * ronda,
      oroQueOtorga: 8 + 4 * ronda,
    );
  }

    bool get jugadorActuaPrimero =>
      jugador.estadisticas.agilidad >= monstruo.estadisticas.agilidad;

  int _variar(int base) => base + _azar.nextInt(5) - 2;

    // Devuelve si algún golpe impactó y el daño total causado
  ({bool impacto, int danio}) _resolverGolpe(
    Combatiente atacante,
    Combatiente objetivo, {
    double multiplicador = 1.0,
    bool criticoGarantizado = false,
    int golpes = 1,
  }) {
    final partes = <String>[];
    var danioTotal = 0;
    var huboCritico = false;

    for (var i = 0; i < golpes; i++) {
      if (_azar.nextDouble() < objetivo.estadisticas.probabilidadEsquivar) {
        partes.add('esquivado');
        continue;
      }

      final esCritico = criticoGarantizado ||
          _azar.nextDouble() < atacante.estadisticas.probabilidadCritico;
      var danio = _variar(atacante.ataqueEfectivo) * multiplicador;
      if (esCritico) danio *= 1.5;
      final escudo = objetivo.efecto(TipoEfecto.escudo);
      if (escudo != null) danio *= 1 - escudo.valor;

      final danioGolpe = max(1, danio.round());
      objetivo.recibirDanio(danioGolpe);
      danioTotal += danioGolpe;
      huboCritico = huboCritico || esCritico;
      partes.add(esCritico ? '$danioGolpe✨' : '$danioGolpe');
    }

    if (golpes > 1) {
      final detalle = partes.join(' + ');
      _publicarMensaje('${atacante.nombre} atacó $golpes veces: $detalle.');
    } else if (danioTotal == 0) {
      _publicarMensaje('${objetivo.nombre} esquivó el ataque.');
    } else {
      final sufijo = huboCritico ? ' (¡crítico!)' : '';
      _publicarMensaje('${atacante.nombre} hizo $danioTotal de daño$sufijo.');
    }
    notifyListeners();
    return (impacto: danioTotal > 0, danio: danioTotal);
  }

  bool golpearAlMonstruo() => _resolverGolpe(jugador, monstruo).impacto;

  bool golpearAlJugador() => _resolverGolpe(monstruo, jugador).impacto;

  bool usarHabilidad(Habilidad habilidad) {
    jugador.mana -= habilidad.costoMana;

    var impacto = false;
    var danio = 0;
    if (habilidad.haceDanio) {
      final resultado = _resolverGolpe(
        jugador,
        monstruo,
        multiplicador: habilidad.multiplicadorDanio,
        criticoGarantizado: habilidad.criticoGarantizado,
        golpes: habilidad.golpes,
      );
      impacto = resultado.impacto;
      danio = resultado.danio;
    }

    final extras = <String>[];

    if (habilidad.robaVida > 0 && danio > 0) {
      final cura = max(1, (danio * habilidad.robaVida).round());
      jugador.curar(cura);
      extras.add('+$cura PV');
    }
    if (habilidad.curaPorcentaje > 0) {
      final cura = (jugador.vidaMaxima * habilidad.curaPorcentaje).round();
      jugador.curar(cura);
      extras.add('+$cura PV');
    }
    if (habilidad.robaMana > 0 && danio > 0) {
      jugador.recuperarMana(habilidad.robaMana);
      extras.add('+${habilidad.robaMana} PM');
    }

    final efecto = habilidad.efecto;
    // Un efecto sobre el rival solo se aplica si el golpe no fue esquivado
    if (efecto != null && (efecto.sobreSiMismo || impacto)) {
      final destino = efecto.sobreSiMismo ? jugador : monstruo;
      // Los efectos sobre uno mismo pierden un turno al cerrar este mismo turno,
      // por eso se compensa con +1
      final turnos = efecto.turnos + (efecto.sobreSiMismo ? 1 : 0);
      final valor = efecto.tipo == TipoEfecto.veneno
          ? max(1, (jugador.ataqueEfectivo * efecto.valor).round()).toDouble()
          : efecto.valor;
      destino.aplicarEfecto(
        EfectoActivo(tipo: efecto.tipo, turnosRestantes: turnos, valor: valor),
      );
      extras.add('${efecto.tipo.emoji} ${efecto.tipo.nombre}');
    }

    final partes = <String>['${jugador.nombre} usó ${habilidad.nombre}.'];
    if (habilidad.haceDanio) partes.add(ultimoMensaje);
    if (extras.isNotEmpty) {
      final detalleExtras = extras.join(', ');
      partes.add('$detalleExtras.');
    }
    ultimoMensaje = partes.join(' ');
    notifyListeners();
    return impacto;
  }

    // Se llama antes de que actúe `actor`. Devuelve false si pierde el turno (muerto o aturdido)
  bool iniciarTurno(Combatiente actor) {
    final veneno = actor.efecto(TipoEfecto.veneno);
    if (veneno != null) {
      final danioVeneno = veneno.valor.round();
      actor.recibirDanio(danioVeneno);
      _avisoPrevio = '${actor.nombre} sufre $danioVeneno de daño por veneno.';
      ultimoMensaje = _avisoPrevio;
      notifyListeners();
    }
    if (!actor.estaVivo) return false;

    if (actor.tiene(TipoEfecto.aturdimiento)) {
      _publicarMensaje('${actor.nombre} está aturdido y pierde el turno.');
      notifyListeners();
      return false;
    }
    return true;
  }

  // Se llama al terminar el turno de `actor`: descuenta un turno a sus efectos
  void terminarTurno(Combatiente actor) {
    for (final efecto in actor.efectos) {
      efecto.turnosRestantes--;
    }
    actor.efectos.removeWhere((efecto) => efecto.turnosRestantes <= 0);
    _avisoPrevio = '';
    notifyListeners();
  }

  void irATaberna() {
    final experienciaGanada = monstruo.experienciaQueOtorga;
    final oroGanado = monstruo.oroQueOtorga;
    experiencia += experienciaGanada;
    oro += oroGanado;
    rondasSuperadas++;
    pantalla = Pantalla.taberna;
    ultimoMensaje = '¡Ronda superada! +$experienciaGanada XP, +$oroGanado de oro.';
    combatesDesdeUltimoAnuncio++;
    jugador.efectos.clear();
    notifyListeners();
  }

  void irADerrota() {
    pantalla = Pantalla.derrota;
    estadoPartida = EstadoPartida.detenida;
    notifyListeners();
  }

    void descansar() {
    jugador.curar(40);
    jugador.recuperarMana(15);
    ultimoMensaje = 'Descansaste y recuperaste fuerzas.';
    notifyListeners();
  }

  void siguienteCombate() {
    ronda++;
    monstruo = _generarMonstruo();
    pantalla = Pantalla.combate;
    ultimoMensaje = '¡Un ${monstruo.nombre} aparece!';
    notifyListeners();
  }
}

void mostrarProximamente(BuildContext context, String nombre) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$nombre: próximamente'),
      duration: const Duration(seconds: 1),
    ),
  );
}

class AplicacionRpg extends StatelessWidget {
  const AplicacionRpg({super.key});

  @override
  Widget build(BuildContext context) {
    // Al cambiar modoTema solo se reconstruye el MaterialApp: el `home` const
    // conserva su State, así que la partida no se pierde al cambiar de tema.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: modoTema,
      builder: (context, modo, _) => MaterialApp(
        title: 'RPG por turnos',
        debugShowCheckedModeBanner: false,
        themeMode: modo,
        theme: temaClaro,
        darkTheme: temaOscuro,
        home: const PantallaJuego(),
      ),
    );
  }
}

class PantallaJuego extends StatefulWidget {
  const PantallaJuego({super.key});

  @override
  State<PantallaJuego> createState() => _EstadoPantallaJuego();
}

class _EstadoPantallaJuego extends State<PantallaJuego> {
  final juego = JuegoRpg();

  @override
  void dispose() {
    juego.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: juego,
      builder: (context, _) {
        final hayBotonera = juego.pantalla != Pantalla.seleccion;
        final mostrarCapa = juego.estadoPartida == EstadoPartida.pausada;
        final hayBannerLateral =
            esPantallaAncha(context) && juego.mostrarPublicidad;

        final columnaJuego = Column(
          children: [
            EncabezadoJuego(juego: juego),
            Expanded(
              child: SafeArea(
                top: false,
                bottom: !hayBotonera,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: switch (juego.pantalla) {
                          Pantalla.seleccion => VistaSeleccion(
                              key: const ValueKey('seleccion'),
                              juego: juego,
                            ),
                          // La key incluye idPartida: al reiniciar se destruye
                          // el State anterior y se corta cualquier turno en vuelo.
                          Pantalla.combate => VistaCombate(
                              key: ValueKey('combate-${juego.idPartida}'),
                              juego: juego,
                            ),
                          Pantalla.taberna => VistaTaberna(
                              key: const ValueKey('taberna'),
                              juego: juego,
                            ),
                          Pantalla.derrota => VistaDerrota(
                              key: const ValueKey('derrota'),
                              juego: juego,
                            ),
                        },
                      ),
                    ),
                    if (mostrarCapa)
                      const Positioned.fill(child: CapaPausa()),
                  ],
                ),
              ),
            ),
            if (hayBotonera) BotoneraJuego(juego: juego),
          ],
        );

        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: columnaJuego),
              if (hayBannerLateral) const BannerPublicidad(),
            ],
          ),
        );
      },
    );
  }
}

class EncabezadoJuego extends StatelessWidget {
  const EncabezadoJuego({super.key, required this.juego});

  final JuegoRpg juego;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final esPro = juego.tipoCuenta == TipoCuenta.pro;

    return Material(
      color: colores.surfaceContainer,
      // bottom: false para que el fondo del header cubra la barra de estado
      // pero sin reservar espacio abajo
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: MediaQuery.sizeOf(context).height < 500 ? 4 : 10,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colores.primaryContainer,
                child: Text(
                  juego.claseActual?.emoji ?? '👤',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      juego.nombreUsuario,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: esPro ? Colors.amber : colores.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            esPro ? 'PRO' : 'BASIC',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: esPro ? Colors.black87 : colores.onSecondaryContainer,
                            ),
                          ),
                        ),
                        if (juego.pantalla != Pantalla.seleccion)
                          Text(
                            'Ronda ${juego.ronda}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Score: ${juego.rondasSuperadas}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('💎 ${juego.diamantes}'),
                ],
              ),
              const BotonTema(),
              IconButton(
                tooltip: 'Tienda',
                icon: const Icon(Icons.storefront),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PantallaTienda(juego: juego),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VistaSeleccion extends StatelessWidget {
  const VistaSeleccion({super.key, required this.juego});

  final JuegoRpg juego;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Elige tu clase',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            for (final clase in ClasePersonaje.todas)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Text(clase.emoji, style: const TextStyle(fontSize: 40)),
                  title: Text(clase.nombre),
                  subtitle: Text(
                    '${clase.descripcion}\n${clase.estadisticas.resumen}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => juego.elegirClase(clase),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BotoneraJuego extends StatelessWidget {
  const BotoneraJuego({super.key, required this.juego});

  final JuegoRpg juego;

  @override
  Widget build(BuildContext context) {
    final enJuego =
        juego.pantalla == Pantalla.combate || juego.pantalla == Pantalla.taberna;
    final detenida = juego.estadoPartida == EstadoPartida.detenida;
    final pausada = juego.estadoPartida == EstadoPartida.pausada;
    final compacta = MediaQuery.sizeOf(context).height < 500;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: compacta ? 2 : 6),
          child: Row(
            children: [
              _BotonControl(
                icono: Icons.play_arrow,
                texto: 'Inicio',
                alTocar: detenida ? juego.iniciar : null,
                compacto: compacta,
              ),
              _BotonControl(
                icono: pausada ? Icons.play_circle : Icons.pause,
                texto: pausada ? 'Reanudar' : 'Pausa',
                alTocar: enJuego && !detenida ? juego.alternarPausa : null,
                compacto: compacta,
              ),
              _BotonControl(
                icono: Icons.restart_alt,
                texto: 'Reiniciar',
                alTocar: juego.reiniciarPartida,
                compacto: compacta,
              ),
              _BotonControl(
                icono: Icons.add_circle_outline,
                texto: 'Nueva',
                alTocar: juego.volverASeleccion,
                compacto: compacta,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonControl extends StatelessWidget {
  const _BotonControl({
    required this.icono,
    required this.texto,
    required this.alTocar,
    required this.compacto,
  });

  final IconData icono;
  final String texto;
  final VoidCallback? alTocar;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            onPressed: alTocar,
            tooltip: texto,
            icon: Icon(icono),
          ),
          if (!compacto)
            Text(texto, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class CapaPausa extends StatelessWidget {
  const CapaPausa({super.key});

  @override
  Widget build(BuildContext context) {
    // ColoredBox es opaco al hit-testing: bloquea los toques sobre el juego
    return const ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⏸️', style: TextStyle(fontSize: 64)),
            SizedBox(height: 8),
            Text(
              'Juego en pausa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraRecurso extends StatelessWidget {
  const _BarraRecurso({
    required this.etiqueta,
    required this.valor,
    required this.maximo,
    required this.color,
  });

  final String etiqueta;
  final int valor;
  final int maximo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelMedium;

    return Row(
      children: [
        SizedBox(width: 28, child: Text(etiqueta, style: estilo)),
        Expanded(
          child: LinearProgressIndicator(
            value: maximo == 0 ? 0 : valor / maximo,
            minHeight: 10,
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 8),
        Text('$valor/$maximo', style: estilo),
      ],
    );
  }
}

class InfoCombatiente extends StatelessWidget {
  const InfoCombatiente({
    super.key,
    required this.combatiente,
    this.mostrarMana = false,
  });

  final Combatiente combatiente;
  final bool mostrarMana;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              combatiente.nombre,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            _BarraRecurso(
              etiqueta: 'PV',
              valor: combatiente.vida,
              maximo: combatiente.vidaMaxima,
              color: Colors.red.shade400,
            ),
            if (mostrarMana && combatiente.manaMaximo > 0) ...[
              const SizedBox(height: 6),
              _BarraRecurso(
                etiqueta: 'PM',
                valor: combatiente.mana,
                maximo: combatiente.manaMaximo,
                color: Colors.blue.shade400,
              ),
            ],
            if (combatiente.efectos.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                children: [
                  for (final efecto in combatiente.efectos)
                    Text('${efecto.tipo.emoji} ${efecto.turnosRestantes}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GrillaBotones extends StatelessWidget {
  const GrillaBotones({super.key, required this.botones, required this.columnas});

  final List<Widget> botones;
  final int columnas;

  @override
  Widget build(BuildContext context) {
    final filas = <Widget>[];
    for (var i = 0; i < botones.length; i += columnas) {
      final fila = botones.sublist(i, min(i + columnas, botones.length));
      if (i > 0) filas.add(const SizedBox(height: 8));
      filas.add(
        Row(
          children: [
            for (var j = 0; j < fila.length; j++) ...[
              if (j > 0) const SizedBox(width: 8),
              Expanded(child: SizedBox(height: 48, child: fila[j])),
            ],
          ],
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: filas);
  }
}

Future<void> mostrarEntrenamiento(BuildContext context, JuegoRpg juego) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (_) => PanelEntrenamiento(juego: juego),
  );
}

class PanelEntrenamiento extends StatefulWidget {
  const PanelEntrenamiento({super.key, required this.juego});

  final JuegoRpg juego;

  @override
  State<PanelEntrenamiento> createState() => _EstadoPanelEntrenamiento();
}

class _EstadoPanelEntrenamiento extends State<PanelEntrenamiento> {
  int _pestana = 0;

  @override
  Widget build(BuildContext context) {
    final juego = widget.juego;
    final estilos = Theme.of(context).textTheme;

    // ListenableBuilder: la hoja se redibuja sola tras cada compra
    return ListenableBuilder(
      listenable: juego,
      builder: (context, _) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              Text('Entrenamiento', style: estilos.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '✨ XP: ${juego.experiencia}     💎 ${juego.diamantes}',
                style: estilos.titleMedium,
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Estadísticas')),
                  ButtonSegment(value: 1, label: Text('Habilidades')),
                ],
                selected: {_pestana},
                onSelectionChanged: (seleccion) =>
                    setState(() => _pestana = seleccion.first),
              ),
              const SizedBox(height: 12),
              if (_pestana == 0)
                ...[
                  for (final tipo in TipoEstadistica.values)
                    _FilaEntrenamiento(juego: juego, tipo: tipo),
                ]
              else
                ListaArbolHabilidades(juego: juego),
            ],
          ),
        );
      },
    );
  }
}

class _FilaEntrenamiento extends StatelessWidget {
  const _FilaEntrenamiento({required this.juego, required this.tipo});

  final JuegoRpg juego;
  final TipoEstadistica tipo;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final valor = juego.jugador.estadisticas.valorDe(tipo);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tipo.emoji} ${tipo.nombre}: $valor → ${valor + 1}',
              style: estilos.titleMedium,
            ),
            Text(tipo.efecto, style: estilos.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: juego.alcanzaXp
                        ? () => juego.entrenar(tipo, conDiamantes: false)
                        : null,
                    child: Text('✨ ${juego.costoEntrenamientoXp} XP'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: juego.alcanzanDiamantes
                        ? () => juego.entrenar(tipo, conDiamantes: true)
                        : null,
                    child: Text('💎 ${juego.costoEntrenamientoDiamantes}'),
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

// Si el combatiente tiene `sprite` se dibuja con las imágenes de assets/sprites;
// si no (los monstruos, por ahora) sigue usando el emoji provisorio.
class SpriteCombatiente extends StatelessWidget {
  const SpriteCombatiente({
    super.key,
    required this.combatiente,
    required this.anguloArma,
    required this.mirarIzquierda,
    required this.tamano,
    this.animacion = AnimSprite.standby,
    this.progreso = 0,
  });

  final Combatiente combatiente;
  final double anguloArma;
  final bool mirarIzquierda;
  final double tamano;
  final AnimSprite animacion;
  final double progreso;

  @override
  Widget build(BuildContext context) {
    final angulo = mirarIzquierda ? -anguloArma : anguloArma;
    final sprite = combatiente.sprite;

    Widget contenido;
    if (sprite != null) {
      contenido = OverflowBox(
        maxWidth: tamano * 2,
        child: Transform.flip(
          flipX: mirarIzquierda,
          child: SpriteHoja(
            sprite: sprite,
            animacion: animacion,
            progreso: progreso,
            alto: tamano,
          ),
        ),
      );
    } else {
      contenido = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Text(combatiente.emoji, style: TextStyle(fontSize: tamano * 0.73)),
          Positioned(
            right: mirarIzquierda ? null : -tamano * 0.15,
            left: mirarIzquierda ? -tamano * 0.15 : null,
            bottom: tamano * 0.07,
            child: Transform.rotate(
              angle: angulo,
              alignment: Alignment.bottomCenter,
              child: Text(combatiente.arma, style: TextStyle(fontSize: tamano * 0.4)),
            ),
          ),
        ],
      );
    }

    return AnimatedOpacity(
      opacity: combatiente.estaVivo ? 1 : 0,
      duration: const Duration(milliseconds: 500),
      child: SizedBox(width: tamano, height: tamano, child: contenido),
    );
  }
}

class VistaCombate extends StatefulWidget {
  const VistaCombate({super.key, required this.juego});

  final JuegoRpg juego;

  @override
  State<VistaCombate> createState() => _EstadoVistaCombate();
}

class _EstadoVistaCombate extends State<VistaCombate>
    with TickerProviderStateMixin {
  late final AnimationController _controlAtaque = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _controlSacudida = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  // Bucle de la animación standby
  late final AnimationController _controlReposo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
    // Vuelo de la flecha: 0 sale del arco, 1 llega al monstruo
  late final AnimationController _controlProyectil = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  // Estallido del hechizo sobre el monstruo
  late final AnimationController _controlEfecto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  // Un solo controlador (0 a 1) maneja toda la coreografía del ataque:
  // 0-0.3 avanza, 0.3-0.5 baja el arma (impacto en 0.5), 0.5-0.7 la sube, 0.7-1 retrocede.
  late final Animation<double> _avance = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
      weight: 30,
    ),
  ]).animate(_controlAtaque);

  late final Animation<double> _giroArma = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
  ]).animate(_controlAtaque);

  bool _atacaJugador = true;
  bool _ocupado = false;
  bool _golpeando = false;
  TipoAtaque _tipoAtaque = TipoAtaque.cuerpoACuerpo;
  bool _proyectilVisible = false;
  bool _efectoVisible = false;

  @override
  void initState() {
    super.initState();
    _controlReposo.repeat();
    AudioManager.playBgm('audio/Lugia_Song.mp3');
  }

  @override
  void dispose() {
    _controlAtaque.dispose();
    _controlSacudida.dispose();
    _controlReposo.dispose();
    super.dispose();
    _controlProyectil.dispose();
    _controlEfecto.dispose();
  }

  // Qué animación y qué progreso le toca a cada lado en este instante.
  (AnimSprite, double) _animacionDe({required bool esJugador}) {
    final esAtacante = _golpeando && (_atacaJugador == esJugador);
    if (esAtacante) return (AnimSprite.ataque, _controlAtaque.value);
    final esObjetivo = _atacaJugador != esJugador;
    if (esObjetivo && _controlSacudida.isAnimating) {
      return (AnimSprite.dano, _controlSacudida.value);
    }
    return (AnimSprite.standby, _controlReposo.value);
  }

  Future<void> _animarGolpe({
    required bool esJugador,
    required bool Function() alImpactar,
  }) async {
    // Solo el jugador puede atacar a distancia: los monstruos siempre embisten
    final tipo = esJugador
        ? tipoAtaqueDeSprite(widget.juego.jugador.sprite)
        : TipoAtaque.cuerpoACuerpo;

    setState(() {
      _atacaJugador = esJugador;
      _golpeando = true;
      _tipoAtaque = tipo;
    });
    _controlAtaque.value = 0;

    switch (tipo) {
      case TipoAtaque.cuerpoACuerpo:
        {
          // animateTo(0.5) recorre solo la primera mitad: ahí está el impacto,
          // se aplica el daño y recién después se completa la animación.
          await _controlAtaque.animateTo(0.5);
          final acerto = alImpactar();
          if (acerto) _controlSacudida.forward(from: 0);
          await _controlAtaque.animateTo(1.0);
        }
      case TipoAtaque.magia:
        {
          await _controlAtaque.animateTo(0.4); // el bastón empieza a brillar
          // La animación del mago sigue corriendo mientras estalla el hechizo
          final fin = _controlAtaque.animateTo(1.0);
          setState(() => _efectoVisible = true);
          _controlEfecto.value = 0;
          await _controlEfecto.animateTo(0.2); // el estallido ya se ve sobre el monstruo
          final acerto = alImpactar();
          if (acerto) _controlSacudida.forward(from: 0);
          await Future.wait([fin, _controlEfecto.animateTo(1.0)]);
          if (mounted) setState(() => _efectoVisible = false);
        }
      case TipoAtaque.proyectil:
        {
          await _controlAtaque.animateTo(0.5); // el arquero tensa el arco
          final fin = _controlAtaque.animateTo(1.0);
          setState(() => _proyectilVisible = true);
          await _controlProyectil.forward(from: 0); // la flecha viaja hasta el monstruo
          if (mounted) setState(() => _proyectilVisible = false);
          final acerto = alImpactar();
          if (acerto) _controlSacudida.forward(from: 0);
          await fin;
        }
    }

    if (mounted) setState(() => _golpeando = false);
  }

  // Sondeo simple: si la vista se destruye durante la pausa, el bucle termina
  // solo (mounted) y no queda ningún listener colgado.
  Future<void> _esperarReanudacion() async {
    while (mounted && widget.juego.estadoPartida == EstadoPartida.pausada) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _ejecutarRonda(
    bool Function() accionJugador, {
    bool sinAtaque = false,
  }) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    final juego = widget.juego;

    // La agilidad decide quién actúa primero en cada ronda
    final ordenTurnos = juego.jugadorActuaPrimero ? [true, false] : [false, true];

    for (final turnoDelJugador in ordenTurnos) {
      final actor = turnoDelJugador ? juego.jugador : juego.monstruo;
      final puedeActuar = juego.iniciarTurno(actor);

      if (!puedeActuar) {
        await Future.delayed(const Duration(milliseconds: 800));
      } else if (turnoDelJugador && sinAtaque) {
        // Objetos y habilidades sin daño: consumen el turno, sin embestida
        accionJugador();
        await Future.delayed(const Duration(milliseconds: 700));
      } else {
        await _animarGolpe(
          esJugador: turnoDelJugador,
          alImpactar: turnoDelJugador ? accionJugador : juego.golpearAlJugador,
        );
      }

      juego.terminarTurno(actor);
      await _esperarReanudacion();
      if (!mounted) return;

      if (!juego.monstruo.estaVivo) {
        await Future.delayed(const Duration(milliseconds: 800));
        await _esperarReanudacion();
        if (mounted) juego.irATaberna();
        return;
      }
      if (!juego.jugador.estaVivo) {
        await Future.delayed(const Duration(milliseconds: 800));
        await _esperarReanudacion();
        if (mounted) juego.irADerrota();
        return;
      }
    }

    setState(() => _ocupado = false);
  }

  Future<void> _elegirHabilidad() async {
    final juego = widget.juego;
    final elegida = await showModalBottomSheet<Habilidad>(
      context: context,
      builder: (contextoHoja) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final habilidad in juego.jugador.habilidades)
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: Text(habilidad.nombre),
                subtitle: Text('${habilidad.descripcion}  ·  🔷 ${habilidad.costoMana}'),
                enabled: juego.jugador.puedeUsar(habilidad),
                onTap: () => Navigator.of(contextoHoja).pop(habilidad),
              ),
          ],
        ),
      ),
    );
    if (elegida != null && mounted) {
        await _ejecutarRonda(() => juego.usarHabilidad(elegida), sinAtaque: !elegida.haceDanio,
      );
    }
  }

  Future<void> _elegirObjeto() async {
    final juego = widget.juego;
    final elegida = await showModalBottomSheet<Pocion>(
      context: context,
      builder: (contextoHoja) {
      final disponibles =Pocion.todas.where((pocion) => juego.cantidadDe(pocion) > 0).toList();

        return SafeArea(
          child: disponibles.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No tienes objetos. Puedes comprar pociones en la tienda de la taberna.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final pocion in disponibles)
                      ListTile(
                        leading: Icon(
                          Icons.science,
                          color: pocion.color,
                          size: pocion.tamanoIcono,
                        ),
                        title: Text('${pocion.nombre}  x${juego.cantidadDe(pocion)}'),
                        subtitle: Text('${pocion.efecto} · Usarla cuenta como un turno'),
                        enabled: juego.puedeUsarPocion(pocion),
                        onTap: () => Navigator.of(contextoHoja).pop(pocion),
                      ),
                  ],
                ),
        );
      },
    );
    if (elegida != null && mounted) {
      await _ejecutarRonda(() => juego.usarPocion(elegida), sinAtaque: true);
    }
  }

  Future<void> _confirmarRendicion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('¿Rendirse?'),
        content: const Text('La partida terminará con tu score actual.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Rendirme'),
          ),
        ],
      ),
    );
    if (confirmado == true && mounted) widget.juego.irADerrota();
  }

  double get _desplazamientoSacudida {
    final t = _controlSacudida.value;
    return sin(t * pi * 6) * 10 * (1 - t);
  }

  @override
  Widget build(BuildContext context) {
    final juego = widget.juego;
    final colores = Theme.of(context).colorScheme;
    final puedeActuar = !_ocupado && juego.enCurso;
    final fondo = fondoCombateSegunBrillo(colores.brightness);

    return LayoutBuilder(
      builder: (context, area) {
        // Teléfono acostado: poca altura, el panel de acciones pasa a un costado
        final lateral = area.maxHeight < 420 && area.maxWidth > area.maxHeight;

        return Flex(
          direction: lateral ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, restricciones) {
              final ancho = restricciones.maxWidth;
              final alto = restricciones.maxHeight;
              final tamanoJugador =
                  (min(ancho, alto) * 0.32).clamp(64.0, 260.0).toDouble();
              final tamanoMonstruo = tamanoJugador * 1.3;
              final margenIzquierdo = ancho * 0.11;
              final margenDerecho = ancho * 0.10;
              final espacioLibre = ancho -
                  margenIzquierdo -
                  margenDerecho -
                  tamanoJugador -
                  tamanoMonstruo;
              final baseSprites = alto * 0.14;

              return AnimatedBuilder(
                animation: Listenable.merge([  _controlAtaque,  _controlSacudida,  _controlReposo,  _controlProyectil,  _controlEfecto,]),
                builder: (context, _) {
                  final tamanoAtacante =
                      _atacaJugador ? tamanoJugador : tamanoMonstruo;
                  final distancia = max(0.0, espacioLibre - tamanoAtacante * 0.2);
                  final avance = _tipoAtaque == TipoAtaque.cuerpoACuerpo ? _avance.value * distancia : 0.0;

                  // Puntos de referencia para el hechizo y la flecha
                  final xMonstruo = ancho - margenDerecho - tamanoMonstruo / 2;
                  final yMonstruo = baseSprites + tamanoMonstruo * 0.45;

                  final tamanoEfecto = tamanoMonstruo * 1.3;
                  final te = _controlEfecto.value;
                  final escalaEfecto = 0.5 + 0.6 * Curves.easeOut.transform(te);
                  final opacidadEfecto =
                      (te < 0.7 ? 1.0 : 1 - (te - 0.7) / 0.3).clamp(0.0, 1.0).toDouble();

                  // La flecha sale de la punta del arco (en coordenadas del frame 170x156)
                  final escalaTira = tamanoJugador / altoFrameSprite;
                  final anchoFlecha = anchoFrameFlecha * escalaTira;
                  final altoFlecha = altoFrameFlecha * escalaTira;
                  final anchoFrameJugador = tamanoJugador * anchoFrameSprite / altoFrameSprite;
                  final xOrigen = margenIzquierdo +
                      tamanoJugador / 2 +
                      (130 / anchoFrameSprite - 0.5) * anchoFrameJugador;
                  final yOrigen = baseSprites + (1 - 62 / altoFrameSprite) * tamanoJugador;
                  final tv = _controlProyectil.value;
                  final xFlecha = xOrigen + (xMonstruo - xOrigen) * tv;
                  final yFlecha = yOrigen + (yMonstruo - yOrigen) * tv;
                  final anguloFlecha = -atan2(yMonstruo - yOrigen, xMonstruo - xOrigen);
                  final giro = -0.6 + 1.6 * _giroArma.value;
                  final sacudida = _desplazamientoSacudida;
                  final (animJugador, progJugador) = _animacionDe(esJugador: true);
                  final (animMonstruo, progMonstruo) = _animacionDe(esJugador: false);

                  final desplazamientoJugador = _atacaJugador ? avance : sacudida;
                  final desplazamientoMonstruo = _atacaJugador ? sacudida : -avance;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Image.asset(
                            fondo,
                            // La key distinta por fondo hace que AnimatedSwitcher anime el cambio
                            key: ValueKey(fondo),
                            // Con restricciones sueltas la imagen no llenaría el área
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            alignment: Alignment.bottomCenter, // el suelo siempre queda visible
                            filterQuality: FilterQuality.none, // mantiene el pixel art nítido
                            errorBuilder: (_, __, ___) =>
                                ColoredBox(color: colores.primaryContainer),
                          ),
                        ),
                      ),
                      Positioned(
                        left: margenIzquierdo + desplazamientoJugador,
                        bottom: baseSprites,
                        child: SpriteCombatiente(
                          combatiente: juego.jugador,
                          anguloArma: _atacaJugador ? giro : -0.6,
                          mirarIzquierda: false,
                          tamano: tamanoJugador,
                          animacion: animJugador,
                          progreso: progJugador,
                        ),
                      ),
                      Positioned(
                        right: margenDerecho - desplazamientoMonstruo,
                        bottom: baseSprites,
                        child: SpriteCombatiente(
                          combatiente: juego.monstruo,
                          anguloArma: !_atacaJugador ? giro : -0.6,
                          mirarIzquierda: true,
                          tamano: tamanoMonstruo,
                          animacion: animMonstruo,
                          progreso: progMonstruo,
                        ),
                      ),
                      if (_efectoVisible)
                        Positioned(
                          left: xMonstruo - tamanoEfecto / 2,
                          bottom: yMonstruo - tamanoEfecto / 2,
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: opacidadEfecto,
                              child: Transform.scale(
                                scale: escalaEfecto,
                                child: Image.asset(
                                  imagenEfectoMagia,
                                  width: tamanoEfecto,
                                  height: tamanoEfecto,
                                  filterQuality: FilterQuality.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_proyectilVisible)
                        Positioned(
                          left: xFlecha - anchoFlecha / 2,
                          bottom: yFlecha - altoFlecha / 2,
                          child: IgnorePointer(
                            child: Transform.rotate(
                              angle: anguloFlecha,
                              child: FrameDeTira(
                                asset: imagenFlechas,
                                frames: 2,
                                // alterna los dos frames para que la estela titile
                                indice: (tv * 8).floor() % 2,
                                ancho: anchoFlecha,
                                alto: altoFlecha,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 0,
                        right: 0,
                        width: ancho >= 600 ? ancho * 0.69 : ancho,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: InfoCombatiente(combatiente: juego.monstruo),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        SizedBox(
          width: lateral ? 340 : null,
          child: Material(
          color: colores.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, restricciones) {
                return SingleChildScrollView(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: InfoCombatiente(
                          combatiente: juego.jugador,
                          mostrarMana: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(juego.ultimoMensaje, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    GrillaBotones(
                      columnas: restricciones.maxWidth >= 600 ? 4 : 2,
                      botones: [
                        FilledButton.icon(
                          onPressed: puedeActuar ? () => _ejecutarRonda(juego.golpearAlMonstruo) : null,
                          icon: const Icon(Icons.flash_on),
                          label: const Text('Ataque básico'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: puedeActuar ? _elegirHabilidad : null,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Habilidad'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: puedeActuar ? _elegirObjeto : null,
                          icon: const Icon(Icons.inventory_2),
                          label: const Text('Objeto'),
                        ),
                        OutlinedButton.icon(
                          onPressed: puedeActuar ? _confirmarRendicion : null,
                          icon: const Icon(Icons.flag),
                          label: const Text('Rendirse'),
                        ),
                      ],
                    ),
                  ],
                ),
                );
              },
            ),
          ),
        ),
        ),
          ],
        );
      },
    );
  }
}

class _BotonTaberna extends StatelessWidget {
  const _BotonTaberna({
    required this.icono,
    required this.texto,
    required this.alTocar,
  });

  final IconData icono;
  final String texto;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton.tonalIcon(
        onPressed: alTocar,
        icon: Icon(icono),
        label: Text(texto, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class VistaTaberna extends StatefulWidget {
  const VistaTaberna({super.key, required this.juego});

  final JuegoRpg juego;

  @override
  State<VistaTaberna> createState() => _EstadoVistaTaberna();
}

class _EstadoVistaTaberna extends State<VistaTaberna>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlBebida = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controlBebida.dispose();
    super.dispose();
  }

  Future<void> _siguienteCombate() async {
    final juego = widget.juego;
    if (juego.tocaAnuncio && !esPantallaAncha(context)) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AnuncioIntersticial(),
      );
      juego.anuncioMostrado();
    }
    if (mounted) juego.siguienteCombate();
  }

  @override
  Widget build(BuildContext context) {
    final juego = widget.juego;
    final puedeActuar = juego.enCurso;

    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        final alto = restricciones.maxHeight;
        final esAncha = ancho >= 600;
        final esBaja = alto < 360;
        final anchoColumna = esAncha ? 240.0 : 160.0;
        final diametroSiguiente = esBaja ? 72.0 : (esAncha ? 130.0 : 88.0);
        final tamanoPersonaje =
            (min(ancho, alto) * 0.45).clamp(80.0, 320.0).toDouble();

        Widget envolver(Widget boton) =>
            esAncha ? SizedBox(width: 240, child: boton) : Expanded(child: boton);

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                fondoTaberna,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF4E342E)),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _controlBebida,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(_controlBebida.value);
                  return SizedBox(
                    width: tamanoPersonaje * 1.8,
                    height: tamanoPersonaje * 1.8,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Transform.translate(
                          offset: Offset(0, -tamanoPersonaje * 0.03 * t),
                          child: juego.jugador.sprite != null
                              ? SpriteHoja(
                                  sprite: juego.jugador.sprite!,
                                  animacion: AnimSprite.standby,
                                  progreso: _controlBebida.value,
                                  alto: tamanoPersonaje,
                                )
                              : Text(
                                  juego.jugador.emoji,
                                  style: TextStyle(fontSize: tamanoPersonaje),
                                ),
                        ),
                        Positioned(
                          right: tamanoPersonaje * 0.25,
                          bottom: tamanoPersonaje * 0.25,
                          child: Transform.translate(
                            offset: Offset(
                              -tamanoPersonaje * 0.28 * t,
                              -tamanoPersonaje * 0.42 * t,
                            ),
                            child: Transform.rotate(
                              angle: -0.7 * t,
                              child: Text(
                                '🍺',
                                style: TextStyle(fontSize: tamanoPersonaje * 0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              width: anchoColumna,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BotonTaberna(
                    icono: Icons.storefront,
                    texto: 'Tienda',
                    alTocar: puedeActuar
                        ? () => mostrarTiendaPociones(context, juego)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _BotonTaberna(
                    icono: Icons.fitness_center,
                    texto: 'Entrenamiento',
                    alTocar: puedeActuar ? () => mostrarEntrenamiento(context, juego) : null,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              width: min(320.0, ancho - anchoColumna - 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InfoCombatiente(
                    combatiente: juego.jugador,
                    mostrarMana: true,
                  ),
                  if (!esBaja) ...[
                    const SizedBox(height: 6),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text('✨ XP: ${juego.experiencia}     🪙 Oro: ${juego.oro}'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  envolver(
                    _BotonTaberna(
                      icono: Icons.bed,
                      texto: 'Descansar',
                      alTocar: puedeActuar ? juego.descansar : null,
                    ),
                  ),
                  if (esAncha) const Spacer() else const SizedBox(width: 12),
                  SizedBox(
                    width: diametroSiguiente,
                    height: diametroSiguiente,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: puedeActuar ? _siguienteCombate : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.arrow_forward),
                          Text('Siguiente', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class VistaDerrota extends StatelessWidget {
  const VistaDerrota({super.key, required this.juego});

  final JuegoRpg juego;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💀', style: TextStyle(fontSize: 80)),
            Text('Has caído', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text('Rondas superadas: ${juego.rondasSuperadas}'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: juego.volverASeleccion,
              child: const Text('Nueva partida'),
            ),
          ],
        ),
      ),
    );
  }
}