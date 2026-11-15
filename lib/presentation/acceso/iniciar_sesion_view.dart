import 'package:flutter/material.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/logo_gip.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:provider/provider.dart';

/// Pantalla de inicio de sesión con correo y contraseña (DI-05), según
/// `docs/ui/rediseno/login-web.html` y `login-movil.html`: en la web, panel
/// verde a la izquierda y el formulario a la derecha; en el móvil, el panel
/// arriba y el formulario montado encima.
class IniciarSesionView extends StatefulWidget {
  const IniciarSesionView({super.key});

  /// Desde este ancho caben las dos mitades.
  static const anchoDosMitades = 960.0;

  @override
  State<IniciarSesionView> createState() => _IniciarSesionViewState();
}

class _IniciarSesionViewState extends State<IniciarSesionView> {
  final _correo = TextEditingController();
  final _clave = TextEditingController();

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  void _entrar() {
    context.read<IniciarSesionViewModel>().iniciarSesion(
      _correo.text,
      _clave.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IniciarSesionViewModel>();
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricciones) =>
            restricciones.maxWidth >= IniciarSesionView.anchoDosMitades
            ? _web(vm)
            : _movil(vm),
      ),
    );
  }

  Widget _web(IniciarSesionViewModel vm) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Expanded(flex: 56, child: _PanelVerde(web: true)),
      Expanded(
        flex: 52,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: TarjetaGip(
                  elevada: true,
                  radio: 24,
                  padding: const EdgeInsets.fromLTRB(40, 40, 40, 36),
                  child: _Formulario(
                    web: true,
                    correo: _correo,
                    clave: _clave,
                    vm: vm,
                    onEntrar: _entrar,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _movil(IniciarSesionViewModel vm) {
    final tema = Theme.of(context);
    return SingleChildScrollView(
      child: Stack(
        children: [
          const SizedBox(
            width: double.infinity,
            height: 330,
            child: _PanelVerde(web: false),
          ),
          SafeArea(
            child: Padding(
              // El formulario se monta 30 px sobre el panel (prototipo).
              padding: EdgeInsets.fromLTRB(
                16,
                300 - MediaQuery.paddingOf(context).top,
                16,
                26,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TarjetaGip(
                        elevada: true,
                        radio: 26,
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                        child: _Formulario(
                          web: false,
                          correo: _correo,
                          clave: _clave,
                          vm: vm,
                          onEntrar: _entrar,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _Aviso(
                        icono: Icons.cloud_done_outlined,
                        texto: 'Después de la primera vez, abre sin internet',
                        centrado: true,
                        estilo: tema.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.web,
    required this.correo,
    required this.clave,
    required this.vm,
    required this.onEntrar,
  });

  final bool web;
  final TextEditingController correo;
  final TextEditingController clave;
  final IniciarSesionViewModel vm;
  final VoidCallback onEntrar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final separacion = SizedBox(height: web ? 22 : 16);
    final error = vm.error;
    final avisoClave = _Aviso(
      icono: Icons.help_outline,
      texto:
          '¿Olvidó la contraseña? Pídale al administrador de la tienda que '
          'la cambie.',
      centrado: !web,
      sinIcono: !web,
      estilo: tema.textTheme.bodySmall?.copyWith(
        fontSize: web ? 14 : 13,
        height: 1.45,
      ),
    );
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Iniciar sesión',
              style: tema.textTheme.headlineLarge?.copyWith(
                fontSize: web ? 30 : 24,
                letterSpacing: web ? -0.3 : null,
              ),
            ),
          ),
          SizedBox(height: web ? 8 : 4),
          Text(
            web
                ? 'Entre con el correo y la contraseña de su tienda.'
                : 'Con el correo de su tienda.',
            style: tema.textTheme.bodyLarge?.copyWith(
              fontSize: web ? 16 : 15,
              color: esquema.onSurfaceVariant,
            ),
          ),
          separacion,
          CampoGip(
            etiqueta: 'Correo',
            controlador: correo,
            campoKey: const Key('acceso_correo'),
            icono: Icons.mail_outline,
            pista: 'nombre@tienda.com',
            alto: web ? 54 : 52,
            habilitado: !vm.enviando,
            tipoTeclado: TextInputType.emailAddress,
            accionTeclado: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          separacion,
          CampoGip(
            etiqueta: 'Contraseña',
            controlador: clave,
            campoKey: const Key('acceso_clave'),
            icono: Icons.lock_outline,
            pista: 'Su contraseña',
            contrasena: true,
            alto: web ? 54 : 52,
            habilitado: !vm.enviando,
            accionTeclado: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => onEntrar(),
          ),
          if (error != null) ...[
            separacion,
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: esquema.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: esquema.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        error,
                        style: tema.textTheme.bodyMedium?.copyWith(
                          color: esquema.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          separacion,
          BotonPrimario(
            key: const Key('acceso_entrar'),
            texto: 'Entrar',
            icono: Icons.arrow_forward,
            iconoAlFinal: true,
            cargando: vm.enviando,
            onPressed: onEntrar,
          ),
          if (web) ...[
            separacion,
            const Divider(),
            separacion,
            _Aviso(
              icono: Icons.cloud_done_outlined,
              texto:
                  'Después de entrar la primera vez, la app abre aunque no '
                  'haya internet.',
              estilo: tema.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 12),
            avisoClave,
          ] else ...[
            const SizedBox(height: 16),
            avisoClave,
          ],
        ],
      ),
    );
  }
}

/// Aviso con ícono verde y texto secundario.
class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icono,
    required this.texto,
    required this.estilo,
    this.centrado = false,
    this.sinIcono = false,
  });

  final IconData icono;
  final String texto;
  final TextStyle? estilo;
  final bool centrado;
  final bool sinIcono;

  @override
  Widget build(BuildContext context) {
    final texto = Text(
      this.texto,
      textAlign: centrado ? TextAlign.center : TextAlign.start,
      style: estilo,
    );
    if (sinIcono) return texto;
    return Row(
      mainAxisAlignment: centrado
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icono,
            size: centrado ? 16 : 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        centrado ? Flexible(child: texto) : Expanded(child: texto),
      ],
    );
  }
}

/// Panel verde con punteado blanco al 10 %, dos círculos decorativos, el
/// logo y el nombre. Es decorativo: el lector de pantalla lo salta.
class _PanelVerde extends StatelessWidget {
  const _PanelVerde({required this.web});

  final bool web;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final extra = tema.extension<ColoresExtraGip>()!;
    final blanco = esquema.onPrimary;
    Widget circulo(double tamano, Color color) => Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    final nombre = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoGip(tamano: web ? 104 : 80, sobreVerde: true),
        SizedBox(height: web ? 22 : 14),
        Text(
          'GIP',
          style: tema.textTheme.headlineLarge?.copyWith(
            fontSize: web ? 64 : 40,
            height: 1,
            letterSpacing: (web ? 64 : 40) * -0.02,
            color: blanco,
          ),
        ),
        SizedBox(height: web ? 6 : 4),
        Text(
          'Gestor de Inventario Predictivo',
          textAlign: TextAlign.center,
          style: tema.textTheme.bodyLarge?.copyWith(
            fontSize: web ? 18 : 15,
            fontWeight: FontWeight.w500,
            color: blanco.withValues(alpha: 0.85),
          ),
        ),
        if (web) ...[
          const SizedBox(height: 22),
          Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
              color: blanco.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Bienvenido de nuevo',
            style: tema.textTheme.titleLarge?.copyWith(
              fontSize: 24,
              color: blanco,
            ),
          ),
        ],
      ],
    );
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: web
            ? BorderRadius.zero
            : const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: CustomPaint(
          painter: _Punteado(
            fondo: esquema.primary,
            punto: blanco.withValues(alpha: 0.10),
          ),
          child: Stack(
            children: [
              if (web) ...[
                Positioned(
                  right: -160,
                  top: -140,
                  child: circulo(520, extra.verdeCirculoClaro),
                ),
                Positioned(
                  left: -120,
                  bottom: -120,
                  child: circulo(380, extra.verdeCirculoOscuro),
                ),
                Positioned.fill(
                  child: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(48),
                        child: nombre,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Positioned(
                  right: -110,
                  top: -120,
                  child: circulo(300, extra.verdeCirculoClaro),
                ),
                Positioned(
                  left: -70,
                  bottom: -80,
                  child: circulo(200, extra.verdeCirculoOscuro),
                ),
                Positioned(left: 0, right: 0, top: 70, child: nombre),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fondo `primario` con un punto de 1,2 px cada 22 px.
class _Punteado extends CustomPainter {
  _Punteado({required this.fondo, required this.punto});

  final Color fondo;
  final Color punto;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fondo);
    final pintura = Paint()..color = punto;
    const paso = 22.0;
    for (var y = paso / 2; y < size.height; y += paso) {
      for (var x = paso / 2; x < size.width; x += paso) {
        canvas.drawCircle(Offset(x, y), 1.2, pintura);
      }
    }
  }

  @override
  bool shouldRepaint(_Punteado viejo) =>
      viejo.fondo != fondo || viejo.punto != punto;
}
