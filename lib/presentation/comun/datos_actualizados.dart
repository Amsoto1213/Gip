import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Avisa que llegaron datos de otros equipos a la base local (CUS-23, DI-49).
/// Lo dispara la sincronización cuando bajó algo que cambió en este equipo; las
/// pantallas que muestran datos se suscriben con
/// [RecargarAlCambiarLosDatos] y vuelven a leerlos.
class DatosActualizados extends ChangeNotifier {
  int _version = 0;

  /// Cuántas veces han llegado datos nuevos; sirve para las pruebas.
  int get version => _version;

  /// Hay datos nuevos en la base local.
  void avisar() {
    _version++;
    notifyListeners();
  }
}

/// Vuelve a leer los datos de la pantalla cada vez que llegan datos de otros
/// equipos, para que el tendero no vea cifras viejas (DI-49). Va justo debajo
/// del `ChangeNotifierProvider` del view model: [alRecargar] recibe ese view
/// model y llama a su método de carga. No dibuja nada propio.
///
/// Solo se usa en pantallas que **muestran** datos. En las que el usuario está
/// escribiendo o armando algo (la venta, un formulario, el conteo) no se usa:
/// recargarlas le borraría lo que lleva hecho.
class RecargarAlCambiarLosDatos<VM extends ChangeNotifier>
    extends StatefulWidget {
  const RecargarAlCambiarLosDatos({
    super.key,
    required this.alRecargar,
    required this.child,
  });

  /// Qué hacer con el view model de la pantalla cuando llegan datos.
  final void Function(VM viewModel) alRecargar;
  final Widget child;

  @override
  State<RecargarAlCambiarLosDatos<VM>> createState() =>
      _RecargarAlCambiarLosDatosState<VM>();
}

class _RecargarAlCambiarLosDatosState<VM extends ChangeNotifier>
    extends State<RecargarAlCambiarLosDatos<VM>> {
  DatosActualizados? _datos;

  @override
  void initState() {
    super.initState();
    // Sin el aviso en el árbol (una pantalla probada sola) simplemente no
    // recarga.
    try {
      _datos = context.read<DatosActualizados>()..addListener(_recargar);
    } on ProviderNotFoundException {
      _datos = null;
    }
  }

  void _recargar() {
    if (!mounted) return;
    widget.alRecargar(context.read<VM>());
  }

  @override
  void dispose() {
    _datos?.removeListener(_recargar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
