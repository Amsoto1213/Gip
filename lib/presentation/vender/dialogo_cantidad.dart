import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/surtido/widgets_movimiento.dart';
import 'package:gip/presentation/vender/vender_view_model.dart';

/// La pregunta con la unidad en su género: "Cuántas unidades", "Cuántos kilos",
/// "Cuántas libras".
String _cuantos(UnidadMedida unidad) => switch (unidad) {
  UnidadMedida.unidad => 'Cuántas unidades',
  UnidadMedida.kilogramo => 'Cuántos kilos',
  UnidadMedida.libra => 'Cuántas libras',
};

/// Pide la cantidad de una línea de la venta (CUS-02, DI-53): un diálogo con un
/// campo para escribirla. En kilos y libras acepta decimales (3,4); por unidad
/// solo enteros. Termina con la cantidad, o con null si el tendero cancela.
/// Las reglas las da [VenderViewModel.errorDeCantidad].
Future<Decimal?> pedirCantidad(
  BuildContext context, {
  required String producto,
  required UnidadMedida unidad,
  required Decimal actual,
}) => showDialog<Decimal>(
  context: context,
  barrierColor: Theme.of(context).colorScheme.scrim,
  builder: (_) =>
      _DialogoCantidad(producto: producto, unidad: unidad, actual: actual),
);

class _DialogoCantidad extends StatefulWidget {
  const _DialogoCantidad({
    required this.producto,
    required this.unidad,
    required this.actual,
  });

  final String producto;
  final UnidadMedida unidad;
  final Decimal actual;

  @override
  State<_DialogoCantidad> createState() => _DialogoCantidadState();
}

class _DialogoCantidadState extends State<_DialogoCantidad> {
  late final _controlador = TextEditingController(
    text: mostrarCantidad(widget.actual),
  );
  String? _error;

  @override
  void initState() {
    super.initState();
    // El valor de ahora queda seleccionado: escribir lo reemplaza.
    _controlador.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controlador.text.length,
    );
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _aceptar() {
    final error = VenderViewModel.errorDeCantidad(
      _controlador.text,
      widget.unidad,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context)
        .pop(VenderViewModel.leerCantidad(_controlador.text, widget.unidad));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final decimales = VenderViewModel.admiteDecimales(widget.unidad);
    return AlertDialog(
      key: const Key('dialogo_cantidad'),
      backgroundColor: tema.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FormaGip.radioTarjeta),
      ),
      title: Text(
        '¿${_cuantos(widget.unidad)} de ${widget.producto}?',
        style: tema.textTheme.titleMedium,
      ),
      content: SizedBox(
        width: 360,
        child: CampoGip(
          campoKey: const Key('dialogo_cantidad_campo'),
          etiqueta: 'Cantidad en ${unidadCorta(widget.unidad)}',
          controlador: _controlador,
          pista: decimales ? 'Ej.: 3,4' : 'Ej.: 3',
          error: _error,
          tipoTeclado: TextInputType.numberWithOptions(decimal: decimales),
          formateadores: [
            if (decimales)
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
            else
              FilteringTextInputFormatter.digitsOnly,
          ],
          accionTeclado: TextInputAction.done,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _aceptar(),
        ),
      ),
      actionsOverflowButtonSpacing: 8,
      actions: [
        BotonSecundario(
          key: const Key('dialogo_cantidad_cancelar'),
          texto: 'Cancelar',
          sinBorde: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        BotonPrimario(
          key: const Key('dialogo_cantidad_aceptar'),
          texto: 'Aceptar',
          compacto: true,
          onPressed: _aceptar,
        ),
      ],
    );
  }
}
