import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/dialogo_confirmacion.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/mensaje_resultado.dart';
import 'package:gip/presentation/comun/nota_info.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/negocio/rutas_negocio.dart';
import 'package:gip/presentation/negocio/usuarios_view_model.dart';
import 'package:gip/presentation/surtido/widgets_movimiento.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Usuarios de la tienda (CUS-15), según los mockups `mUsuarios` y
/// `wUsuarios` con los componentes del rediseño: la lista de usuarios, activos
/// e inactivos, y el formulario "Agregar empleado". Desactivar pide
/// confirmación; el propietario no se desactiva.
///
/// Agregar un empleado crea también su cuenta de acceso: el formulario pide
/// correo y contraseña, y el empleado entra con ellos (DI-43). La lista muestra
/// el correo de cada usuario.
///
/// No se muestran la fecha de alta ("desde jul. 2026", la tabla web muestra el
/// correo en su lugar) ni la de baja ("desactivada el 3 nov.") porque
/// `Usuario` no las guarda, ni el género ("Propietaria", "Empleada"), ni "con
/// la cédula … y su PIN": el PIN no existe, se inicia sesión con correo y
/// contraseña (DI-05, DI-42, DI-43).
class UsuariosView extends StatefulWidget {
  const UsuariosView({super.key});

  static const notaEmpleado =
      'Un empleado puede vender, surtir y fiar. No ve la caja, la ganancia ni '
      'los reportes.';

  static const notaDesactivar =
      'Al desactivar a alguien se pide confirmación. Sus ventas y registros se '
      'conservan. El propietario no se puede desactivar.';

  @override
  State<UsuariosView> createState() => _UsuariosViewState();
}

class _UsuariosViewState extends State<UsuariosView> {
  final _nombre = TextEditingController();
  final _cedula = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();

  /// Para llevar la pantalla hasta el resultado de un intento.
  final _resultadoKey = GlobalKey();

  @override
  void dispose() {
    _nombre.dispose();
    _cedula.dispose();
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  void _volver() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(rutaPrincipalNegocio);
    }
  }

  /// Lleva el resultado del intento a la vista. En el móvil sale entre la lista
  /// y el formulario, así que el formulario no se aleja si hay que corregir.
  void _verResultado() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contexto = _resultadoKey.currentContext;
      if (!mounted || contexto == null) return;
      Scrollable.ensureVisible(
        contexto,
        alignment: 0.2,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _agregar() async {
    final vm = context.read<UsuariosViewModel>();
    final creado = await vm.agregar(
      _nombre.text,
      _cedula.text,
      _correo.text,
      _clave.text,
    );
    if (creado) {
      _nombre.clear();
      _cedula.clear();
      _correo.clear();
      _clave.clear();
    }
    if (mounted) _verResultado();
  }

  Future<void> _desactivar(Usuario empleado) async {
    final vm = context.read<UsuariosViewModel>();
    final confirmado = await pedirConfirmacion(
      context,
      pregunta:
          '¿Desactivar a ${empleado.getNombre()}? No podrá volver a iniciar '
          'sesión. Sus ventas y registros se conservan.',
      textoConfirmar: 'Desactivar',
    );
    if (!confirmado) return;
    await vm.desactivar(empleado);
    if (mounted) _verResultado();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UsuariosViewModel>();
    final web = FormaGip.esWeb(context);

    final List<Widget> cuerpo;
    if (vm.errorCarga case final error?) {
      cuerpo = [
        TarjetaAviso(
          key: const Key('usuarios_error_carga'),
          titulo: error,
          icono: error == UsuariosViewModel.mensajeSoloPropietario
              ? Icons.lock_outline
              : Icons.warning_amber_rounded,
        ),
      ];
    } else if (vm.cargando && vm.usuarios.isEmpty) {
      cuerpo = const [
        Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    } else {
      final lista = _Lista(vm: vm, web: web, onDesactivar: _desactivar);
      final formulario = _Formulario(
        vm: vm,
        nombre: _nombre,
        cedula: _cedula,
        correo: _correo,
        clave: _clave,
        onAgregar: _agregar,
      );
      final resultado = _Resultado(key: _resultadoKey, vm: vm);
      cuerpo = [
        if (web) resultado,
        if (web)
          // La lista a la izquierda y el formulario a la derecha (340–420 px).
          ColumnasMovimiento(
            formulario: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                lista,
                const SizedBox(height: 18),
                const NotaInfo(
                  key: Key('usuarios_nota'),
                  texto: UsuariosView.notaDesactivar,
                ),
              ],
            ),
            resumen: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                formulario,
                const SizedBox(height: 18),
                const NotaInfo(
                  key: Key('usuarios_nota_empleado'),
                  texto: UsuariosView.notaEmpleado,
                ),
              ],
            ),
          )
        else ...[
          lista,
          const SizedBox(height: 16),
          resultado,
          formulario,
          const SizedBox(height: 16),
          const NotaInfo(
            key: Key('usuarios_nota_empleado'),
            texto: UsuariosView.notaEmpleado,
          ),
        ],
      ];
    }

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: web ? 1240 : 880),
            child: RefreshIndicator(
              onRefresh: vm.cargar,
              child: ListView(
                padding: web
                    ? const EdgeInsets.fromLTRB(44, 32, 44, 48)
                    : const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  EncabezadoPantalla(
                    titulo: 'Usuarios de la tienda',
                    miga: 'Usuarios',
                    seccion: 'Negocio',
                    onVolver: _volver,
                  ),
                  SizedBox(height: web ? 24 : 16),
                  ...cuerpo,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lo que dejó el último intento de agregar o desactivar.
class _Resultado extends StatelessWidget {
  const _Resultado({super.key, required this.vm});

  final UsuariosViewModel vm;

  @override
  Widget build(BuildContext context) {
    final Widget? tarjeta;
    if (vm.error case final error?) {
      tarjeta = TarjetaAviso(
        key: const Key('usuarios_error'),
        titulo: error,
        icono: error == UsuariosViewModel.mensajeSoloPropietario
            ? Icons.lock_outline
            : Icons.warning_amber_rounded,
      );
    } else if (vm.mensajeListo case final listo?) {
      tarjeta = MensajeResultado(
        key: const Key('usuarios_listo'),
        texto: listo,
        esError: false,
      );
    } else {
      tarjeta = null;
    }
    if (tarjeta == null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: tarjeta);
  }
}

String _rol(Usuario u) => u is Administrador ? 'Propietario' : 'Empleado';

/// Los usuarios, activos e inactivos: en el móvil una fila por usuario con su
/// estado o su botón; en la web una tabla con Nombre, Rol, Estado y la acción.
class _Lista extends StatelessWidget {
  const _Lista({
    required this.vm,
    required this.web,
    required this.onDesactivar,
  });

  final UsuariosViewModel vm;
  final bool web;
  final ValueChanged<Usuario> onDesactivar;

  @override
  Widget build(BuildContext context) {
    final extra = Theme.of(context).extension<ColoresExtraGip>()!;
    return TarjetaGip(
      key: const Key('usuarios_lista'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (web) const _EncabezadoTabla(),
          for (final (i, u) in vm.usuarios.indexed) ...[
            if (i > 0 || web) Divider(height: 1, color: extra.separador),
            web
                ? _FilaWeb(vm: vm, usuario: u, onDesactivar: onDesactivar)
                : _FilaMovil(vm: vm, usuario: u, onDesactivar: onDesactivar),
          ],
        ],
      ),
    );
  }
}

PildoraEstado _pildora(Usuario u) => u.isActivo()
    ? const PildoraEstado('Activo', tono: TonoEstado.bien)
    : const PildoraEstado('Inactivo', tono: TonoEstado.neutro);

Widget _botonDesactivar(
  UsuariosViewModel vm,
  Usuario u,
  ValueChanged<Usuario> onDesactivar,
) => BotonSecundario(
  key: Key('usuario_desactivar_${u.getId()}'),
  texto: 'Desactivar',
  alto: 44,
  onPressed: vm.ocupado ? null : () => onDesactivar(u),
);

class _FilaMovil extends StatelessWidget {
  const _FilaMovil({
    required this.vm,
    required this.usuario,
    required this.onDesactivar,
  });

  final UsuariosViewModel vm;
  final Usuario usuario;
  final ValueChanged<Usuario> onDesactivar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final u = usuario;
    return ConstrainedBox(
      key: Key('usuario_${u.getId()}'),
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: esquema.primaryContainer,
              child: Icon(Icons.person_outline, color: esquema.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.getNombre(), style: tema.textTheme.titleMedium),
                  Text(
                    vm.esUsted(u) ? '${_rol(u)} · usted' : _rol(u),
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                  if (u.getCorreo() case final correo?)
                    Text(
                      correo,
                      key: Key('usuario_correo_${u.getId()}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: esquema.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (vm.puedeDesactivarse(u))
              _botonDesactivar(vm, u, onDesactivar)
            else
              _pildora(u),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoTabla extends StatelessWidget {
  const _EncabezadoTabla();

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelMedium;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Nombre', style: estilo)),
          Expanded(flex: 2, child: Text('Rol', style: estilo)),
          Expanded(flex: 4, child: Text('Correo', style: estilo)),
          Expanded(flex: 2, child: Text('Estado', style: estilo)),
          const SizedBox(width: 130),
        ],
      ),
    );
  }
}

class _FilaWeb extends StatelessWidget {
  const _FilaWeb({
    required this.vm,
    required this.usuario,
    required this.onDesactivar,
  });

  final UsuariosViewModel vm;
  final Usuario usuario;
  final ValueChanged<Usuario> onDesactivar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final u = usuario;
    final atenuado = !u.isActivo();
    final color = atenuado ? tema.colorScheme.onSurfaceVariant : null;
    return ConstrainedBox(
      key: Key('usuario_${u.getId()}'),
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text.rich(
                TextSpan(
                  text: u.getNombre(),
                  style: tema.textTheme.titleSmall?.copyWith(color: color),
                  children: [
                    if (vm.esUsted(u))
                      TextSpan(
                        text: ' (usted)',
                        style: tema.textTheme.bodyLarge,
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _rol(u),
                style: tema.textTheme.bodyLarge?.copyWith(color: color),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                u.getCorreo() ?? '',
                key: Key('usuario_correo_${u.getId()}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tema.textTheme.bodyLarge?.copyWith(color: color),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(alignment: Alignment.centerLeft, child: _pildora(u)),
            ),
            SizedBox(
              width: 130,
              child: Align(
                alignment: Alignment.centerRight,
                child: vm.puedeDesactivarse(u)
                    ? _botonDesactivar(vm, u, onDesactivar)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Agregar empleado": nombre, cédula y el botón.
class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.vm,
    required this.nombre,
    required this.cedula,
    required this.correo,
    required this.clave,
    required this.onAgregar,
  });

  final UsuariosViewModel vm;
  final TextEditingController nombre;
  final TextEditingController cedula;
  final TextEditingController correo;
  final TextEditingController clave;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return TarjetaGip(
      key: const Key('usuarios_formulario'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Agregar empleado', style: tema.textTheme.titleLarge),
          const SizedBox(height: 16),
          CampoGip(
            campoKey: const Key('usuarios_nombre'),
            etiqueta: 'Nombre completo',
            controlador: nombre,
            pista: 'Ej.: Daniel Mendoza',
            habilitado: !vm.ocupado,
            mayusculas: TextCapitalization.words,
            accionTeclado: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CampoGip(
            campoKey: const Key('usuarios_cedula'),
            etiqueta: 'Cédula',
            controlador: cedula,
            pista: 'Solo números',
            habilitado: !vm.ocupado,
            tipoTeclado: TextInputType.number,
            formateadores: [FilteringTextInputFormatter.digitsOnly],
            accionTeclado: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CampoGip(
            campoKey: const Key('usuarios_correo'),
            etiqueta: 'Correo',
            controlador: correo,
            pista: 'daniel@correo.com',
            ayuda: 'Con este correo y su contraseña el empleado entra a GIP.',
            habilitado: !vm.ocupado,
            tipoTeclado: TextInputType.emailAddress,
            accionTeclado: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CampoGip(
            campoKey: const Key('usuarios_clave'),
            etiqueta: 'Contraseña',
            controlador: clave,
            pista: 'Mínimo 6 caracteres',
            contrasena: true,
            habilitado: !vm.ocupado,
            accionTeclado: TextInputAction.done,
            onSubmitted: (_) => vm.ocupado ? null : onAgregar(),
          ),
          const SizedBox(height: 20),
          BotonPrimario(
            key: const Key('usuarios_agregar'),
            texto: 'Agregar empleado',
            icono: Icons.add,
            cargando: vm.ocupado,
            onPressed: vm.ocupado ? null : onAgregar,
          ),
        ],
      ),
    );
  }
}
