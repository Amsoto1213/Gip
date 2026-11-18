import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Lectura de códigos con la cámara del celular (CUS-17, alt "cámara del
/// celular, app Android"). El lector 2D en modo teclado no pasa por aquí:
/// escribe el texto en el campo enfocado y termina con Enter. La Business
/// Layer solo recibe el texto, venga de donde venga (DA-47).

/// La cámara se usa solo en la app Android; en la web se lee con el lector 2D
/// (diagrama de CUS-17, `docs/ui/paridad.md`).
bool get camaraDisponible =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Resultado de abrir la cámara. Si el tendero la cierra sin leer, no hay
/// resultado (null).
sealed class ResultadoLectura {
  const ResultadoLectura();
}

/// La cámara leyó [texto], tal como viene en el código.
final class LecturaLeida extends ResultadoLectura {
  const LecturaLeida(this.texto);

  final String texto;
}

/// No se pudo usar la cámara: permiso negado, sin cámara o falla del equipo
/// (alt "Lectura fallida"). Quien la abrió muestra el mensaje.
final class LecturaFallida extends ResultadoLectura {
  const LecturaFallida();
}

/// Abre [LeerCodigoView] encima de todo y espera la lectura.
Future<ResultadoLectura?> leerCodigoConCamara(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push<ResultadoLectura>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LeerCodigoView(),
      ),
    );

/// Nombre del formato para mostrar ("EAN-13", "QR").
String nombreFormato(FormatoCodigo formato) => switch (formato) {
  FormatoCodigo.ean13 => 'EAN-13',
  FormatoCodigo.ean8 => 'EAN-8',
  FormatoCodigo.upca => 'UPC-A',
  FormatoCodigo.qr => 'QR',
};

/// Pantalla "Leer código" (mockup `Escanear`): vista de la cámara con el marco
/// y la linterna. Devuelve la primera lectura con `pop`. No muestra la tarjeta
/// del lector Bluetooth ni la del producto leído: la lectura vuelve a la
/// pantalla que la pidió, que sigue el flujo (DI-34).
class LeerCodigoView extends StatefulWidget {
  const LeerCodigoView({super.key});

  @override
  State<LeerCodigoView> createState() => _LeerCodigoViewState();
}

class _LeerCodigoViewState extends State<LeerCodigoView> {
  final _camara = MobileScannerController();
  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    _camara.addListener(_revisarError);
  }

  @override
  void dispose() {
    _camara.removeListener(_revisarError);
    _camara.dispose();
    super.dispose();
  }

  void _terminar(ResultadoLectura? resultado) {
    if (_terminado || !mounted) return;
    _terminado = true;
    Navigator.of(context).pop(resultado);
  }

  void _revisarError() {
    if (_camara.value.error != null) _terminar(const LecturaFallida());
  }

  void _detectar(BarcodeCapture captura) {
    final texto = captura.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .where((t) => t.trim().isNotEmpty)
        .firstOrNull;
    if (texto != null) _terminar(LecturaLeida(texto));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final extra = tema.extension<ColoresExtraGip>()!;
    final blanco = esquema.onPrimary;

    return Scaffold(
      backgroundColor: extra.navFondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    key: const Key('leer_codigo_cerrar'),
                    tooltip: 'Cerrar',
                    color: blanco,
                    iconSize: 28,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => _terminar(null),
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Leer código',
                      style: tema.textTheme.headlineSmall?.copyWith(
                        color: blanco,
                      ),
                    ),
                  ),
                  _Linterna(camara: _camara),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(FormaGip.radioTarjeta),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(controller: _camara, onDetect: _detectar),
                        CustomPaint(painter: _Marco(color: blanco)),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Centre el código dentro del marco',
                              textAlign: TextAlign.center,
                              style: tema.textTheme.bodyLarge?.copyWith(
                                color: extra.navTexto,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

/// Botón de la linterna; no aparece si la cámara no tiene.
class _Linterna extends StatelessWidget {
  const _Linterna({required this.camara});

  final MobileScannerController camara;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: camara,
      builder: (context, estado, _) {
        final linterna = estado.torchState;
        if (linterna == TorchState.unavailable) {
          return const SizedBox.shrink();
        }
        final encendida = linterna == TorchState.on;
        return IconButton(
          tooltip: encendida ? 'Apagar la linterna' : 'Encender la linterna',
          color: esquema.onPrimary,
          iconSize: 26,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: camara.toggleTorch,
          icon: Icon(encendida ? Icons.flashlight_off : Icons.flashlight_on),
        );
      },
    );
  }
}

/// Las cuatro esquinas del marco donde se centra el código.
class _Marco extends CustomPainter {
  const _Marco({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ancho = size.width * 0.72;
    final alto = ancho * 0.62;
    final caja = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: ancho,
      height: alto,
    );
    const largo = 36.0;
    final pincel = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (final (esquina, dx, dy) in [
      (caja.topLeft, 1.0, 1.0),
      (caja.topRight, -1.0, 1.0),
      (caja.bottomLeft, 1.0, -1.0),
      (caja.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(esquina, esquina.translate(largo * dx, 0), pincel)
        ..drawLine(esquina, esquina.translate(0, largo * dy), pincel);
    }
  }

  @override
  bool shouldRepaint(_Marco anterior) => anterior.color != color;
}
