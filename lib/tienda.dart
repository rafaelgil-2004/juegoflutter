import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

class ProductoTienda {
  const ProductoTienda({
    required this.nombre,
    required this.descripcion,
    required this.emoji,
    required this.precio,
    this.diamantes = 0,
    this.esPro = false,
  });

  final String nombre;
  final String descripcion;
  final String emoji;
  final double precio;
  final int diamantes;
  final bool esPro;

  String get precioTexto => 'US\$ ${precio.toStringAsFixed(2)}';

  static const paquetesDiamantes = [
    ProductoTienda(
      nombre: 'Puñado de diamantes',
      descripcion: '50 diamantes',
      emoji: '💎',
      precio: 0.99,
      diamantes: 50,
    ),
    ProductoTienda(
      nombre: 'Bolsa de diamantes',
      descripcion: '120 diamantes',
      emoji: '👝',
      precio: 1.99,
      diamantes: 120,
    ),
    ProductoTienda(
      nombre: 'Cofre de diamantes',
      descripcion: '300 diamantes',
      emoji: '🧰',
      precio: 4.99,
      diamantes: 300,
    ),
    ProductoTienda(
      nombre: 'Tesoro de diamantes',
      descripcion: '700 diamantes',
      emoji: '🏆',
      precio: 9.99,
      diamantes: 700,
    ),
  ];

  static const cuentaPro = ProductoTienda(
    nombre: 'Cuenta PRO',
    descripcion: 'Mejora tu cuenta a PRO',
    emoji: '👑',
    precio: 7.99,
    esPro: true,
  );
}

class PantallaTienda extends StatelessWidget {
  const PantallaTienda({super.key, required this.juego});

  final JuegoRpg juego;

  Future<void> _comprar(BuildContext context, ProductoTienda producto) async {
    final pagoExitoso = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogoPago(producto: producto),
    );
    if (pagoExitoso != true) return;

    juego.comprar(producto);
    // context.mounted: el await anterior pudo dejar el contexto desmontado
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          producto.esPro
              ? '¡Ahora eres PRO! 👑'
              : '¡Recibiste ${producto.diamantes} diamantes! 💎',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: juego,
      builder: (context, _) {
        final esPro = juego.tipoCuenta == TipoCuenta.pro;
        final estilos = Theme.of(context).textTheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tienda'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text('💎 ${juego.diamantes}', style: estilos.titleMedium),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Diamantes', style: estilos.headlineSmall),
              const SizedBox(height: 8),
              for (final producto in ProductoTienda.paquetesDiamantes)
                _TarjetaProducto(
                  producto: producto,
                  alTocar: () => _comprar(context, producto),
                ),
              const SizedBox(height: 16),
              Text('Cuenta', style: estilos.headlineSmall),
              const SizedBox(height: 8),
              _TarjetaProducto(
                producto: ProductoTienda.cuentaPro,
                activo: esPro,
                alTocar: () => _comprar(context, ProductoTienda.cuentaPro),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TarjetaProducto extends StatelessWidget {
  const _TarjetaProducto({
    required this.producto,
    required this.alTocar,
    this.activo = false,
  });

  final ProductoTienda producto;
  final VoidCallback alTocar;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        enabled: !activo,
        leading: Text(producto.emoji, style: const TextStyle(fontSize: 36)),
        title: Text(producto.nombre),
        subtitle: Text(producto.descripcion),
        trailing: activo
            ? const Chip(label: Text('Activa'))
            : Text(
                producto.precioTexto,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        onTap: alTocar,
      ),
    );
  }
}

class DialogoPago extends StatefulWidget {
  const DialogoPago({super.key, required this.producto});

  final ProductoTienda producto;

  @override
  State<DialogoPago> createState() => _EstadoDialogoPago();
}

class _EstadoDialogoPago extends State<DialogoPago> {
  final _controlNumero = TextEditingController();
  bool _procesando = false;

  bool get _numeroValido =>
      _controlNumero.text.replaceAll(' ', '').length == 16;

  @override
  void dispose() {
    _controlNumero.dispose();
    super.dispose();
  }

  Future<void> _pagar() async {
    setState(() => _procesando = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pagar ${widget.producto.precioTexto}'),
      content: _procesando
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.producto.nombre),
                const SizedBox(height: 12),
                TextField(
                  controller: _controlNumero,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de tarjeta',
                    hintText: '0000 0000 0000 0000',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(),
                  ),
                  // El orden importa: primero se filtran dígitos y se limita
                  // el largo, y al final se reinsertan los espacios.
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    FormateadorTarjeta(),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  'Simulación: ingresa cualquier número de 16 dígitos. '
                  'No se realiza ningún cobro.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
      actions: _procesando
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: _numeroValido ? _pagar : null,
                child: const Text('Pagar'),
              ),
            ],
    );
  }
}

class FormateadorTarjeta extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    final digitos = nuevo.text;
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digitos[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}