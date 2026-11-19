import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';

/// "$ 12.000".
String pesos(Decimal valor) => '\$ ${mostrarPrecio(valor)}';

/// Hora local de un movimiento: "2:30 p. m.".
String horaDe(DateTime fecha) {
  final local = fecha.toLocal();
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minutos = local.minute.toString().padLeft(2, '0');
  return '$h:$minutos ${local.hour < 12 ? 'a. m.' : 'p. m.'}';
}

/// "+ $ 8.500" si entra y "− $ 12.000" si sale.
String valorConSigno(MovimientoCaja m) =>
    '${m.esIngreso() ? '+' : '−'} ${pesos(m.getValor())}';

/// Lo que se muestra como título de un movimiento: su descripción o, si no
/// tiene, su clase.
String tituloDe(MovimientoCaja m) {
  final descripcion = m.getDescripcion().trim();
  if (descripcion.isNotEmpty) return descripcion;
  return m.esDelNegocio() ? 'Del negocio' : 'Personal';
}

/// "Negocio" o "Personal" (los movimientos de anulación se anotan solos).
String claseDe(MovimientoCaja m) => m.esDelNegocio() ? 'Negocio' : 'Personal';

PildoraEstado _pildoraDe(MovimientoCaja m) => PildoraEstado(
  claseDe(m),
  tono: m.esDelNegocio() ? TonoEstado.bien : TonoEstado.neutro,
);

/// Tabla "Movimientos de hoy" de la web (mockup `wCaja`): hora, descripción,
/// clase y valor, el más reciente primero.
class TarjetaMovimientosHoy extends StatelessWidget {
  const TarjetaMovimientosHoy({super.key, required this.movimientos});

  final List<MovimientoCaja> movimientos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final secundario = tema.textTheme.labelMedium;
    return TarjetaGip(
      key: const Key('caja_movimientos_hoy'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Movimientos de hoy', style: tema.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (movimientos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Todavía no hay movimientos hoy.',
                key: const Key('caja_sin_movimientos'),
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            Row(
              children: [
                SizedBox(width: 96, child: Text('Hora', style: secundario)),
                Expanded(child: Text('Descripción', style: secundario)),
                SizedBox(width: 120, child: Text('Clase', style: secundario)),
                SizedBox(
                  width: 120,
                  child: Text(
                    'Valor',
                    textAlign: TextAlign.end,
                    style: secundario,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final m in movimientos)
              Container(
                key: Key('caja_mov_${m.getId()}'),
                constraints: const BoxConstraints(minHeight: 52),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: tema.colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        horaDe(m.getFecha()),
                        style: tema.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tituloDe(m),
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.bodyLarge,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _pildoraDe(m),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        valorConSigno(m),
                        textAlign: TextAlign.end,
                        style: tema.textTheme.bodyLarge?.cifrasTabulares,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Lista "Hoy" del móvil (mockup `mCaja`): una tarjeta con una fila por
/// movimiento, el más reciente primero.
class ListaMovimientosHoy extends StatelessWidget {
  const ListaMovimientosHoy({super.key, required this.movimientos});

  final List<MovimientoCaja> movimientos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Hoy', style: tema.textTheme.titleLarge),
        const SizedBox(height: 12),
        TarjetaGip(
          key: const Key('caja_movimientos_hoy'),
          child: movimientos.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Todavía no hay movimientos hoy.',
                    key: const Key('caja_sin_movimientos'),
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < movimientos.length; i++)
                      Container(
                        key: Key('caja_mov_${movimientos[i].getId()}'),
                        constraints: const BoxConstraints(minHeight: 64),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: i == 0
                            ? null
                            : BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: tema.colorScheme.outlineVariant,
                                  ),
                                ),
                              ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tituloDe(movimientos[i]),
                                    overflow: TextOverflow.ellipsis,
                                    style: tema.textTheme.titleMedium,
                                  ),
                                  Text(
                                    '${horaDe(movimientos[i].getFecha())} · '
                                    '${claseDe(movimientos[i])}',
                                    style: tema.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              valorConSigno(movimientos[i]),
                              style:
                                  tema.textTheme.titleMedium?.cifrasTabulares,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
