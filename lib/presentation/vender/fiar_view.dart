import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/presentation/comun/barra_busqueda.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/opcion_radio.dart';
import 'package:gip/presentation/comun/tarjeta_cifra.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/vender/fiar_view_model.dart';
import 'package:provider/provider.dart';

/// Fiar parte de la venta (CUS-07). En el móvil es una pantalla hija de
/// Cobrar con el botón fijo abajo (mockup `mFiar`); en la web, con
/// [enDialogo], un diálogo sobre Cobrar con "Cancelar" (`wFiar`). Termina
/// con el `Fiado` preparado, o con null si el tendero vuelve.
class FiarView extends StatefulWidget {
  const FiarView({super.key, this.enDialogo = false});

  final bool enDialogo;

  @override
  State<FiarView> createState() => _FiarViewState();
}

class _FiarViewState extends State<FiarView> {
  final _busqueda = TextEditingController();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  late final TextEditingController _monto = TextEditingController(
    text: context.read<FiarViewModel>().montoInicial,
  );

  @override
  void dispose() {
    _busqueda.dispose();
    _nombre.dispose();
    _telefono.dispose();
    _monto.dispose();
    super.dispose();
  }

  FiarViewModel get _vm => context.read<FiarViewModel>();

  void _cerrar() => Navigator.of(context).pop();

  void _agregar() {
    FocusScope.of(context).unfocus();
    final fiado = _vm.agregar();
    if (fiado != null) Navigator.of(context).pop(fiado);
  }

  Future<void> _registrarCliente() async {
    final registrado = await _vm.registrarCliente(_nombre.text, _telefono.text);
    if (registrado) {
      _nombre.clear();
      _telefono.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FiarViewModel>();
    return widget.enDialogo ? _dialogo(vm) : _pantalla(vm);
  }

  Widget _pantalla(FiarViewModel vm) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          EncabezadoPantalla(
            titulo: 'Fiar parte de la venta',
            seccion: 'Cobrar',
            onVolver: _cerrar,
          ),
          const SizedBox(height: 16),
          ..._contenido(vm),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_botonAgregar(vm), ..._deuda(vm)],
        ),
      ),
    ),
  );

  Widget _dialogo(FiarViewModel vm) {
    final tema = Theme.of(context);
    return Dialog(
      backgroundColor: tema.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FormaGip.radioTarjeta),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: FormaGip.anchoWeb),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fiar parte de la venta',
                    style: tema.textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  key: const Key('fiar_cerrar'),
                  onPressed: _cerrar,
                  tooltip: 'Cerrar',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._contenido(vm),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _deuda(vm),
                  ),
                ),
                const SizedBox(width: 12),
                BotonSecundario(texto: 'Cancelar', onPressed: _cerrar),
                const SizedBox(width: 12),
                SizedBox(width: 280, child: _botonAgregar(vm)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _contenido(FiarViewModel vm) {
    final tema = Theme.of(context);
    final datos = vm.datos;
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TarjetaCifra(
              etiqueta: 'Total',
              valor: '\$ ${mostrarPrecio(datos.total)}',
              detalle: 'la venta',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TarjetaCifra(
              etiqueta: 'Ya pagó',
              valor: '\$ ${mostrarPrecio(datos.yaPago)}',
              detalle: datos.detallePagado,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TarjetaCifra(
              etiqueta: 'Falta',
              valor: '\$ ${mostrarPrecio(datos.falta)}',
              valorKey: const Key('fiar_falta'),
              detalle: 'por cubrir',
              enRojo: datos.falta > Decimal.zero,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Text('¿A quién le fía?', style: tema.textTheme.labelLarge),
      const SizedBox(height: 8),
      BarraBusqueda(
        pista: 'Buscar cliente por nombre',
        controlador: _busqueda,
        campoKey: const Key('fiar_buscar'),
        onChanged: vm.buscar,
      ),
      const SizedBox(height: 12),
      _ListaClientes(
        vm: vm,
        nombre: _nombre,
        telefono: _telefono,
        onRegistrar: _registrarCliente,
      ),
      const SizedBox(height: 20),
      CampoGip(
        etiqueta: '¿Cuánto queda fiado?',
        controlador: _monto,
        campoKey: const Key('fiar_monto'),
        prefijo: r'$ ',
        alto: 64,
        estiloTexto: tema.textTheme.headlineMedium?.cifrasTabulares,
        tipoTeclado: TextInputType.number,
        ayuda: 'Debe ser mayor que cero. Se guarda cuando confirme la venta.',
        error: vm.errorMonto,
        onChanged: vm.cambiarMonto,
      ),
    ];
  }

  Widget _botonAgregar(FiarViewModel vm) => BotonPrimario(
    key: const Key('fiar_agregar'),
    texto: 'Agregar fiado al pago',
    icono: Icons.check,
    onPressed: vm.puedeAgregar ? _agregar : null,
  );

  /// "María quedará debiendo $ 55.900 en total."
  List<Widget> _deuda(FiarViewModel vm) {
    final deuda = vm.deudaTotal;
    final cliente = vm.cliente;
    if (deuda == null || cliente == null) return const [];
    final nombre = cliente.getNombre().split(' ').first;
    return [
      const SizedBox(height: 6),
      Text(
        '$nombre quedará debiendo \$ ${mostrarPrecio(deuda)} en total.',
        key: const Key('fiar_deuda'),
        textAlign: widget.enDialogo ? TextAlign.start : TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14),
      ),
    ];
  }
}

/// Clientes encontrados, cada uno con su saldo, y "+ Cliente nuevo" con su
/// formulario de nombre y teléfono.
class _ListaClientes extends StatelessWidget {
  const _ListaClientes({
    required this.vm,
    required this.nombre,
    required this.telefono,
    required this.onRegistrar,
  });

  final FiarViewModel vm;
  final TextEditingController nombre;
  final TextEditingController telefono;
  final VoidCallback onRegistrar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final separador = Divider(
      height: 1,
      thickness: 1,
      color: tema.extension<ColoresExtraGip>()!.separador,
    );
    final elegido = vm.cliente;
    final avisos = [
      if (vm.errorBusqueda != null)
        _aviso(tema, vm.errorBusqueda!, const Key('fiar_error_busqueda')),
      if (vm.sinResultados)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No hay clientes con ese nombre',
            style: tema.textTheme.bodyMedium,
          ),
        ),
    ];
    return TarjetaGip(
      radio: FormaGip.radioTarjetaMovil,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...avisos.expand((a) => [a, separador]),
          for (final cliente in vm.clientes) ...[
            OpcionRadio(
              key: Key('fiar_cliente_${cliente.getId()}'),
              titulo: cliente.getNombre(),
              subtitulo: _subtitulo(cliente),
              valor: _saldo(cliente),
              valorEnRojo: cliente.calcularSaldoPendiente() > Decimal.zero,
              elegida: elegido?.getId() == cliente.getId(),
              onTap: () => vm.elegir(cliente),
            ),
            separador,
          ],
          if (vm.creandoCliente)
            _formularioNuevo(context)
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('fiar_cliente_nuevo'),
                  onPressed: () => vm.mostrarClienteNuevo(true),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    textStyle: tema.textTheme.titleSmall,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Cliente nuevo (nombre y teléfono)'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _formularioNuevo(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoGip(
          etiqueta: 'Nombre del cliente',
          controlador: nombre,
          campoKey: const Key('fiar_nuevo_nombre'),
          icono: Icons.person_outline,
          mayusculas: TextCapitalization.words,
          error: vm.errorNombre,
        ),
        const SizedBox(height: 12),
        CampoGip(
          etiqueta: 'Teléfono (opcional)',
          controlador: telefono,
          campoKey: const Key('fiar_nuevo_telefono'),
          icono: Icons.phone_outlined,
          tipoTeclado: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 12,
          runSpacing: 8,
          children: [
            BotonSecundario(
              texto: 'Cancelar',
              sinBorde: true,
              onPressed: () => vm.mostrarClienteNuevo(false),
            ),
            SizedBox(
              width: 220,
              child: BotonPrimario(
                key: const Key('fiar_nuevo_registrar'),
                texto: 'Registrar cliente',
                compacto: true,
                cargando: vm.registrando,
                onPressed: vm.registrando ? null : onRegistrar,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  static Widget _aviso(ThemeData tema, String texto, Key key) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(
      texto,
      key: key,
      style: tema.textTheme.bodyMedium?.copyWith(
        color: tema.colorScheme.error,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  /// "300 412 4521 · 3 fiados pendientes" o "… · al día".
  static String _subtitulo(Cliente cliente) {
    final pendientes = cliente.obtenerFiadosPendientes().length;
    return [
      if (cliente.getTelefono().isNotEmpty) cliente.getTelefono(),
      switch (pendientes) {
        0 => 'al día',
        1 => '1 fiado pendiente',
        _ => '$pendientes fiados pendientes',
      },
    ].join(' · ');
  }

  /// "debe $ 47.500" o "$ 0".
  static String _saldo(Cliente cliente) {
    final saldo = cliente.calcularSaldoPendiente();
    return saldo > Decimal.zero
        ? 'debe \$ ${mostrarPrecio(saldo)}'
        : '\$ ${mostrarPrecio(saldo)}';
  }
}
