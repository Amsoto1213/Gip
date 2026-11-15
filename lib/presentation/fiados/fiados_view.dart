import 'package:flutter/material.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/workflow/pagos/registrar_abono_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/barra_busqueda.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/selector_filtro.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/fiados/abono_view_model.dart';
import 'package:gip/presentation/fiados/fiados_view_model.dart';
import 'package:gip/presentation/fiados/formato_fecha.dart';
import 'package:gip/presentation/fiados/rutas_fiados.dart';
import 'package:gip/presentation/fiados/widgets_fiados.dart';
import 'package:provider/provider.dart';

/// Sección Fiados: clientes con lo que deben (CUS-19 mínimo) y abonos
/// (CUS-08), según los mockups `mClientes` y `wClientes`.
///
/// En ancho suficiente es una sola página: la lista a la izquierda y, a la
/// derecha, el cliente elegido con su formulario de abono. En angosto, la
/// lista lleva a la pantalla del cliente y de ahí al abono.
///
/// No se muestran "+30 días", "41 días", "Cliente desde…", "Eliminar datos del
/// cliente", el indicador "Al día" ni las iniciales en círculo: llegan con
/// CUS-19 completo y CUS-21 (DI-27).
class FiadosView extends StatefulWidget {
  const FiadosView({super.key});

  /// Desde este ancho del cuerpo se usan dos columnas.
  static const anchoDosColumnas = 860.0;

  @override
  State<FiadosView> createState() => _FiadosViewState();
}

class _FiadosViewState extends State<FiadosView> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FiadosViewModel>();
    final web = FormaGip.esWeb(context);
    final deudores = vm.deudores;
    final contexto = vm.cargaInicial
        ? null
        : 'Le deben ${pesos(vm.deudaTotal)} · '
              '$deudores ${deudores == 1 ? 'cliente' : 'clientes'}';
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: LayoutBuilder(
              builder: (context, restricciones) {
                final dosColumnas =
                    restricciones.maxWidth >= FiadosView.anchoDosColumnas;
                final lista = _Lista(
                  vm: vm,
                  busqueda: _busqueda,
                  dosColumnas: dosColumnas,
                );
                return ListView(
                  padding: web
                      ? const EdgeInsets.fromLTRB(44, 36, 44, 48)
                      : const EdgeInsets.fromLTRB(16, 28, 16, 24),
                  children: [
                    EncabezadoPantalla(titulo: 'Fiados', contexto: contexto),
                    const SizedBox(height: 22),
                    if (dosColumnas)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: lista),
                          const SizedBox(width: 22),
                          Expanded(flex: 3, child: _DetalleWeb(vm: vm)),
                        ],
                      )
                    else
                      lista,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Búsqueda, filtros y lista de clientes.
class _Lista extends StatelessWidget {
  const _Lista({
    required this.vm,
    required this.busqueda,
    required this.dosColumnas,
  });

  final FiadosViewModel vm;
  final TextEditingController busqueda;
  final bool dosColumnas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final clientes = vm.clientes;
    final separador = Divider(height: 1, thickness: 1, color: extra.separador);

    Widget aviso(String texto, Key key) => Padding(
      padding: const EdgeInsets.all(16),
      child: Text(texto, key: key, style: tema.textTheme.bodyMedium),
    );

    final Widget contenido;
    if (vm.error case final error?) {
      contenido = TarjetaAviso(key: const Key('fiados_error'), titulo: error);
    } else if (vm.cargaInicial) {
      contenido = const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (clientes.isEmpty) {
      contenido = TarjetaGip(
        radio: FormaGip.radioTarjetaMovil,
        child: aviso(
          vm.sinResultados
              ? 'No hay clientes con ese nombre'
              : vm.filtro == FiltroClientes.deben
              ? 'Ningún cliente le debe. Los clientes se crean al fiar.'
              : 'Todavía no hay clientes. Se crean al fiar una venta.',
          const Key('fiados_vacio'),
        ),
      );
    } else {
      contenido = TarjetaGip(
        radio: FormaGip.radioTarjetaMovil,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, cliente) in clientes.indexed) ...[
              if (i > 0) separador,
              FilaCliente(
                key: Key('fiados_cliente_${cliente.getId()}'),
                cliente: cliente,
                saldo: vm.saldoDe(cliente),
                elegida: dosColumnas && vm.elegido?.getId() == cliente.getId(),
                conFlecha: !dosColumnas,
                onTap: () {
                  vm.elegir(cliente);
                  if (!dosColumnas) abrirCliente(context, vm);
                },
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BarraBusqueda(
          pista: 'Buscar cliente por nombre',
          controlador: busqueda,
          campoKey: const Key('fiados_buscar'),
          onChanged: vm.buscar,
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: SelectorFiltro<FiltroClientes>(
            prefijoClave: 'fiados_filtro',
            elegido: vm.filtro,
            onElegir: vm.filtrar,
            opciones: const [
              (valor: FiltroClientes.deben, etiqueta: 'Deben'),
              (valor: FiltroClientes.todos, etiqueta: 'Todos'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        contenido,
        const SizedBox(height: 14),
        Text(
          'Los clientes se crean al fiar, solo con nombre y teléfono.',
          style: tema.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// A la derecha (web): el cliente elegido con su formulario de abono.
class _DetalleWeb extends StatelessWidget {
  const _DetalleWeb({required this.vm});

  final FiadosViewModel vm;

  @override
  Widget build(BuildContext context) {
    final cliente = vm.elegido;
    if (cliente == null) {
      return TarjetaGip(
        radio: FormaGip.radioTarjetaMovil,
        padding: const EdgeInsets.all(24),
        child: Text(
          'Elija un cliente para ver sus fiados y registrar un abono.',
          key: const Key('fiados_elegir'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    // Un modelo nuevo por cliente y por lectura de la base: así el formulario
    // empieza con los fiados recién leídos (DI-27).
    return ChangeNotifierProvider(
      key: ValueKey((cliente.getId(), vm.generacion)),
      create: (context) => AbonoViewModel(
        context.read<RegistrarAbonoCoordinator>(),
        context.read<IniciarSesionViewModel>().usuarioActivo!.tienda,
        cliente,
      ),
      child: _ClienteYAbono(vm: vm, cliente: cliente),
    );
  }
}

class _ClienteYAbono extends StatelessWidget {
  const _ClienteYAbono({required this.vm, required this.cliente});

  final FiadosViewModel vm;
  final Cliente cliente;

  Future<void> _registrar(BuildContext context) async {
    final abono = context.read<AbonoViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    final registrado = await abono.registrar();
    if (registrado) {
      await vm.recargar();
      mensajes.showSnackBar(
        SnackBar(
          content: Text(
            'Abono registrado. Nuevo saldo: ${pesos(abono.saldoNuevo!)}',
          ),
        ),
      );
    } else if (abono.debeRecargar) {
      vm.avisar(abono.error!);
      await vm.recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final abono = context.watch<AbonoViewModel>();
    final tema = Theme.of(context);
    final fiado = abono.fiado;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(cliente.getNombre(), style: tema.textTheme.headlineMedium),
        const SizedBox(height: 14),
        if (vm.aviso case final aviso?) ...[
          TarjetaAviso(key: const Key('fiados_aviso'), titulo: aviso),
          const SizedBox(height: 14),
        ],
        ResumenCliente(
          cliente: cliente,
          saldoTotal: vm.saldoDe(cliente),
          fiadoElegido: fiado,
          onElegirFiado: abono.elegirFiado,
        ),
        const SizedBox(height: 20),
        BotonEliminarCliente(vm: vm, cliente: cliente),
        if (abono.fiados.isNotEmpty) ...[
          const SizedBox(height: 20),
          TarjetaGip(
            radio: FormaGip.radioTarjetaMovil,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  fiado == null
                      ? 'Registrar abono'
                      : 'Registrar abono · fiado del '
                            '${fechaCorta(fiado.getFechaInicio())}',
                  style: tema.textTheme.titleMedium,
                ),
                if (abono.errorFiado case final e?) ...[
                  const SizedBox(height: 8),
                  Text(
                    e,
                    key: const Key('abono_error_fiado'),
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                CamposAbono(vm: abono),
                if (abono.quedaSaldado && fiado != null) ...[
                  const SizedBox(height: 16),
                  AvisoSaldado(fiado: fiado),
                ],
                if (abono.error case final e?) ...[
                  const SizedBox(height: 12),
                  Text(
                    e,
                    key: const Key('abono_error'),
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 280,
                    child: BotonRegistrarAbono(
                      vm: abono,
                      conMonto: false,
                      onPressed: () => _registrar(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
