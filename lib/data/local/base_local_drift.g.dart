// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_local_drift.dart';

// ignore_for_file: type=lint
class $ColaPendientesTable extends ColaPendientes
    with TableInfo<$ColaPendientesTable, EntradaCola> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ColaPendientesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tiendaIdMeta = const VerificationMeta(
    'tiendaId',
  );
  @override
  late final GeneratedColumn<String> tiendaId = GeneratedColumn<String>(
    'tienda_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tablaMeta = const VerificationMeta('tabla');
  @override
  late final GeneratedColumn<String> tabla = GeneratedColumn<String>(
    'tabla',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _registroIdMeta = const VerificationMeta(
    'registroId',
  );
  @override
  late final GeneratedColumn<String> registroId = GeneratedColumn<String>(
    'registro_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operacionMeta = const VerificationMeta(
    'operacion',
  );
  @override
  late final GeneratedColumn<String> operacion = GeneratedColumn<String>(
    'operacion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intentosMeta = const VerificationMeta(
    'intentos',
  );
  @override
  late final GeneratedColumn<int> intentos = GeneratedColumn<int>(
    'intentos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> creadoEn =
      GeneratedColumn<DateTime>(
        'creado_en',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ColaPendientesTable.$convertercreadoEn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tiendaId,
    tabla,
    registroId,
    operacion,
    intentos,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cola_pendientes';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntradaCola> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tienda_id')) {
      context.handle(
        _tiendaIdMeta,
        tiendaId.isAcceptableOrUnknown(data['tienda_id']!, _tiendaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tiendaIdMeta);
    }
    if (data.containsKey('tabla')) {
      context.handle(
        _tablaMeta,
        tabla.isAcceptableOrUnknown(data['tabla']!, _tablaMeta),
      );
    } else if (isInserting) {
      context.missing(_tablaMeta);
    }
    if (data.containsKey('registro_id')) {
      context.handle(
        _registroIdMeta,
        registroId.isAcceptableOrUnknown(data['registro_id']!, _registroIdMeta),
      );
    } else if (isInserting) {
      context.missing(_registroIdMeta);
    }
    if (data.containsKey('operacion')) {
      context.handle(
        _operacionMeta,
        operacion.isAcceptableOrUnknown(data['operacion']!, _operacionMeta),
      );
    } else if (isInserting) {
      context.missing(_operacionMeta);
    }
    if (data.containsKey('intentos')) {
      context.handle(
        _intentosMeta,
        intentos.isAcceptableOrUnknown(data['intentos']!, _intentosMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntradaCola map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntradaCola(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tiendaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tienda_id'],
      )!,
      tabla: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tabla'],
      )!,
      registroId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registro_id'],
      )!,
      operacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operacion'],
      )!,
      intentos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intentos'],
      )!,
      creadoEn: $ColaPendientesTable.$convertercreadoEn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}creado_en'],
        )!,
      ),
    );
  }

  @override
  $ColaPendientesTable createAlias(String alias) {
    return $ColaPendientesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $convertercreadoEn =
      const ConversorFechaUtc();
}

class EntradaCola extends DataClass implements Insertable<EntradaCola> {
  final String id;
  final String tiendaId;
  final String tabla;
  final String registroId;
  final String operacion;
  final int intentos;
  final DateTime creadoEn;
  const EntradaCola({
    required this.id,
    required this.tiendaId,
    required this.tabla,
    required this.registroId,
    required this.operacion,
    required this.intentos,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tienda_id'] = Variable<String>(tiendaId);
    map['tabla'] = Variable<String>(tabla);
    map['registro_id'] = Variable<String>(registroId);
    map['operacion'] = Variable<String>(operacion);
    map['intentos'] = Variable<int>(intentos);
    {
      map['creado_en'] = Variable<DateTime>(
        $ColaPendientesTable.$convertercreadoEn.toSql(creadoEn),
      );
    }
    return map;
  }

  ColaPendientesCompanion toCompanion(bool nullToAbsent) {
    return ColaPendientesCompanion(
      id: Value(id),
      tiendaId: Value(tiendaId),
      tabla: Value(tabla),
      registroId: Value(registroId),
      operacion: Value(operacion),
      intentos: Value(intentos),
      creadoEn: Value(creadoEn),
    );
  }

  factory EntradaCola.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntradaCola(
      id: serializer.fromJson<String>(json['id']),
      tiendaId: serializer.fromJson<String>(json['tiendaId']),
      tabla: serializer.fromJson<String>(json['tabla']),
      registroId: serializer.fromJson<String>(json['registroId']),
      operacion: serializer.fromJson<String>(json['operacion']),
      intentos: serializer.fromJson<int>(json['intentos']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tiendaId': serializer.toJson<String>(tiendaId),
      'tabla': serializer.toJson<String>(tabla),
      'registroId': serializer.toJson<String>(registroId),
      'operacion': serializer.toJson<String>(operacion),
      'intentos': serializer.toJson<int>(intentos),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  EntradaCola copyWith({
    String? id,
    String? tiendaId,
    String? tabla,
    String? registroId,
    String? operacion,
    int? intentos,
    DateTime? creadoEn,
  }) => EntradaCola(
    id: id ?? this.id,
    tiendaId: tiendaId ?? this.tiendaId,
    tabla: tabla ?? this.tabla,
    registroId: registroId ?? this.registroId,
    operacion: operacion ?? this.operacion,
    intentos: intentos ?? this.intentos,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  EntradaCola copyWithCompanion(ColaPendientesCompanion data) {
    return EntradaCola(
      id: data.id.present ? data.id.value : this.id,
      tiendaId: data.tiendaId.present ? data.tiendaId.value : this.tiendaId,
      tabla: data.tabla.present ? data.tabla.value : this.tabla,
      registroId: data.registroId.present
          ? data.registroId.value
          : this.registroId,
      operacion: data.operacion.present ? data.operacion.value : this.operacion,
      intentos: data.intentos.present ? data.intentos.value : this.intentos,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntradaCola(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('tabla: $tabla, ')
          ..write('registroId: $registroId, ')
          ..write('operacion: $operacion, ')
          ..write('intentos: $intentos, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tiendaId,
    tabla,
    registroId,
    operacion,
    intentos,
    creadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntradaCola &&
          other.id == this.id &&
          other.tiendaId == this.tiendaId &&
          other.tabla == this.tabla &&
          other.registroId == this.registroId &&
          other.operacion == this.operacion &&
          other.intentos == this.intentos &&
          other.creadoEn == this.creadoEn);
}

class ColaPendientesCompanion extends UpdateCompanion<EntradaCola> {
  final Value<String> id;
  final Value<String> tiendaId;
  final Value<String> tabla;
  final Value<String> registroId;
  final Value<String> operacion;
  final Value<int> intentos;
  final Value<DateTime> creadoEn;
  final Value<int> rowid;
  const ColaPendientesCompanion({
    this.id = const Value.absent(),
    this.tiendaId = const Value.absent(),
    this.tabla = const Value.absent(),
    this.registroId = const Value.absent(),
    this.operacion = const Value.absent(),
    this.intentos = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ColaPendientesCompanion.insert({
    required String id,
    required String tiendaId,
    required String tabla,
    required String registroId,
    required String operacion,
    this.intentos = const Value.absent(),
    required DateTime creadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tiendaId = Value(tiendaId),
       tabla = Value(tabla),
       registroId = Value(registroId),
       operacion = Value(operacion),
       creadoEn = Value(creadoEn);
  static Insertable<EntradaCola> custom({
    Expression<String>? id,
    Expression<String>? tiendaId,
    Expression<String>? tabla,
    Expression<String>? registroId,
    Expression<String>? operacion,
    Expression<int>? intentos,
    Expression<DateTime>? creadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tiendaId != null) 'tienda_id': tiendaId,
      if (tabla != null) 'tabla': tabla,
      if (registroId != null) 'registro_id': registroId,
      if (operacion != null) 'operacion': operacion,
      if (intentos != null) 'intentos': intentos,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ColaPendientesCompanion copyWith({
    Value<String>? id,
    Value<String>? tiendaId,
    Value<String>? tabla,
    Value<String>? registroId,
    Value<String>? operacion,
    Value<int>? intentos,
    Value<DateTime>? creadoEn,
    Value<int>? rowid,
  }) {
    return ColaPendientesCompanion(
      id: id ?? this.id,
      tiendaId: tiendaId ?? this.tiendaId,
      tabla: tabla ?? this.tabla,
      registroId: registroId ?? this.registroId,
      operacion: operacion ?? this.operacion,
      intentos: intentos ?? this.intentos,
      creadoEn: creadoEn ?? this.creadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tiendaId.present) {
      map['tienda_id'] = Variable<String>(tiendaId.value);
    }
    if (tabla.present) {
      map['tabla'] = Variable<String>(tabla.value);
    }
    if (registroId.present) {
      map['registro_id'] = Variable<String>(registroId.value);
    }
    if (operacion.present) {
      map['operacion'] = Variable<String>(operacion.value);
    }
    if (intentos.present) {
      map['intentos'] = Variable<int>(intentos.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(
        $ColaPendientesTable.$convertercreadoEn.toSql(creadoEn.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ColaPendientesCompanion(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('tabla: $tabla, ')
          ..write('registroId: $registroId, ')
          ..write('operacion: $operacion, ')
          ..write('intentos: $intentos, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductosTable extends Productos
    with TableInfo<$ProductosTable, FilaProducto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tiendaIdMeta = const VerificationMeta(
    'tiendaId',
  );
  @override
  late final GeneratedColumn<String> tiendaId = GeneratedColumn<String>(
    'tienda_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  @override
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
    'codigo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreNormalizadoMeta = const VerificationMeta(
    'nombreNormalizado',
  );
  @override
  late final GeneratedColumn<String> nombreNormalizado =
      GeneratedColumn<String>(
        'nombre_normalizado',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _unidadMedidaMeta = const VerificationMeta(
    'unidadMedida',
  );
  @override
  late final GeneratedColumn<String> unidadMedida = GeneratedColumn<String>(
    'unidad_medida',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String> precioCompra =
      GeneratedColumn<String>(
        'precio_compra',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Decimal?>($ProductosTable.$converterprecioCompran);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> precioVenta =
      GeneratedColumn<String>(
        'precio_venta',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($ProductosTable.$converterprecioVenta);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime>
  actualizadoEn = GeneratedColumn<DateTime>(
    'actualizado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($ProductosTable.$converteractualizadoEn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tiendaId,
    codigo,
    nombre,
    nombreNormalizado,
    unidadMedida,
    precioCompra,
    precioVenta,
    actualizadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'productos';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaProducto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tienda_id')) {
      context.handle(
        _tiendaIdMeta,
        tiendaId.isAcceptableOrUnknown(data['tienda_id']!, _tiendaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tiendaIdMeta);
    }
    if (data.containsKey('codigo')) {
      context.handle(
        _codigoMeta,
        codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta),
      );
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('nombre_normalizado')) {
      context.handle(
        _nombreNormalizadoMeta,
        nombreNormalizado.isAcceptableOrUnknown(
          data['nombre_normalizado']!,
          _nombreNormalizadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nombreNormalizadoMeta);
    }
    if (data.containsKey('unidad_medida')) {
      context.handle(
        _unidadMedidaMeta,
        unidadMedida.isAcceptableOrUnknown(
          data['unidad_medida']!,
          _unidadMedidaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unidadMedidaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaProducto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaProducto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tiendaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tienda_id'],
      )!,
      codigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      nombreNormalizado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_normalizado'],
      )!,
      unidadMedida: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unidad_medida'],
      )!,
      precioCompra: $ProductosTable.$converterprecioCompran.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}precio_compra'],
        ),
      ),
      precioVenta: $ProductosTable.$converterprecioVenta.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}precio_venta'],
        )!,
      ),
      actualizadoEn: $ProductosTable.$converteractualizadoEn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}actualizado_en'],
        )!,
      ),
    );
  }

  @override
  $ProductosTable createAlias(String alias) {
    return $ProductosTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterprecioCompra =
      const ConversorDecimal();
  static TypeConverter<Decimal?, String?> $converterprecioCompran =
      NullAwareTypeConverter.wrap($converterprecioCompra);
  static TypeConverter<Decimal, String> $converterprecioVenta =
      const ConversorDecimal();
  static TypeConverter<DateTime, DateTime> $converteractualizadoEn =
      const ConversorFechaUtc();
}

class FilaProducto extends DataClass implements Insertable<FilaProducto> {
  final String id;
  final String tiendaId;
  final String codigo;
  final String nombre;
  final String nombreNormalizado;
  final String unidadMedida;
  final Decimal? precioCompra;
  final Decimal precioVenta;
  final DateTime actualizadoEn;
  const FilaProducto({
    required this.id,
    required this.tiendaId,
    required this.codigo,
    required this.nombre,
    required this.nombreNormalizado,
    required this.unidadMedida,
    this.precioCompra,
    required this.precioVenta,
    required this.actualizadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tienda_id'] = Variable<String>(tiendaId);
    map['codigo'] = Variable<String>(codigo);
    map['nombre'] = Variable<String>(nombre);
    map['nombre_normalizado'] = Variable<String>(nombreNormalizado);
    map['unidad_medida'] = Variable<String>(unidadMedida);
    if (!nullToAbsent || precioCompra != null) {
      map['precio_compra'] = Variable<String>(
        $ProductosTable.$converterprecioCompran.toSql(precioCompra),
      );
    }
    {
      map['precio_venta'] = Variable<String>(
        $ProductosTable.$converterprecioVenta.toSql(precioVenta),
      );
    }
    {
      map['actualizado_en'] = Variable<DateTime>(
        $ProductosTable.$converteractualizadoEn.toSql(actualizadoEn),
      );
    }
    return map;
  }

  ProductosCompanion toCompanion(bool nullToAbsent) {
    return ProductosCompanion(
      id: Value(id),
      tiendaId: Value(tiendaId),
      codigo: Value(codigo),
      nombre: Value(nombre),
      nombreNormalizado: Value(nombreNormalizado),
      unidadMedida: Value(unidadMedida),
      precioCompra: precioCompra == null && nullToAbsent
          ? const Value.absent()
          : Value(precioCompra),
      precioVenta: Value(precioVenta),
      actualizadoEn: Value(actualizadoEn),
    );
  }

  factory FilaProducto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaProducto(
      id: serializer.fromJson<String>(json['id']),
      tiendaId: serializer.fromJson<String>(json['tiendaId']),
      codigo: serializer.fromJson<String>(json['codigo']),
      nombre: serializer.fromJson<String>(json['nombre']),
      nombreNormalizado: serializer.fromJson<String>(json['nombreNormalizado']),
      unidadMedida: serializer.fromJson<String>(json['unidadMedida']),
      precioCompra: serializer.fromJson<Decimal?>(json['precioCompra']),
      precioVenta: serializer.fromJson<Decimal>(json['precioVenta']),
      actualizadoEn: serializer.fromJson<DateTime>(json['actualizadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tiendaId': serializer.toJson<String>(tiendaId),
      'codigo': serializer.toJson<String>(codigo),
      'nombre': serializer.toJson<String>(nombre),
      'nombreNormalizado': serializer.toJson<String>(nombreNormalizado),
      'unidadMedida': serializer.toJson<String>(unidadMedida),
      'precioCompra': serializer.toJson<Decimal?>(precioCompra),
      'precioVenta': serializer.toJson<Decimal>(precioVenta),
      'actualizadoEn': serializer.toJson<DateTime>(actualizadoEn),
    };
  }

  FilaProducto copyWith({
    String? id,
    String? tiendaId,
    String? codigo,
    String? nombre,
    String? nombreNormalizado,
    String? unidadMedida,
    Value<Decimal?> precioCompra = const Value.absent(),
    Decimal? precioVenta,
    DateTime? actualizadoEn,
  }) => FilaProducto(
    id: id ?? this.id,
    tiendaId: tiendaId ?? this.tiendaId,
    codigo: codigo ?? this.codigo,
    nombre: nombre ?? this.nombre,
    nombreNormalizado: nombreNormalizado ?? this.nombreNormalizado,
    unidadMedida: unidadMedida ?? this.unidadMedida,
    precioCompra: precioCompra.present ? precioCompra.value : this.precioCompra,
    precioVenta: precioVenta ?? this.precioVenta,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
  );
  FilaProducto copyWithCompanion(ProductosCompanion data) {
    return FilaProducto(
      id: data.id.present ? data.id.value : this.id,
      tiendaId: data.tiendaId.present ? data.tiendaId.value : this.tiendaId,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      nombreNormalizado: data.nombreNormalizado.present
          ? data.nombreNormalizado.value
          : this.nombreNormalizado,
      unidadMedida: data.unidadMedida.present
          ? data.unidadMedida.value
          : this.unidadMedida,
      precioCompra: data.precioCompra.present
          ? data.precioCompra.value
          : this.precioCompra,
      precioVenta: data.precioVenta.present
          ? data.precioVenta.value
          : this.precioVenta,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaProducto(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('codigo: $codigo, ')
          ..write('nombre: $nombre, ')
          ..write('nombreNormalizado: $nombreNormalizado, ')
          ..write('unidadMedida: $unidadMedida, ')
          ..write('precioCompra: $precioCompra, ')
          ..write('precioVenta: $precioVenta, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tiendaId,
    codigo,
    nombre,
    nombreNormalizado,
    unidadMedida,
    precioCompra,
    precioVenta,
    actualizadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaProducto &&
          other.id == this.id &&
          other.tiendaId == this.tiendaId &&
          other.codigo == this.codigo &&
          other.nombre == this.nombre &&
          other.nombreNormalizado == this.nombreNormalizado &&
          other.unidadMedida == this.unidadMedida &&
          other.precioCompra == this.precioCompra &&
          other.precioVenta == this.precioVenta &&
          other.actualizadoEn == this.actualizadoEn);
}

class ProductosCompanion extends UpdateCompanion<FilaProducto> {
  final Value<String> id;
  final Value<String> tiendaId;
  final Value<String> codigo;
  final Value<String> nombre;
  final Value<String> nombreNormalizado;
  final Value<String> unidadMedida;
  final Value<Decimal?> precioCompra;
  final Value<Decimal> precioVenta;
  final Value<DateTime> actualizadoEn;
  final Value<int> rowid;
  const ProductosCompanion({
    this.id = const Value.absent(),
    this.tiendaId = const Value.absent(),
    this.codigo = const Value.absent(),
    this.nombre = const Value.absent(),
    this.nombreNormalizado = const Value.absent(),
    this.unidadMedida = const Value.absent(),
    this.precioCompra = const Value.absent(),
    this.precioVenta = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductosCompanion.insert({
    required String id,
    required String tiendaId,
    required String codigo,
    required String nombre,
    required String nombreNormalizado,
    required String unidadMedida,
    this.precioCompra = const Value.absent(),
    required Decimal precioVenta,
    required DateTime actualizadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tiendaId = Value(tiendaId),
       codigo = Value(codigo),
       nombre = Value(nombre),
       nombreNormalizado = Value(nombreNormalizado),
       unidadMedida = Value(unidadMedida),
       precioVenta = Value(precioVenta),
       actualizadoEn = Value(actualizadoEn);
  static Insertable<FilaProducto> custom({
    Expression<String>? id,
    Expression<String>? tiendaId,
    Expression<String>? codigo,
    Expression<String>? nombre,
    Expression<String>? nombreNormalizado,
    Expression<String>? unidadMedida,
    Expression<String>? precioCompra,
    Expression<String>? precioVenta,
    Expression<DateTime>? actualizadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tiendaId != null) 'tienda_id': tiendaId,
      if (codigo != null) 'codigo': codigo,
      if (nombre != null) 'nombre': nombre,
      if (nombreNormalizado != null) 'nombre_normalizado': nombreNormalizado,
      if (unidadMedida != null) 'unidad_medida': unidadMedida,
      if (precioCompra != null) 'precio_compra': precioCompra,
      if (precioVenta != null) 'precio_venta': precioVenta,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductosCompanion copyWith({
    Value<String>? id,
    Value<String>? tiendaId,
    Value<String>? codigo,
    Value<String>? nombre,
    Value<String>? nombreNormalizado,
    Value<String>? unidadMedida,
    Value<Decimal?>? precioCompra,
    Value<Decimal>? precioVenta,
    Value<DateTime>? actualizadoEn,
    Value<int>? rowid,
  }) {
    return ProductosCompanion(
      id: id ?? this.id,
      tiendaId: tiendaId ?? this.tiendaId,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      nombreNormalizado: nombreNormalizado ?? this.nombreNormalizado,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tiendaId.present) {
      map['tienda_id'] = Variable<String>(tiendaId.value);
    }
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (nombreNormalizado.present) {
      map['nombre_normalizado'] = Variable<String>(nombreNormalizado.value);
    }
    if (unidadMedida.present) {
      map['unidad_medida'] = Variable<String>(unidadMedida.value);
    }
    if (precioCompra.present) {
      map['precio_compra'] = Variable<String>(
        $ProductosTable.$converterprecioCompran.toSql(precioCompra.value),
      );
    }
    if (precioVenta.present) {
      map['precio_venta'] = Variable<String>(
        $ProductosTable.$converterprecioVenta.toSql(precioVenta.value),
      );
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<DateTime>(
        $ProductosTable.$converteractualizadoEn.toSql(actualizadoEn.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductosCompanion(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('codigo: $codigo, ')
          ..write('nombre: $nombre, ')
          ..write('nombreNormalizado: $nombreNormalizado, ')
          ..write('unidadMedida: $unidadMedida, ')
          ..write('precioCompra: $precioCompra, ')
          ..write('precioVenta: $precioVenta, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemsInventarioTable extends ItemsInventario
    with TableInfo<$ItemsInventarioTable, FilaItemInventario> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsInventarioTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tiendaIdMeta = const VerificationMeta(
    'tiendaId',
  );
  @override
  late final GeneratedColumn<String> tiendaId = GeneratedColumn<String>(
    'tienda_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productoIdMeta = const VerificationMeta(
    'productoId',
  );
  @override
  late final GeneratedColumn<String> productoId = GeneratedColumn<String>(
    'producto_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES productos (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> stockActual =
      GeneratedColumn<String>(
        'stock_actual',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($ItemsInventarioTable.$converterstockActual);
  @override
  List<GeneratedColumn> get $columns => [id, tiendaId, productoId, stockActual];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items_inventario';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaItemInventario> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tienda_id')) {
      context.handle(
        _tiendaIdMeta,
        tiendaId.isAcceptableOrUnknown(data['tienda_id']!, _tiendaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tiendaIdMeta);
    }
    if (data.containsKey('producto_id')) {
      context.handle(
        _productoIdMeta,
        productoId.isAcceptableOrUnknown(data['producto_id']!, _productoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productoIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {tiendaId, productoId},
  ];
  @override
  FilaItemInventario map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaItemInventario(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tiendaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tienda_id'],
      )!,
      productoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}producto_id'],
      )!,
      stockActual: $ItemsInventarioTable.$converterstockActual.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}stock_actual'],
        )!,
      ),
    );
  }

  @override
  $ItemsInventarioTable createAlias(String alias) {
    return $ItemsInventarioTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterstockActual =
      const ConversorDecimal();
}

class FilaItemInventario extends DataClass
    implements Insertable<FilaItemInventario> {
  final String id;
  final String tiendaId;
  final String productoId;
  final Decimal stockActual;
  const FilaItemInventario({
    required this.id,
    required this.tiendaId,
    required this.productoId,
    required this.stockActual,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tienda_id'] = Variable<String>(tiendaId);
    map['producto_id'] = Variable<String>(productoId);
    {
      map['stock_actual'] = Variable<String>(
        $ItemsInventarioTable.$converterstockActual.toSql(stockActual),
      );
    }
    return map;
  }

  ItemsInventarioCompanion toCompanion(bool nullToAbsent) {
    return ItemsInventarioCompanion(
      id: Value(id),
      tiendaId: Value(tiendaId),
      productoId: Value(productoId),
      stockActual: Value(stockActual),
    );
  }

  factory FilaItemInventario.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaItemInventario(
      id: serializer.fromJson<String>(json['id']),
      tiendaId: serializer.fromJson<String>(json['tiendaId']),
      productoId: serializer.fromJson<String>(json['productoId']),
      stockActual: serializer.fromJson<Decimal>(json['stockActual']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tiendaId': serializer.toJson<String>(tiendaId),
      'productoId': serializer.toJson<String>(productoId),
      'stockActual': serializer.toJson<Decimal>(stockActual),
    };
  }

  FilaItemInventario copyWith({
    String? id,
    String? tiendaId,
    String? productoId,
    Decimal? stockActual,
  }) => FilaItemInventario(
    id: id ?? this.id,
    tiendaId: tiendaId ?? this.tiendaId,
    productoId: productoId ?? this.productoId,
    stockActual: stockActual ?? this.stockActual,
  );
  FilaItemInventario copyWithCompanion(ItemsInventarioCompanion data) {
    return FilaItemInventario(
      id: data.id.present ? data.id.value : this.id,
      tiendaId: data.tiendaId.present ? data.tiendaId.value : this.tiendaId,
      productoId: data.productoId.present
          ? data.productoId.value
          : this.productoId,
      stockActual: data.stockActual.present
          ? data.stockActual.value
          : this.stockActual,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaItemInventario(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('productoId: $productoId, ')
          ..write('stockActual: $stockActual')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tiendaId, productoId, stockActual);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaItemInventario &&
          other.id == this.id &&
          other.tiendaId == this.tiendaId &&
          other.productoId == this.productoId &&
          other.stockActual == this.stockActual);
}

class ItemsInventarioCompanion extends UpdateCompanion<FilaItemInventario> {
  final Value<String> id;
  final Value<String> tiendaId;
  final Value<String> productoId;
  final Value<Decimal> stockActual;
  final Value<int> rowid;
  const ItemsInventarioCompanion({
    this.id = const Value.absent(),
    this.tiendaId = const Value.absent(),
    this.productoId = const Value.absent(),
    this.stockActual = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsInventarioCompanion.insert({
    required String id,
    required String tiendaId,
    required String productoId,
    required Decimal stockActual,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tiendaId = Value(tiendaId),
       productoId = Value(productoId),
       stockActual = Value(stockActual);
  static Insertable<FilaItemInventario> custom({
    Expression<String>? id,
    Expression<String>? tiendaId,
    Expression<String>? productoId,
    Expression<String>? stockActual,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tiendaId != null) 'tienda_id': tiendaId,
      if (productoId != null) 'producto_id': productoId,
      if (stockActual != null) 'stock_actual': stockActual,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsInventarioCompanion copyWith({
    Value<String>? id,
    Value<String>? tiendaId,
    Value<String>? productoId,
    Value<Decimal>? stockActual,
    Value<int>? rowid,
  }) {
    return ItemsInventarioCompanion(
      id: id ?? this.id,
      tiendaId: tiendaId ?? this.tiendaId,
      productoId: productoId ?? this.productoId,
      stockActual: stockActual ?? this.stockActual,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tiendaId.present) {
      map['tienda_id'] = Variable<String>(tiendaId.value);
    }
    if (productoId.present) {
      map['producto_id'] = Variable<String>(productoId.value);
    }
    if (stockActual.present) {
      map['stock_actual'] = Variable<String>(
        $ItemsInventarioTable.$converterstockActual.toSql(stockActual.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsInventarioCompanion(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('productoId: $productoId, ')
          ..write('stockActual: $stockActual, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VentasTable extends Ventas with TableInfo<$VentasTable, FilaVenta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VentasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tiendaIdMeta = const VerificationMeta(
    'tiendaId',
  );
  @override
  late final GeneratedColumn<String> tiendaId = GeneratedColumn<String>(
    'tienda_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> fecha =
      GeneratedColumn<DateTime>(
        'fecha',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($VentasTable.$converterfecha);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> total =
      GeneratedColumn<String>(
        'total',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($VentasTable.$convertertotal);
  @override
  List<GeneratedColumn> get $columns => [id, tiendaId, fecha, total];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ventas';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaVenta> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tienda_id')) {
      context.handle(
        _tiendaIdMeta,
        tiendaId.isAcceptableOrUnknown(data['tienda_id']!, _tiendaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tiendaIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaVenta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaVenta(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tiendaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tienda_id'],
      )!,
      fecha: $VentasTable.$converterfecha.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}fecha'],
        )!,
      ),
      total: $VentasTable.$convertertotal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}total'],
        )!,
      ),
    );
  }

  @override
  $VentasTable createAlias(String alias) {
    return $VentasTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterfecha =
      const ConversorFechaUtc();
  static TypeConverter<Decimal, String> $convertertotal =
      const ConversorDecimal();
}

class FilaVenta extends DataClass implements Insertable<FilaVenta> {
  final String id;
  final String tiendaId;
  final DateTime fecha;
  final Decimal total;
  const FilaVenta({
    required this.id,
    required this.tiendaId,
    required this.fecha,
    required this.total,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tienda_id'] = Variable<String>(tiendaId);
    {
      map['fecha'] = Variable<DateTime>(
        $VentasTable.$converterfecha.toSql(fecha),
      );
    }
    {
      map['total'] = Variable<String>(
        $VentasTable.$convertertotal.toSql(total),
      );
    }
    return map;
  }

  VentasCompanion toCompanion(bool nullToAbsent) {
    return VentasCompanion(
      id: Value(id),
      tiendaId: Value(tiendaId),
      fecha: Value(fecha),
      total: Value(total),
    );
  }

  factory FilaVenta.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaVenta(
      id: serializer.fromJson<String>(json['id']),
      tiendaId: serializer.fromJson<String>(json['tiendaId']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      total: serializer.fromJson<Decimal>(json['total']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tiendaId': serializer.toJson<String>(tiendaId),
      'fecha': serializer.toJson<DateTime>(fecha),
      'total': serializer.toJson<Decimal>(total),
    };
  }

  FilaVenta copyWith({
    String? id,
    String? tiendaId,
    DateTime? fecha,
    Decimal? total,
  }) => FilaVenta(
    id: id ?? this.id,
    tiendaId: tiendaId ?? this.tiendaId,
    fecha: fecha ?? this.fecha,
    total: total ?? this.total,
  );
  FilaVenta copyWithCompanion(VentasCompanion data) {
    return FilaVenta(
      id: data.id.present ? data.id.value : this.id,
      tiendaId: data.tiendaId.present ? data.tiendaId.value : this.tiendaId,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      total: data.total.present ? data.total.value : this.total,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaVenta(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('fecha: $fecha, ')
          ..write('total: $total')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tiendaId, fecha, total);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaVenta &&
          other.id == this.id &&
          other.tiendaId == this.tiendaId &&
          other.fecha == this.fecha &&
          other.total == this.total);
}

class VentasCompanion extends UpdateCompanion<FilaVenta> {
  final Value<String> id;
  final Value<String> tiendaId;
  final Value<DateTime> fecha;
  final Value<Decimal> total;
  final Value<int> rowid;
  const VentasCompanion({
    this.id = const Value.absent(),
    this.tiendaId = const Value.absent(),
    this.fecha = const Value.absent(),
    this.total = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VentasCompanion.insert({
    required String id,
    required String tiendaId,
    required DateTime fecha,
    required Decimal total,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tiendaId = Value(tiendaId),
       fecha = Value(fecha),
       total = Value(total);
  static Insertable<FilaVenta> custom({
    Expression<String>? id,
    Expression<String>? tiendaId,
    Expression<DateTime>? fecha,
    Expression<String>? total,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tiendaId != null) 'tienda_id': tiendaId,
      if (fecha != null) 'fecha': fecha,
      if (total != null) 'total': total,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VentasCompanion copyWith({
    Value<String>? id,
    Value<String>? tiendaId,
    Value<DateTime>? fecha,
    Value<Decimal>? total,
    Value<int>? rowid,
  }) {
    return VentasCompanion(
      id: id ?? this.id,
      tiendaId: tiendaId ?? this.tiendaId,
      fecha: fecha ?? this.fecha,
      total: total ?? this.total,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tiendaId.present) {
      map['tienda_id'] = Variable<String>(tiendaId.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(
        $VentasTable.$converterfecha.toSql(fecha.value),
      );
    }
    if (total.present) {
      map['total'] = Variable<String>(
        $VentasTable.$convertertotal.toSql(total.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VentasCompanion(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('fecha: $fecha, ')
          ..write('total: $total, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MovimientosInventarioTable extends MovimientosInventario
    with TableInfo<$MovimientosInventarioTable, FilaMovimientoInventario> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovimientosInventarioTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tiendaIdMeta = const VerificationMeta(
    'tiendaId',
  );
  @override
  late final GeneratedColumn<String> tiendaId = GeneratedColumn<String>(
    'tienda_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items_inventario (id)',
    ),
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> cantidad =
      GeneratedColumn<String>(
        'cantidad',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($MovimientosInventarioTable.$convertercantidad);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> fecha =
      GeneratedColumn<DateTime>(
        'fecha',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($MovimientosInventarioTable.$converterfecha);
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String> costoUnitario =
      GeneratedColumn<String>(
        'costo_unitario',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Decimal?>(
        $MovimientosInventarioTable.$convertercostoUnitarion,
      );
  static const VerificationMeta _numeroFacturaMeta = const VerificationMeta(
    'numeroFactura',
  );
  @override
  late final GeneratedColumn<String> numeroFactura = GeneratedColumn<String>(
    'numero_factura',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ventaIdMeta = const VerificationMeta(
    'ventaId',
  );
  @override
  late final GeneratedColumn<String> ventaId = GeneratedColumn<String>(
    'venta_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ventas (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String> precioUnitario =
      GeneratedColumn<String>(
        'precio_unitario',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Decimal?>(
        $MovimientosInventarioTable.$converterprecioUnitarion,
      );
  static const VerificationMeta _motivoMeta = const VerificationMeta('motivo');
  @override
  late final GeneratedColumn<String> motivo = GeneratedColumn<String>(
    'motivo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String>
  cantidadContada =
      GeneratedColumn<String>(
        'cantidad_contada',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Decimal?>(
        $MovimientosInventarioTable.$convertercantidadContadan,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tiendaId,
    itemId,
    tipo,
    cantidad,
    fecha,
    estado,
    costoUnitario,
    numeroFactura,
    ventaId,
    precioUnitario,
    motivo,
    cantidadContada,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movimientos_inventario';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaMovimientoInventario> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tienda_id')) {
      context.handle(
        _tiendaIdMeta,
        tiendaId.isAcceptableOrUnknown(data['tienda_id']!, _tiendaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tiendaIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    } else if (isInserting) {
      context.missing(_estadoMeta);
    }
    if (data.containsKey('numero_factura')) {
      context.handle(
        _numeroFacturaMeta,
        numeroFactura.isAcceptableOrUnknown(
          data['numero_factura']!,
          _numeroFacturaMeta,
        ),
      );
    }
    if (data.containsKey('venta_id')) {
      context.handle(
        _ventaIdMeta,
        ventaId.isAcceptableOrUnknown(data['venta_id']!, _ventaIdMeta),
      );
    }
    if (data.containsKey('motivo')) {
      context.handle(
        _motivoMeta,
        motivo.isAcceptableOrUnknown(data['motivo']!, _motivoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaMovimientoInventario map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaMovimientoInventario(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tiendaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tienda_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      cantidad: $MovimientosInventarioTable.$convertercantidad.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cantidad'],
        )!,
      ),
      fecha: $MovimientosInventarioTable.$converterfecha.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}fecha'],
        )!,
      ),
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      costoUnitario: $MovimientosInventarioTable.$convertercostoUnitarion
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}costo_unitario'],
            ),
          ),
      numeroFactura: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numero_factura'],
      ),
      ventaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venta_id'],
      ),
      precioUnitario: $MovimientosInventarioTable.$converterprecioUnitarion
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}precio_unitario'],
            ),
          ),
      motivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motivo'],
      ),
      cantidadContada: $MovimientosInventarioTable.$convertercantidadContadan
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}cantidad_contada'],
            ),
          ),
    );
  }

  @override
  $MovimientosInventarioTable createAlias(String alias) {
    return $MovimientosInventarioTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $convertercantidad =
      const ConversorDecimal();
  static TypeConverter<DateTime, DateTime> $converterfecha =
      const ConversorFechaUtc();
  static TypeConverter<Decimal, String> $convertercostoUnitario =
      const ConversorDecimal();
  static TypeConverter<Decimal?, String?> $convertercostoUnitarion =
      NullAwareTypeConverter.wrap($convertercostoUnitario);
  static TypeConverter<Decimal, String> $converterprecioUnitario =
      const ConversorDecimal();
  static TypeConverter<Decimal?, String?> $converterprecioUnitarion =
      NullAwareTypeConverter.wrap($converterprecioUnitario);
  static TypeConverter<Decimal, String> $convertercantidadContada =
      const ConversorDecimal();
  static TypeConverter<Decimal?, String?> $convertercantidadContadan =
      NullAwareTypeConverter.wrap($convertercantidadContada);
}

class FilaMovimientoInventario extends DataClass
    implements Insertable<FilaMovimientoInventario> {
  final String id;
  final String tiendaId;
  final String itemId;
  final String tipo;
  final Decimal cantidad;
  final DateTime fecha;
  final String estado;
  final Decimal? costoUnitario;
  final String? numeroFactura;
  final String? ventaId;
  final Decimal? precioUnitario;
  final String? motivo;
  final Decimal? cantidadContada;
  const FilaMovimientoInventario({
    required this.id,
    required this.tiendaId,
    required this.itemId,
    required this.tipo,
    required this.cantidad,
    required this.fecha,
    required this.estado,
    this.costoUnitario,
    this.numeroFactura,
    this.ventaId,
    this.precioUnitario,
    this.motivo,
    this.cantidadContada,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tienda_id'] = Variable<String>(tiendaId);
    map['item_id'] = Variable<String>(itemId);
    map['tipo'] = Variable<String>(tipo);
    {
      map['cantidad'] = Variable<String>(
        $MovimientosInventarioTable.$convertercantidad.toSql(cantidad),
      );
    }
    {
      map['fecha'] = Variable<DateTime>(
        $MovimientosInventarioTable.$converterfecha.toSql(fecha),
      );
    }
    map['estado'] = Variable<String>(estado);
    if (!nullToAbsent || costoUnitario != null) {
      map['costo_unitario'] = Variable<String>(
        $MovimientosInventarioTable.$convertercostoUnitarion.toSql(
          costoUnitario,
        ),
      );
    }
    if (!nullToAbsent || numeroFactura != null) {
      map['numero_factura'] = Variable<String>(numeroFactura);
    }
    if (!nullToAbsent || ventaId != null) {
      map['venta_id'] = Variable<String>(ventaId);
    }
    if (!nullToAbsent || precioUnitario != null) {
      map['precio_unitario'] = Variable<String>(
        $MovimientosInventarioTable.$converterprecioUnitarion.toSql(
          precioUnitario,
        ),
      );
    }
    if (!nullToAbsent || motivo != null) {
      map['motivo'] = Variable<String>(motivo);
    }
    if (!nullToAbsent || cantidadContada != null) {
      map['cantidad_contada'] = Variable<String>(
        $MovimientosInventarioTable.$convertercantidadContadan.toSql(
          cantidadContada,
        ),
      );
    }
    return map;
  }

  MovimientosInventarioCompanion toCompanion(bool nullToAbsent) {
    return MovimientosInventarioCompanion(
      id: Value(id),
      tiendaId: Value(tiendaId),
      itemId: Value(itemId),
      tipo: Value(tipo),
      cantidad: Value(cantidad),
      fecha: Value(fecha),
      estado: Value(estado),
      costoUnitario: costoUnitario == null && nullToAbsent
          ? const Value.absent()
          : Value(costoUnitario),
      numeroFactura: numeroFactura == null && nullToAbsent
          ? const Value.absent()
          : Value(numeroFactura),
      ventaId: ventaId == null && nullToAbsent
          ? const Value.absent()
          : Value(ventaId),
      precioUnitario: precioUnitario == null && nullToAbsent
          ? const Value.absent()
          : Value(precioUnitario),
      motivo: motivo == null && nullToAbsent
          ? const Value.absent()
          : Value(motivo),
      cantidadContada: cantidadContada == null && nullToAbsent
          ? const Value.absent()
          : Value(cantidadContada),
    );
  }

  factory FilaMovimientoInventario.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaMovimientoInventario(
      id: serializer.fromJson<String>(json['id']),
      tiendaId: serializer.fromJson<String>(json['tiendaId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      cantidad: serializer.fromJson<Decimal>(json['cantidad']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      estado: serializer.fromJson<String>(json['estado']),
      costoUnitario: serializer.fromJson<Decimal?>(json['costoUnitario']),
      numeroFactura: serializer.fromJson<String?>(json['numeroFactura']),
      ventaId: serializer.fromJson<String?>(json['ventaId']),
      precioUnitario: serializer.fromJson<Decimal?>(json['precioUnitario']),
      motivo: serializer.fromJson<String?>(json['motivo']),
      cantidadContada: serializer.fromJson<Decimal?>(json['cantidadContada']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tiendaId': serializer.toJson<String>(tiendaId),
      'itemId': serializer.toJson<String>(itemId),
      'tipo': serializer.toJson<String>(tipo),
      'cantidad': serializer.toJson<Decimal>(cantidad),
      'fecha': serializer.toJson<DateTime>(fecha),
      'estado': serializer.toJson<String>(estado),
      'costoUnitario': serializer.toJson<Decimal?>(costoUnitario),
      'numeroFactura': serializer.toJson<String?>(numeroFactura),
      'ventaId': serializer.toJson<String?>(ventaId),
      'precioUnitario': serializer.toJson<Decimal?>(precioUnitario),
      'motivo': serializer.toJson<String?>(motivo),
      'cantidadContada': serializer.toJson<Decimal?>(cantidadContada),
    };
  }

  FilaMovimientoInventario copyWith({
    String? id,
    String? tiendaId,
    String? itemId,
    String? tipo,
    Decimal? cantidad,
    DateTime? fecha,
    String? estado,
    Value<Decimal?> costoUnitario = const Value.absent(),
    Value<String?> numeroFactura = const Value.absent(),
    Value<String?> ventaId = const Value.absent(),
    Value<Decimal?> precioUnitario = const Value.absent(),
    Value<String?> motivo = const Value.absent(),
    Value<Decimal?> cantidadContada = const Value.absent(),
  }) => FilaMovimientoInventario(
    id: id ?? this.id,
    tiendaId: tiendaId ?? this.tiendaId,
    itemId: itemId ?? this.itemId,
    tipo: tipo ?? this.tipo,
    cantidad: cantidad ?? this.cantidad,
    fecha: fecha ?? this.fecha,
    estado: estado ?? this.estado,
    costoUnitario: costoUnitario.present
        ? costoUnitario.value
        : this.costoUnitario,
    numeroFactura: numeroFactura.present
        ? numeroFactura.value
        : this.numeroFactura,
    ventaId: ventaId.present ? ventaId.value : this.ventaId,
    precioUnitario: precioUnitario.present
        ? precioUnitario.value
        : this.precioUnitario,
    motivo: motivo.present ? motivo.value : this.motivo,
    cantidadContada: cantidadContada.present
        ? cantidadContada.value
        : this.cantidadContada,
  );
  FilaMovimientoInventario copyWithCompanion(
    MovimientosInventarioCompanion data,
  ) {
    return FilaMovimientoInventario(
      id: data.id.present ? data.id.value : this.id,
      tiendaId: data.tiendaId.present ? data.tiendaId.value : this.tiendaId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      cantidad: data.cantidad.present ? data.cantidad.value : this.cantidad,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      estado: data.estado.present ? data.estado.value : this.estado,
      costoUnitario: data.costoUnitario.present
          ? data.costoUnitario.value
          : this.costoUnitario,
      numeroFactura: data.numeroFactura.present
          ? data.numeroFactura.value
          : this.numeroFactura,
      ventaId: data.ventaId.present ? data.ventaId.value : this.ventaId,
      precioUnitario: data.precioUnitario.present
          ? data.precioUnitario.value
          : this.precioUnitario,
      motivo: data.motivo.present ? data.motivo.value : this.motivo,
      cantidadContada: data.cantidadContada.present
          ? data.cantidadContada.value
          : this.cantidadContada,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaMovimientoInventario(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('itemId: $itemId, ')
          ..write('tipo: $tipo, ')
          ..write('cantidad: $cantidad, ')
          ..write('fecha: $fecha, ')
          ..write('estado: $estado, ')
          ..write('costoUnitario: $costoUnitario, ')
          ..write('numeroFactura: $numeroFactura, ')
          ..write('ventaId: $ventaId, ')
          ..write('precioUnitario: $precioUnitario, ')
          ..write('motivo: $motivo, ')
          ..write('cantidadContada: $cantidadContada')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tiendaId,
    itemId,
    tipo,
    cantidad,
    fecha,
    estado,
    costoUnitario,
    numeroFactura,
    ventaId,
    precioUnitario,
    motivo,
    cantidadContada,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaMovimientoInventario &&
          other.id == this.id &&
          other.tiendaId == this.tiendaId &&
          other.itemId == this.itemId &&
          other.tipo == this.tipo &&
          other.cantidad == this.cantidad &&
          other.fecha == this.fecha &&
          other.estado == this.estado &&
          other.costoUnitario == this.costoUnitario &&
          other.numeroFactura == this.numeroFactura &&
          other.ventaId == this.ventaId &&
          other.precioUnitario == this.precioUnitario &&
          other.motivo == this.motivo &&
          other.cantidadContada == this.cantidadContada);
}

class MovimientosInventarioCompanion
    extends UpdateCompanion<FilaMovimientoInventario> {
  final Value<String> id;
  final Value<String> tiendaId;
  final Value<String> itemId;
  final Value<String> tipo;
  final Value<Decimal> cantidad;
  final Value<DateTime> fecha;
  final Value<String> estado;
  final Value<Decimal?> costoUnitario;
  final Value<String?> numeroFactura;
  final Value<String?> ventaId;
  final Value<Decimal?> precioUnitario;
  final Value<String?> motivo;
  final Value<Decimal?> cantidadContada;
  final Value<int> rowid;
  const MovimientosInventarioCompanion({
    this.id = const Value.absent(),
    this.tiendaId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.fecha = const Value.absent(),
    this.estado = const Value.absent(),
    this.costoUnitario = const Value.absent(),
    this.numeroFactura = const Value.absent(),
    this.ventaId = const Value.absent(),
    this.precioUnitario = const Value.absent(),
    this.motivo = const Value.absent(),
    this.cantidadContada = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MovimientosInventarioCompanion.insert({
    required String id,
    required String tiendaId,
    required String itemId,
    required String tipo,
    required Decimal cantidad,
    required DateTime fecha,
    required String estado,
    this.costoUnitario = const Value.absent(),
    this.numeroFactura = const Value.absent(),
    this.ventaId = const Value.absent(),
    this.precioUnitario = const Value.absent(),
    this.motivo = const Value.absent(),
    this.cantidadContada = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tiendaId = Value(tiendaId),
       itemId = Value(itemId),
       tipo = Value(tipo),
       cantidad = Value(cantidad),
       fecha = Value(fecha),
       estado = Value(estado);
  static Insertable<FilaMovimientoInventario> custom({
    Expression<String>? id,
    Expression<String>? tiendaId,
    Expression<String>? itemId,
    Expression<String>? tipo,
    Expression<String>? cantidad,
    Expression<DateTime>? fecha,
    Expression<String>? estado,
    Expression<String>? costoUnitario,
    Expression<String>? numeroFactura,
    Expression<String>? ventaId,
    Expression<String>? precioUnitario,
    Expression<String>? motivo,
    Expression<String>? cantidadContada,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tiendaId != null) 'tienda_id': tiendaId,
      if (itemId != null) 'item_id': itemId,
      if (tipo != null) 'tipo': tipo,
      if (cantidad != null) 'cantidad': cantidad,
      if (fecha != null) 'fecha': fecha,
      if (estado != null) 'estado': estado,
      if (costoUnitario != null) 'costo_unitario': costoUnitario,
      if (numeroFactura != null) 'numero_factura': numeroFactura,
      if (ventaId != null) 'venta_id': ventaId,
      if (precioUnitario != null) 'precio_unitario': precioUnitario,
      if (motivo != null) 'motivo': motivo,
      if (cantidadContada != null) 'cantidad_contada': cantidadContada,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MovimientosInventarioCompanion copyWith({
    Value<String>? id,
    Value<String>? tiendaId,
    Value<String>? itemId,
    Value<String>? tipo,
    Value<Decimal>? cantidad,
    Value<DateTime>? fecha,
    Value<String>? estado,
    Value<Decimal?>? costoUnitario,
    Value<String?>? numeroFactura,
    Value<String?>? ventaId,
    Value<Decimal?>? precioUnitario,
    Value<String?>? motivo,
    Value<Decimal?>? cantidadContada,
    Value<int>? rowid,
  }) {
    return MovimientosInventarioCompanion(
      id: id ?? this.id,
      tiendaId: tiendaId ?? this.tiendaId,
      itemId: itemId ?? this.itemId,
      tipo: tipo ?? this.tipo,
      cantidad: cantidad ?? this.cantidad,
      fecha: fecha ?? this.fecha,
      estado: estado ?? this.estado,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      numeroFactura: numeroFactura ?? this.numeroFactura,
      ventaId: ventaId ?? this.ventaId,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      motivo: motivo ?? this.motivo,
      cantidadContada: cantidadContada ?? this.cantidadContada,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tiendaId.present) {
      map['tienda_id'] = Variable<String>(tiendaId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (cantidad.present) {
      map['cantidad'] = Variable<String>(
        $MovimientosInventarioTable.$convertercantidad.toSql(cantidad.value),
      );
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(
        $MovimientosInventarioTable.$converterfecha.toSql(fecha.value),
      );
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (costoUnitario.present) {
      map['costo_unitario'] = Variable<String>(
        $MovimientosInventarioTable.$convertercostoUnitarion.toSql(
          costoUnitario.value,
        ),
      );
    }
    if (numeroFactura.present) {
      map['numero_factura'] = Variable<String>(numeroFactura.value);
    }
    if (ventaId.present) {
      map['venta_id'] = Variable<String>(ventaId.value);
    }
    if (precioUnitario.present) {
      map['precio_unitario'] = Variable<String>(
        $MovimientosInventarioTable.$converterprecioUnitarion.toSql(
          precioUnitario.value,
        ),
      );
    }
    if (motivo.present) {
      map['motivo'] = Variable<String>(motivo.value);
    }
    if (cantidadContada.present) {
      map['cantidad_contada'] = Variable<String>(
        $MovimientosInventarioTable.$convertercantidadContadan.toSql(
          cantidadContada.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovimientosInventarioCompanion(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('itemId: $itemId, ')
          ..write('tipo: $tipo, ')
          ..write('cantidad: $cantidad, ')
          ..write('fecha: $fecha, ')
          ..write('estado: $estado, ')
          ..write('costoUnitario: $costoUnitario, ')
          ..write('numeroFactura: $numeroFactura, ')
          ..write('ventaId: $ventaId, ')
          ..write('precioUnitario: $precioUnitario, ')
          ..write('motivo: $motivo, ')
          ..write('cantidadContada: $cantidadContada, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CajasTable extends Cajas with TableInfo<$CajasTable, FilaCaja> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CajasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tiendaIdMeta = const VerificationMeta(
    'tiendaId',
  );
  @override
  late final GeneratedColumn<String> tiendaId = GeneratedColumn<String>(
    'tienda_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, tiendaId, fecha];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cajas';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaCaja> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tienda_id')) {
      context.handle(
        _tiendaIdMeta,
        tiendaId.isAcceptableOrUnknown(data['tienda_id']!, _tiendaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tiendaIdMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaCaja map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaCaja(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tiendaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tienda_id'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha'],
      )!,
    );
  }

  @override
  $CajasTable createAlias(String alias) {
    return $CajasTable(attachedDatabase, alias);
  }
}

class FilaCaja extends DataClass implements Insertable<FilaCaja> {
  final String id;
  final String tiendaId;
  final String fecha;
  const FilaCaja({
    required this.id,
    required this.tiendaId,
    required this.fecha,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tienda_id'] = Variable<String>(tiendaId);
    map['fecha'] = Variable<String>(fecha);
    return map;
  }

  CajasCompanion toCompanion(bool nullToAbsent) {
    return CajasCompanion(
      id: Value(id),
      tiendaId: Value(tiendaId),
      fecha: Value(fecha),
    );
  }

  factory FilaCaja.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaCaja(
      id: serializer.fromJson<String>(json['id']),
      tiendaId: serializer.fromJson<String>(json['tiendaId']),
      fecha: serializer.fromJson<String>(json['fecha']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tiendaId': serializer.toJson<String>(tiendaId),
      'fecha': serializer.toJson<String>(fecha),
    };
  }

  FilaCaja copyWith({String? id, String? tiendaId, String? fecha}) => FilaCaja(
    id: id ?? this.id,
    tiendaId: tiendaId ?? this.tiendaId,
    fecha: fecha ?? this.fecha,
  );
  FilaCaja copyWithCompanion(CajasCompanion data) {
    return FilaCaja(
      id: data.id.present ? data.id.value : this.id,
      tiendaId: data.tiendaId.present ? data.tiendaId.value : this.tiendaId,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaCaja(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('fecha: $fecha')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tiendaId, fecha);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaCaja &&
          other.id == this.id &&
          other.tiendaId == this.tiendaId &&
          other.fecha == this.fecha);
}

class CajasCompanion extends UpdateCompanion<FilaCaja> {
  final Value<String> id;
  final Value<String> tiendaId;
  final Value<String> fecha;
  final Value<int> rowid;
  const CajasCompanion({
    this.id = const Value.absent(),
    this.tiendaId = const Value.absent(),
    this.fecha = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CajasCompanion.insert({
    required String id,
    required String tiendaId,
    required String fecha,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tiendaId = Value(tiendaId),
       fecha = Value(fecha);
  static Insertable<FilaCaja> custom({
    Expression<String>? id,
    Expression<String>? tiendaId,
    Expression<String>? fecha,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tiendaId != null) 'tienda_id': tiendaId,
      if (fecha != null) 'fecha': fecha,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CajasCompanion copyWith({
    Value<String>? id,
    Value<String>? tiendaId,
    Value<String>? fecha,
    Value<int>? rowid,
  }) {
    return CajasCompanion(
      id: id ?? this.id,
      tiendaId: tiendaId ?? this.tiendaId,
      fecha: fecha ?? this.fecha,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tiendaId.present) {
      map['tienda_id'] = Variable<String>(tiendaId.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CajasCompanion(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('fecha: $fecha, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MovimientosCajaTable extends MovimientosCaja
    with TableInfo<$MovimientosCajaTable, FilaMovimientoCaja> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovimientosCajaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tiendaIdMeta = const VerificationMeta(
    'tiendaId',
  );
  @override
  late final GeneratedColumn<String> tiendaId = GeneratedColumn<String>(
    'tienda_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cajaIdMeta = const VerificationMeta('cajaId');
  @override
  late final GeneratedColumn<String> cajaId = GeneratedColumn<String>(
    'caja_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cajas (id)',
    ),
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clasificacionMeta = const VerificationMeta(
    'clasificacion',
  );
  @override
  late final GeneratedColumn<String> clasificacion = GeneratedColumn<String>(
    'clasificacion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> valor =
      GeneratedColumn<String>(
        'valor',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($MovimientosCajaTable.$convertervalor);
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> fecha =
      GeneratedColumn<DateTime>(
        'fecha',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($MovimientosCajaTable.$converterfecha);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tiendaId,
    cajaId,
    tipo,
    clasificacion,
    valor,
    descripcion,
    fecha,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movimientos_caja';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaMovimientoCaja> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tienda_id')) {
      context.handle(
        _tiendaIdMeta,
        tiendaId.isAcceptableOrUnknown(data['tienda_id']!, _tiendaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tiendaIdMeta);
    }
    if (data.containsKey('caja_id')) {
      context.handle(
        _cajaIdMeta,
        cajaId.isAcceptableOrUnknown(data['caja_id']!, _cajaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cajaIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('clasificacion')) {
      context.handle(
        _clasificacionMeta,
        clasificacion.isAcceptableOrUnknown(
          data['clasificacion']!,
          _clasificacionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clasificacionMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descripcionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaMovimientoCaja map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaMovimientoCaja(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tiendaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tienda_id'],
      )!,
      cajaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caja_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      clasificacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clasificacion'],
      )!,
      valor: $MovimientosCajaTable.$convertervalor.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}valor'],
        )!,
      ),
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      )!,
      fecha: $MovimientosCajaTable.$converterfecha.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}fecha'],
        )!,
      ),
    );
  }

  @override
  $MovimientosCajaTable createAlias(String alias) {
    return $MovimientosCajaTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $convertervalor =
      const ConversorDecimal();
  static TypeConverter<DateTime, DateTime> $converterfecha =
      const ConversorFechaUtc();
}

class FilaMovimientoCaja extends DataClass
    implements Insertable<FilaMovimientoCaja> {
  final String id;
  final String tiendaId;
  final String cajaId;
  final String tipo;
  final String clasificacion;
  final Decimal valor;
  final String descripcion;
  final DateTime fecha;
  const FilaMovimientoCaja({
    required this.id,
    required this.tiendaId,
    required this.cajaId,
    required this.tipo,
    required this.clasificacion,
    required this.valor,
    required this.descripcion,
    required this.fecha,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tienda_id'] = Variable<String>(tiendaId);
    map['caja_id'] = Variable<String>(cajaId);
    map['tipo'] = Variable<String>(tipo);
    map['clasificacion'] = Variable<String>(clasificacion);
    {
      map['valor'] = Variable<String>(
        $MovimientosCajaTable.$convertervalor.toSql(valor),
      );
    }
    map['descripcion'] = Variable<String>(descripcion);
    {
      map['fecha'] = Variable<DateTime>(
        $MovimientosCajaTable.$converterfecha.toSql(fecha),
      );
    }
    return map;
  }

  MovimientosCajaCompanion toCompanion(bool nullToAbsent) {
    return MovimientosCajaCompanion(
      id: Value(id),
      tiendaId: Value(tiendaId),
      cajaId: Value(cajaId),
      tipo: Value(tipo),
      clasificacion: Value(clasificacion),
      valor: Value(valor),
      descripcion: Value(descripcion),
      fecha: Value(fecha),
    );
  }

  factory FilaMovimientoCaja.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaMovimientoCaja(
      id: serializer.fromJson<String>(json['id']),
      tiendaId: serializer.fromJson<String>(json['tiendaId']),
      cajaId: serializer.fromJson<String>(json['cajaId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      clasificacion: serializer.fromJson<String>(json['clasificacion']),
      valor: serializer.fromJson<Decimal>(json['valor']),
      descripcion: serializer.fromJson<String>(json['descripcion']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tiendaId': serializer.toJson<String>(tiendaId),
      'cajaId': serializer.toJson<String>(cajaId),
      'tipo': serializer.toJson<String>(tipo),
      'clasificacion': serializer.toJson<String>(clasificacion),
      'valor': serializer.toJson<Decimal>(valor),
      'descripcion': serializer.toJson<String>(descripcion),
      'fecha': serializer.toJson<DateTime>(fecha),
    };
  }

  FilaMovimientoCaja copyWith({
    String? id,
    String? tiendaId,
    String? cajaId,
    String? tipo,
    String? clasificacion,
    Decimal? valor,
    String? descripcion,
    DateTime? fecha,
  }) => FilaMovimientoCaja(
    id: id ?? this.id,
    tiendaId: tiendaId ?? this.tiendaId,
    cajaId: cajaId ?? this.cajaId,
    tipo: tipo ?? this.tipo,
    clasificacion: clasificacion ?? this.clasificacion,
    valor: valor ?? this.valor,
    descripcion: descripcion ?? this.descripcion,
    fecha: fecha ?? this.fecha,
  );
  FilaMovimientoCaja copyWithCompanion(MovimientosCajaCompanion data) {
    return FilaMovimientoCaja(
      id: data.id.present ? data.id.value : this.id,
      tiendaId: data.tiendaId.present ? data.tiendaId.value : this.tiendaId,
      cajaId: data.cajaId.present ? data.cajaId.value : this.cajaId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      clasificacion: data.clasificacion.present
          ? data.clasificacion.value
          : this.clasificacion,
      valor: data.valor.present ? data.valor.value : this.valor,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaMovimientoCaja(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('cajaId: $cajaId, ')
          ..write('tipo: $tipo, ')
          ..write('clasificacion: $clasificacion, ')
          ..write('valor: $valor, ')
          ..write('descripcion: $descripcion, ')
          ..write('fecha: $fecha')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tiendaId,
    cajaId,
    tipo,
    clasificacion,
    valor,
    descripcion,
    fecha,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaMovimientoCaja &&
          other.id == this.id &&
          other.tiendaId == this.tiendaId &&
          other.cajaId == this.cajaId &&
          other.tipo == this.tipo &&
          other.clasificacion == this.clasificacion &&
          other.valor == this.valor &&
          other.descripcion == this.descripcion &&
          other.fecha == this.fecha);
}

class MovimientosCajaCompanion extends UpdateCompanion<FilaMovimientoCaja> {
  final Value<String> id;
  final Value<String> tiendaId;
  final Value<String> cajaId;
  final Value<String> tipo;
  final Value<String> clasificacion;
  final Value<Decimal> valor;
  final Value<String> descripcion;
  final Value<DateTime> fecha;
  final Value<int> rowid;
  const MovimientosCajaCompanion({
    this.id = const Value.absent(),
    this.tiendaId = const Value.absent(),
    this.cajaId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.clasificacion = const Value.absent(),
    this.valor = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.fecha = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MovimientosCajaCompanion.insert({
    required String id,
    required String tiendaId,
    required String cajaId,
    required String tipo,
    required String clasificacion,
    required Decimal valor,
    required String descripcion,
    required DateTime fecha,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tiendaId = Value(tiendaId),
       cajaId = Value(cajaId),
       tipo = Value(tipo),
       clasificacion = Value(clasificacion),
       valor = Value(valor),
       descripcion = Value(descripcion),
       fecha = Value(fecha);
  static Insertable<FilaMovimientoCaja> custom({
    Expression<String>? id,
    Expression<String>? tiendaId,
    Expression<String>? cajaId,
    Expression<String>? tipo,
    Expression<String>? clasificacion,
    Expression<String>? valor,
    Expression<String>? descripcion,
    Expression<DateTime>? fecha,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tiendaId != null) 'tienda_id': tiendaId,
      if (cajaId != null) 'caja_id': cajaId,
      if (tipo != null) 'tipo': tipo,
      if (clasificacion != null) 'clasificacion': clasificacion,
      if (valor != null) 'valor': valor,
      if (descripcion != null) 'descripcion': descripcion,
      if (fecha != null) 'fecha': fecha,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MovimientosCajaCompanion copyWith({
    Value<String>? id,
    Value<String>? tiendaId,
    Value<String>? cajaId,
    Value<String>? tipo,
    Value<String>? clasificacion,
    Value<Decimal>? valor,
    Value<String>? descripcion,
    Value<DateTime>? fecha,
    Value<int>? rowid,
  }) {
    return MovimientosCajaCompanion(
      id: id ?? this.id,
      tiendaId: tiendaId ?? this.tiendaId,
      cajaId: cajaId ?? this.cajaId,
      tipo: tipo ?? this.tipo,
      clasificacion: clasificacion ?? this.clasificacion,
      valor: valor ?? this.valor,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tiendaId.present) {
      map['tienda_id'] = Variable<String>(tiendaId.value);
    }
    if (cajaId.present) {
      map['caja_id'] = Variable<String>(cajaId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (clasificacion.present) {
      map['clasificacion'] = Variable<String>(clasificacion.value);
    }
    if (valor.present) {
      map['valor'] = Variable<String>(
        $MovimientosCajaTable.$convertervalor.toSql(valor.value),
      );
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(
        $MovimientosCajaTable.$converterfecha.toSql(fecha.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovimientosCajaCompanion(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('cajaId: $cajaId, ')
          ..write('tipo: $tipo, ')
          ..write('clasificacion: $clasificacion, ')
          ..write('valor: $valor, ')
          ..write('descripcion: $descripcion, ')
          ..write('fecha: $fecha, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FormasPagoTable extends FormasPago
    with TableInfo<$FormasPagoTable, FilaFormaPago> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FormasPagoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tiendaIdMeta = const VerificationMeta(
    'tiendaId',
  );
  @override
  late final GeneratedColumn<String> tiendaId = GeneratedColumn<String>(
    'tienda_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ventaIdMeta = const VerificationMeta(
    'ventaId',
  );
  @override
  late final GeneratedColumn<String> ventaId = GeneratedColumn<String>(
    'venta_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ventas (id)',
    ),
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String> montoRecibido =
      GeneratedColumn<String>(
        'monto_recibido',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Decimal?>($FormasPagoTable.$convertermontoRecibidon);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String> cambio =
      GeneratedColumn<String>(
        'cambio',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Decimal?>($FormasPagoTable.$convertercambion);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String> monto =
      GeneratedColumn<String>(
        'monto',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Decimal?>($FormasPagoTable.$convertermonton);
  static const VerificationMeta _referenciaMeta = const VerificationMeta(
    'referencia',
  );
  @override
  late final GeneratedColumn<String> referencia = GeneratedColumn<String>(
    'referencia',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tiendaId,
    ventaId,
    tipo,
    montoRecibido,
    cambio,
    monto,
    referencia,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'formas_pago';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaFormaPago> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tienda_id')) {
      context.handle(
        _tiendaIdMeta,
        tiendaId.isAcceptableOrUnknown(data['tienda_id']!, _tiendaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tiendaIdMeta);
    }
    if (data.containsKey('venta_id')) {
      context.handle(
        _ventaIdMeta,
        ventaId.isAcceptableOrUnknown(data['venta_id']!, _ventaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ventaIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('referencia')) {
      context.handle(
        _referenciaMeta,
        referencia.isAcceptableOrUnknown(data['referencia']!, _referenciaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaFormaPago map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaFormaPago(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tiendaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tienda_id'],
      )!,
      ventaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venta_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      montoRecibido: $FormasPagoTable.$convertermontoRecibidon.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}monto_recibido'],
        ),
      ),
      cambio: $FormasPagoTable.$convertercambion.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cambio'],
        ),
      ),
      monto: $FormasPagoTable.$convertermonton.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}monto'],
        ),
      ),
      referencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}referencia'],
      ),
    );
  }

  @override
  $FormasPagoTable createAlias(String alias) {
    return $FormasPagoTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $convertermontoRecibido =
      const ConversorDecimal();
  static TypeConverter<Decimal?, String?> $convertermontoRecibidon =
      NullAwareTypeConverter.wrap($convertermontoRecibido);
  static TypeConverter<Decimal, String> $convertercambio =
      const ConversorDecimal();
  static TypeConverter<Decimal?, String?> $convertercambion =
      NullAwareTypeConverter.wrap($convertercambio);
  static TypeConverter<Decimal, String> $convertermonto =
      const ConversorDecimal();
  static TypeConverter<Decimal?, String?> $convertermonton =
      NullAwareTypeConverter.wrap($convertermonto);
}

class FilaFormaPago extends DataClass implements Insertable<FilaFormaPago> {
  final String id;
  final String tiendaId;
  final String ventaId;
  final String tipo;
  final Decimal? montoRecibido;
  final Decimal? cambio;
  final Decimal? monto;
  final String? referencia;
  const FilaFormaPago({
    required this.id,
    required this.tiendaId,
    required this.ventaId,
    required this.tipo,
    this.montoRecibido,
    this.cambio,
    this.monto,
    this.referencia,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tienda_id'] = Variable<String>(tiendaId);
    map['venta_id'] = Variable<String>(ventaId);
    map['tipo'] = Variable<String>(tipo);
    if (!nullToAbsent || montoRecibido != null) {
      map['monto_recibido'] = Variable<String>(
        $FormasPagoTable.$convertermontoRecibidon.toSql(montoRecibido),
      );
    }
    if (!nullToAbsent || cambio != null) {
      map['cambio'] = Variable<String>(
        $FormasPagoTable.$convertercambion.toSql(cambio),
      );
    }
    if (!nullToAbsent || monto != null) {
      map['monto'] = Variable<String>(
        $FormasPagoTable.$convertermonton.toSql(monto),
      );
    }
    if (!nullToAbsent || referencia != null) {
      map['referencia'] = Variable<String>(referencia);
    }
    return map;
  }

  FormasPagoCompanion toCompanion(bool nullToAbsent) {
    return FormasPagoCompanion(
      id: Value(id),
      tiendaId: Value(tiendaId),
      ventaId: Value(ventaId),
      tipo: Value(tipo),
      montoRecibido: montoRecibido == null && nullToAbsent
          ? const Value.absent()
          : Value(montoRecibido),
      cambio: cambio == null && nullToAbsent
          ? const Value.absent()
          : Value(cambio),
      monto: monto == null && nullToAbsent
          ? const Value.absent()
          : Value(monto),
      referencia: referencia == null && nullToAbsent
          ? const Value.absent()
          : Value(referencia),
    );
  }

  factory FilaFormaPago.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaFormaPago(
      id: serializer.fromJson<String>(json['id']),
      tiendaId: serializer.fromJson<String>(json['tiendaId']),
      ventaId: serializer.fromJson<String>(json['ventaId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      montoRecibido: serializer.fromJson<Decimal?>(json['montoRecibido']),
      cambio: serializer.fromJson<Decimal?>(json['cambio']),
      monto: serializer.fromJson<Decimal?>(json['monto']),
      referencia: serializer.fromJson<String?>(json['referencia']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tiendaId': serializer.toJson<String>(tiendaId),
      'ventaId': serializer.toJson<String>(ventaId),
      'tipo': serializer.toJson<String>(tipo),
      'montoRecibido': serializer.toJson<Decimal?>(montoRecibido),
      'cambio': serializer.toJson<Decimal?>(cambio),
      'monto': serializer.toJson<Decimal?>(monto),
      'referencia': serializer.toJson<String?>(referencia),
    };
  }

  FilaFormaPago copyWith({
    String? id,
    String? tiendaId,
    String? ventaId,
    String? tipo,
    Value<Decimal?> montoRecibido = const Value.absent(),
    Value<Decimal?> cambio = const Value.absent(),
    Value<Decimal?> monto = const Value.absent(),
    Value<String?> referencia = const Value.absent(),
  }) => FilaFormaPago(
    id: id ?? this.id,
    tiendaId: tiendaId ?? this.tiendaId,
    ventaId: ventaId ?? this.ventaId,
    tipo: tipo ?? this.tipo,
    montoRecibido: montoRecibido.present
        ? montoRecibido.value
        : this.montoRecibido,
    cambio: cambio.present ? cambio.value : this.cambio,
    monto: monto.present ? monto.value : this.monto,
    referencia: referencia.present ? referencia.value : this.referencia,
  );
  FilaFormaPago copyWithCompanion(FormasPagoCompanion data) {
    return FilaFormaPago(
      id: data.id.present ? data.id.value : this.id,
      tiendaId: data.tiendaId.present ? data.tiendaId.value : this.tiendaId,
      ventaId: data.ventaId.present ? data.ventaId.value : this.ventaId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      montoRecibido: data.montoRecibido.present
          ? data.montoRecibido.value
          : this.montoRecibido,
      cambio: data.cambio.present ? data.cambio.value : this.cambio,
      monto: data.monto.present ? data.monto.value : this.monto,
      referencia: data.referencia.present
          ? data.referencia.value
          : this.referencia,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaFormaPago(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('ventaId: $ventaId, ')
          ..write('tipo: $tipo, ')
          ..write('montoRecibido: $montoRecibido, ')
          ..write('cambio: $cambio, ')
          ..write('monto: $monto, ')
          ..write('referencia: $referencia')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tiendaId,
    ventaId,
    tipo,
    montoRecibido,
    cambio,
    monto,
    referencia,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaFormaPago &&
          other.id == this.id &&
          other.tiendaId == this.tiendaId &&
          other.ventaId == this.ventaId &&
          other.tipo == this.tipo &&
          other.montoRecibido == this.montoRecibido &&
          other.cambio == this.cambio &&
          other.monto == this.monto &&
          other.referencia == this.referencia);
}

class FormasPagoCompanion extends UpdateCompanion<FilaFormaPago> {
  final Value<String> id;
  final Value<String> tiendaId;
  final Value<String> ventaId;
  final Value<String> tipo;
  final Value<Decimal?> montoRecibido;
  final Value<Decimal?> cambio;
  final Value<Decimal?> monto;
  final Value<String?> referencia;
  final Value<int> rowid;
  const FormasPagoCompanion({
    this.id = const Value.absent(),
    this.tiendaId = const Value.absent(),
    this.ventaId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.montoRecibido = const Value.absent(),
    this.cambio = const Value.absent(),
    this.monto = const Value.absent(),
    this.referencia = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FormasPagoCompanion.insert({
    required String id,
    required String tiendaId,
    required String ventaId,
    required String tipo,
    this.montoRecibido = const Value.absent(),
    this.cambio = const Value.absent(),
    this.monto = const Value.absent(),
    this.referencia = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tiendaId = Value(tiendaId),
       ventaId = Value(ventaId),
       tipo = Value(tipo);
  static Insertable<FilaFormaPago> custom({
    Expression<String>? id,
    Expression<String>? tiendaId,
    Expression<String>? ventaId,
    Expression<String>? tipo,
    Expression<String>? montoRecibido,
    Expression<String>? cambio,
    Expression<String>? monto,
    Expression<String>? referencia,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tiendaId != null) 'tienda_id': tiendaId,
      if (ventaId != null) 'venta_id': ventaId,
      if (tipo != null) 'tipo': tipo,
      if (montoRecibido != null) 'monto_recibido': montoRecibido,
      if (cambio != null) 'cambio': cambio,
      if (monto != null) 'monto': monto,
      if (referencia != null) 'referencia': referencia,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FormasPagoCompanion copyWith({
    Value<String>? id,
    Value<String>? tiendaId,
    Value<String>? ventaId,
    Value<String>? tipo,
    Value<Decimal?>? montoRecibido,
    Value<Decimal?>? cambio,
    Value<Decimal?>? monto,
    Value<String?>? referencia,
    Value<int>? rowid,
  }) {
    return FormasPagoCompanion(
      id: id ?? this.id,
      tiendaId: tiendaId ?? this.tiendaId,
      ventaId: ventaId ?? this.ventaId,
      tipo: tipo ?? this.tipo,
      montoRecibido: montoRecibido ?? this.montoRecibido,
      cambio: cambio ?? this.cambio,
      monto: monto ?? this.monto,
      referencia: referencia ?? this.referencia,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tiendaId.present) {
      map['tienda_id'] = Variable<String>(tiendaId.value);
    }
    if (ventaId.present) {
      map['venta_id'] = Variable<String>(ventaId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (montoRecibido.present) {
      map['monto_recibido'] = Variable<String>(
        $FormasPagoTable.$convertermontoRecibidon.toSql(montoRecibido.value),
      );
    }
    if (cambio.present) {
      map['cambio'] = Variable<String>(
        $FormasPagoTable.$convertercambion.toSql(cambio.value),
      );
    }
    if (monto.present) {
      map['monto'] = Variable<String>(
        $FormasPagoTable.$convertermonton.toSql(monto.value),
      );
    }
    if (referencia.present) {
      map['referencia'] = Variable<String>(referencia.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FormasPagoCompanion(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('ventaId: $ventaId, ')
          ..write('tipo: $tipo, ')
          ..write('montoRecibido: $montoRecibido, ')
          ..write('cambio: $cambio, ')
          ..write('monto: $monto, ')
          ..write('referencia: $referencia, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlertasReabastecimientoTable extends AlertasReabastecimiento
    with TableInfo<$AlertasReabastecimientoTable, FilaAlerta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertasReabastecimientoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tiendaIdMeta = const VerificationMeta(
    'tiendaId',
  );
  @override
  late final GeneratedColumn<String> tiendaId = GeneratedColumn<String>(
    'tienda_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items_inventario (id)',
    ),
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> existencia =
      GeneratedColumn<String>(
        'existencia',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>(
        $AlertasReabastecimientoTable.$converterexistencia,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String>
  consumoPromedioDiario =
      GeneratedColumn<String>(
        'consumo_promedio_diario',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>(
        $AlertasReabastecimientoTable.$converterconsumoPromedioDiario,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> diasCobertura =
      GeneratedColumn<String>(
        'dias_cobertura',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>(
        $AlertasReabastecimientoTable.$converterdiasCobertura,
      );
  static const VerificationMeta _provisionalMeta = const VerificationMeta(
    'provisional',
  );
  @override
  late final GeneratedColumn<bool> provisional = GeneratedColumn<bool>(
    'provisional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("provisional" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tiendaId,
    itemId,
    fecha,
    existencia,
    consumoPromedioDiario,
    diasCobertura,
    provisional,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alertas_reabastecimiento';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaAlerta> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tienda_id')) {
      context.handle(
        _tiendaIdMeta,
        tiendaId.isAcceptableOrUnknown(data['tienda_id']!, _tiendaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tiendaIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('provisional')) {
      context.handle(
        _provisionalMeta,
        provisional.isAcceptableOrUnknown(
          data['provisional']!,
          _provisionalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_provisionalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaAlerta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaAlerta(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tiendaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tienda_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha'],
      )!,
      existencia: $AlertasReabastecimientoTable.$converterexistencia.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}existencia'],
        )!,
      ),
      consumoPromedioDiario: $AlertasReabastecimientoTable
          .$converterconsumoPromedioDiario
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}consumo_promedio_diario'],
            )!,
          ),
      diasCobertura: $AlertasReabastecimientoTable.$converterdiasCobertura
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}dias_cobertura'],
            )!,
          ),
      provisional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}provisional'],
      )!,
    );
  }

  @override
  $AlertasReabastecimientoTable createAlias(String alias) {
    return $AlertasReabastecimientoTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterexistencia =
      const ConversorDecimal();
  static TypeConverter<Decimal, String> $converterconsumoPromedioDiario =
      const ConversorDecimal();
  static TypeConverter<Decimal, String> $converterdiasCobertura =
      const ConversorDecimal();
}

class FilaAlerta extends DataClass implements Insertable<FilaAlerta> {
  final String id;
  final String tiendaId;
  final String itemId;
  final String fecha;
  final Decimal existencia;
  final Decimal consumoPromedioDiario;
  final Decimal diasCobertura;
  final bool provisional;
  const FilaAlerta({
    required this.id,
    required this.tiendaId,
    required this.itemId,
    required this.fecha,
    required this.existencia,
    required this.consumoPromedioDiario,
    required this.diasCobertura,
    required this.provisional,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tienda_id'] = Variable<String>(tiendaId);
    map['item_id'] = Variable<String>(itemId);
    map['fecha'] = Variable<String>(fecha);
    {
      map['existencia'] = Variable<String>(
        $AlertasReabastecimientoTable.$converterexistencia.toSql(existencia),
      );
    }
    {
      map['consumo_promedio_diario'] = Variable<String>(
        $AlertasReabastecimientoTable.$converterconsumoPromedioDiario.toSql(
          consumoPromedioDiario,
        ),
      );
    }
    {
      map['dias_cobertura'] = Variable<String>(
        $AlertasReabastecimientoTable.$converterdiasCobertura.toSql(
          diasCobertura,
        ),
      );
    }
    map['provisional'] = Variable<bool>(provisional);
    return map;
  }

  AlertasReabastecimientoCompanion toCompanion(bool nullToAbsent) {
    return AlertasReabastecimientoCompanion(
      id: Value(id),
      tiendaId: Value(tiendaId),
      itemId: Value(itemId),
      fecha: Value(fecha),
      existencia: Value(existencia),
      consumoPromedioDiario: Value(consumoPromedioDiario),
      diasCobertura: Value(diasCobertura),
      provisional: Value(provisional),
    );
  }

  factory FilaAlerta.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaAlerta(
      id: serializer.fromJson<String>(json['id']),
      tiendaId: serializer.fromJson<String>(json['tiendaId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      fecha: serializer.fromJson<String>(json['fecha']),
      existencia: serializer.fromJson<Decimal>(json['existencia']),
      consumoPromedioDiario: serializer.fromJson<Decimal>(
        json['consumoPromedioDiario'],
      ),
      diasCobertura: serializer.fromJson<Decimal>(json['diasCobertura']),
      provisional: serializer.fromJson<bool>(json['provisional']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tiendaId': serializer.toJson<String>(tiendaId),
      'itemId': serializer.toJson<String>(itemId),
      'fecha': serializer.toJson<String>(fecha),
      'existencia': serializer.toJson<Decimal>(existencia),
      'consumoPromedioDiario': serializer.toJson<Decimal>(
        consumoPromedioDiario,
      ),
      'diasCobertura': serializer.toJson<Decimal>(diasCobertura),
      'provisional': serializer.toJson<bool>(provisional),
    };
  }

  FilaAlerta copyWith({
    String? id,
    String? tiendaId,
    String? itemId,
    String? fecha,
    Decimal? existencia,
    Decimal? consumoPromedioDiario,
    Decimal? diasCobertura,
    bool? provisional,
  }) => FilaAlerta(
    id: id ?? this.id,
    tiendaId: tiendaId ?? this.tiendaId,
    itemId: itemId ?? this.itemId,
    fecha: fecha ?? this.fecha,
    existencia: existencia ?? this.existencia,
    consumoPromedioDiario: consumoPromedioDiario ?? this.consumoPromedioDiario,
    diasCobertura: diasCobertura ?? this.diasCobertura,
    provisional: provisional ?? this.provisional,
  );
  FilaAlerta copyWithCompanion(AlertasReabastecimientoCompanion data) {
    return FilaAlerta(
      id: data.id.present ? data.id.value : this.id,
      tiendaId: data.tiendaId.present ? data.tiendaId.value : this.tiendaId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      existencia: data.existencia.present
          ? data.existencia.value
          : this.existencia,
      consumoPromedioDiario: data.consumoPromedioDiario.present
          ? data.consumoPromedioDiario.value
          : this.consumoPromedioDiario,
      diasCobertura: data.diasCobertura.present
          ? data.diasCobertura.value
          : this.diasCobertura,
      provisional: data.provisional.present
          ? data.provisional.value
          : this.provisional,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaAlerta(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('itemId: $itemId, ')
          ..write('fecha: $fecha, ')
          ..write('existencia: $existencia, ')
          ..write('consumoPromedioDiario: $consumoPromedioDiario, ')
          ..write('diasCobertura: $diasCobertura, ')
          ..write('provisional: $provisional')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tiendaId,
    itemId,
    fecha,
    existencia,
    consumoPromedioDiario,
    diasCobertura,
    provisional,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaAlerta &&
          other.id == this.id &&
          other.tiendaId == this.tiendaId &&
          other.itemId == this.itemId &&
          other.fecha == this.fecha &&
          other.existencia == this.existencia &&
          other.consumoPromedioDiario == this.consumoPromedioDiario &&
          other.diasCobertura == this.diasCobertura &&
          other.provisional == this.provisional);
}

class AlertasReabastecimientoCompanion extends UpdateCompanion<FilaAlerta> {
  final Value<String> id;
  final Value<String> tiendaId;
  final Value<String> itemId;
  final Value<String> fecha;
  final Value<Decimal> existencia;
  final Value<Decimal> consumoPromedioDiario;
  final Value<Decimal> diasCobertura;
  final Value<bool> provisional;
  final Value<int> rowid;
  const AlertasReabastecimientoCompanion({
    this.id = const Value.absent(),
    this.tiendaId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.fecha = const Value.absent(),
    this.existencia = const Value.absent(),
    this.consumoPromedioDiario = const Value.absent(),
    this.diasCobertura = const Value.absent(),
    this.provisional = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertasReabastecimientoCompanion.insert({
    required String id,
    required String tiendaId,
    required String itemId,
    required String fecha,
    required Decimal existencia,
    required Decimal consumoPromedioDiario,
    required Decimal diasCobertura,
    required bool provisional,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tiendaId = Value(tiendaId),
       itemId = Value(itemId),
       fecha = Value(fecha),
       existencia = Value(existencia),
       consumoPromedioDiario = Value(consumoPromedioDiario),
       diasCobertura = Value(diasCobertura),
       provisional = Value(provisional);
  static Insertable<FilaAlerta> custom({
    Expression<String>? id,
    Expression<String>? tiendaId,
    Expression<String>? itemId,
    Expression<String>? fecha,
    Expression<String>? existencia,
    Expression<String>? consumoPromedioDiario,
    Expression<String>? diasCobertura,
    Expression<bool>? provisional,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tiendaId != null) 'tienda_id': tiendaId,
      if (itemId != null) 'item_id': itemId,
      if (fecha != null) 'fecha': fecha,
      if (existencia != null) 'existencia': existencia,
      if (consumoPromedioDiario != null)
        'consumo_promedio_diario': consumoPromedioDiario,
      if (diasCobertura != null) 'dias_cobertura': diasCobertura,
      if (provisional != null) 'provisional': provisional,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertasReabastecimientoCompanion copyWith({
    Value<String>? id,
    Value<String>? tiendaId,
    Value<String>? itemId,
    Value<String>? fecha,
    Value<Decimal>? existencia,
    Value<Decimal>? consumoPromedioDiario,
    Value<Decimal>? diasCobertura,
    Value<bool>? provisional,
    Value<int>? rowid,
  }) {
    return AlertasReabastecimientoCompanion(
      id: id ?? this.id,
      tiendaId: tiendaId ?? this.tiendaId,
      itemId: itemId ?? this.itemId,
      fecha: fecha ?? this.fecha,
      existencia: existencia ?? this.existencia,
      consumoPromedioDiario:
          consumoPromedioDiario ?? this.consumoPromedioDiario,
      diasCobertura: diasCobertura ?? this.diasCobertura,
      provisional: provisional ?? this.provisional,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tiendaId.present) {
      map['tienda_id'] = Variable<String>(tiendaId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    if (existencia.present) {
      map['existencia'] = Variable<String>(
        $AlertasReabastecimientoTable.$converterexistencia.toSql(
          existencia.value,
        ),
      );
    }
    if (consumoPromedioDiario.present) {
      map['consumo_promedio_diario'] = Variable<String>(
        $AlertasReabastecimientoTable.$converterconsumoPromedioDiario.toSql(
          consumoPromedioDiario.value,
        ),
      );
    }
    if (diasCobertura.present) {
      map['dias_cobertura'] = Variable<String>(
        $AlertasReabastecimientoTable.$converterdiasCobertura.toSql(
          diasCobertura.value,
        ),
      );
    }
    if (provisional.present) {
      map['provisional'] = Variable<bool>(provisional.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertasReabastecimientoCompanion(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('itemId: $itemId, ')
          ..write('fecha: $fecha, ')
          ..write('existencia: $existencia, ')
          ..write('consumoPromedioDiario: $consumoPromedioDiario, ')
          ..write('diasCobertura: $diasCobertura, ')
          ..write('provisional: $provisional, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VentasPerdidasTable extends VentasPerdidas
    with TableInfo<$VentasPerdidasTable, FilaVentaPerdida> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VentasPerdidasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tiendaIdMeta = const VerificationMeta(
    'tiendaId',
  );
  @override
  late final GeneratedColumn<String> tiendaId = GeneratedColumn<String>(
    'tienda_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productoIdMeta = const VerificationMeta(
    'productoId',
  );
  @override
  late final GeneratedColumn<String> productoId = GeneratedColumn<String>(
    'producto_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES productos (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> fecha =
      GeneratedColumn<DateTime>(
        'fecha',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($VentasPerdidasTable.$converterfecha);
  @override
  List<GeneratedColumn> get $columns => [id, tiendaId, productoId, fecha];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ventas_perdidas';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaVentaPerdida> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tienda_id')) {
      context.handle(
        _tiendaIdMeta,
        tiendaId.isAcceptableOrUnknown(data['tienda_id']!, _tiendaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tiendaIdMeta);
    }
    if (data.containsKey('producto_id')) {
      context.handle(
        _productoIdMeta,
        productoId.isAcceptableOrUnknown(data['producto_id']!, _productoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productoIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaVentaPerdida map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaVentaPerdida(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tiendaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tienda_id'],
      )!,
      productoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}producto_id'],
      )!,
      fecha: $VentasPerdidasTable.$converterfecha.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}fecha'],
        )!,
      ),
    );
  }

  @override
  $VentasPerdidasTable createAlias(String alias) {
    return $VentasPerdidasTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterfecha =
      const ConversorFechaUtc();
}

class FilaVentaPerdida extends DataClass
    implements Insertable<FilaVentaPerdida> {
  final String id;
  final String tiendaId;
  final String productoId;
  final DateTime fecha;
  const FilaVentaPerdida({
    required this.id,
    required this.tiendaId,
    required this.productoId,
    required this.fecha,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tienda_id'] = Variable<String>(tiendaId);
    map['producto_id'] = Variable<String>(productoId);
    {
      map['fecha'] = Variable<DateTime>(
        $VentasPerdidasTable.$converterfecha.toSql(fecha),
      );
    }
    return map;
  }

  VentasPerdidasCompanion toCompanion(bool nullToAbsent) {
    return VentasPerdidasCompanion(
      id: Value(id),
      tiendaId: Value(tiendaId),
      productoId: Value(productoId),
      fecha: Value(fecha),
    );
  }

  factory FilaVentaPerdida.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaVentaPerdida(
      id: serializer.fromJson<String>(json['id']),
      tiendaId: serializer.fromJson<String>(json['tiendaId']),
      productoId: serializer.fromJson<String>(json['productoId']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tiendaId': serializer.toJson<String>(tiendaId),
      'productoId': serializer.toJson<String>(productoId),
      'fecha': serializer.toJson<DateTime>(fecha),
    };
  }

  FilaVentaPerdida copyWith({
    String? id,
    String? tiendaId,
    String? productoId,
    DateTime? fecha,
  }) => FilaVentaPerdida(
    id: id ?? this.id,
    tiendaId: tiendaId ?? this.tiendaId,
    productoId: productoId ?? this.productoId,
    fecha: fecha ?? this.fecha,
  );
  FilaVentaPerdida copyWithCompanion(VentasPerdidasCompanion data) {
    return FilaVentaPerdida(
      id: data.id.present ? data.id.value : this.id,
      tiendaId: data.tiendaId.present ? data.tiendaId.value : this.tiendaId,
      productoId: data.productoId.present
          ? data.productoId.value
          : this.productoId,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaVentaPerdida(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('productoId: $productoId, ')
          ..write('fecha: $fecha')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tiendaId, productoId, fecha);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaVentaPerdida &&
          other.id == this.id &&
          other.tiendaId == this.tiendaId &&
          other.productoId == this.productoId &&
          other.fecha == this.fecha);
}

class VentasPerdidasCompanion extends UpdateCompanion<FilaVentaPerdida> {
  final Value<String> id;
  final Value<String> tiendaId;
  final Value<String> productoId;
  final Value<DateTime> fecha;
  final Value<int> rowid;
  const VentasPerdidasCompanion({
    this.id = const Value.absent(),
    this.tiendaId = const Value.absent(),
    this.productoId = const Value.absent(),
    this.fecha = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VentasPerdidasCompanion.insert({
    required String id,
    required String tiendaId,
    required String productoId,
    required DateTime fecha,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tiendaId = Value(tiendaId),
       productoId = Value(productoId),
       fecha = Value(fecha);
  static Insertable<FilaVentaPerdida> custom({
    Expression<String>? id,
    Expression<String>? tiendaId,
    Expression<String>? productoId,
    Expression<DateTime>? fecha,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tiendaId != null) 'tienda_id': tiendaId,
      if (productoId != null) 'producto_id': productoId,
      if (fecha != null) 'fecha': fecha,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VentasPerdidasCompanion copyWith({
    Value<String>? id,
    Value<String>? tiendaId,
    Value<String>? productoId,
    Value<DateTime>? fecha,
    Value<int>? rowid,
  }) {
    return VentasPerdidasCompanion(
      id: id ?? this.id,
      tiendaId: tiendaId ?? this.tiendaId,
      productoId: productoId ?? this.productoId,
      fecha: fecha ?? this.fecha,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tiendaId.present) {
      map['tienda_id'] = Variable<String>(tiendaId.value);
    }
    if (productoId.present) {
      map['producto_id'] = Variable<String>(productoId.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(
        $VentasPerdidasTable.$converterfecha.toSql(fecha.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VentasPerdidasCompanion(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('productoId: $productoId, ')
          ..write('fecha: $fecha, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClientesTable extends Clientes
    with TableInfo<$ClientesTable, FilaCliente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tiendaIdMeta = const VerificationMeta(
    'tiendaId',
  );
  @override
  late final GeneratedColumn<String> tiendaId = GeneratedColumn<String>(
    'tienda_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreNormalizadoMeta = const VerificationMeta(
    'nombreNormalizado',
  );
  @override
  late final GeneratedColumn<String> nombreNormalizado =
      GeneratedColumn<String>(
        'nombre_normalizado',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _telefonoMeta = const VerificationMeta(
    'telefono',
  );
  @override
  late final GeneratedColumn<String> telefono = GeneratedColumn<String>(
    'telefono',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime>
  actualizadoEn = GeneratedColumn<DateTime>(
    'actualizado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($ClientesTable.$converteractualizadoEn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tiendaId,
    nombre,
    nombreNormalizado,
    telefono,
    actualizadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clientes';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaCliente> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tienda_id')) {
      context.handle(
        _tiendaIdMeta,
        tiendaId.isAcceptableOrUnknown(data['tienda_id']!, _tiendaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tiendaIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('nombre_normalizado')) {
      context.handle(
        _nombreNormalizadoMeta,
        nombreNormalizado.isAcceptableOrUnknown(
          data['nombre_normalizado']!,
          _nombreNormalizadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nombreNormalizadoMeta);
    }
    if (data.containsKey('telefono')) {
      context.handle(
        _telefonoMeta,
        telefono.isAcceptableOrUnknown(data['telefono']!, _telefonoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaCliente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaCliente(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tiendaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tienda_id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      nombreNormalizado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_normalizado'],
      )!,
      telefono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefono'],
      )!,
      actualizadoEn: $ClientesTable.$converteractualizadoEn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}actualizado_en'],
        )!,
      ),
    );
  }

  @override
  $ClientesTable createAlias(String alias) {
    return $ClientesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converteractualizadoEn =
      const ConversorFechaUtc();
}

class FilaCliente extends DataClass implements Insertable<FilaCliente> {
  final String id;
  final String tiendaId;
  final String nombre;
  final String nombreNormalizado;
  final String telefono;
  final DateTime actualizadoEn;
  const FilaCliente({
    required this.id,
    required this.tiendaId,
    required this.nombre,
    required this.nombreNormalizado,
    required this.telefono,
    required this.actualizadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tienda_id'] = Variable<String>(tiendaId);
    map['nombre'] = Variable<String>(nombre);
    map['nombre_normalizado'] = Variable<String>(nombreNormalizado);
    map['telefono'] = Variable<String>(telefono);
    {
      map['actualizado_en'] = Variable<DateTime>(
        $ClientesTable.$converteractualizadoEn.toSql(actualizadoEn),
      );
    }
    return map;
  }

  ClientesCompanion toCompanion(bool nullToAbsent) {
    return ClientesCompanion(
      id: Value(id),
      tiendaId: Value(tiendaId),
      nombre: Value(nombre),
      nombreNormalizado: Value(nombreNormalizado),
      telefono: Value(telefono),
      actualizadoEn: Value(actualizadoEn),
    );
  }

  factory FilaCliente.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaCliente(
      id: serializer.fromJson<String>(json['id']),
      tiendaId: serializer.fromJson<String>(json['tiendaId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      nombreNormalizado: serializer.fromJson<String>(json['nombreNormalizado']),
      telefono: serializer.fromJson<String>(json['telefono']),
      actualizadoEn: serializer.fromJson<DateTime>(json['actualizadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tiendaId': serializer.toJson<String>(tiendaId),
      'nombre': serializer.toJson<String>(nombre),
      'nombreNormalizado': serializer.toJson<String>(nombreNormalizado),
      'telefono': serializer.toJson<String>(telefono),
      'actualizadoEn': serializer.toJson<DateTime>(actualizadoEn),
    };
  }

  FilaCliente copyWith({
    String? id,
    String? tiendaId,
    String? nombre,
    String? nombreNormalizado,
    String? telefono,
    DateTime? actualizadoEn,
  }) => FilaCliente(
    id: id ?? this.id,
    tiendaId: tiendaId ?? this.tiendaId,
    nombre: nombre ?? this.nombre,
    nombreNormalizado: nombreNormalizado ?? this.nombreNormalizado,
    telefono: telefono ?? this.telefono,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
  );
  FilaCliente copyWithCompanion(ClientesCompanion data) {
    return FilaCliente(
      id: data.id.present ? data.id.value : this.id,
      tiendaId: data.tiendaId.present ? data.tiendaId.value : this.tiendaId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      nombreNormalizado: data.nombreNormalizado.present
          ? data.nombreNormalizado.value
          : this.nombreNormalizado,
      telefono: data.telefono.present ? data.telefono.value : this.telefono,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaCliente(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('nombre: $nombre, ')
          ..write('nombreNormalizado: $nombreNormalizado, ')
          ..write('telefono: $telefono, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tiendaId,
    nombre,
    nombreNormalizado,
    telefono,
    actualizadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaCliente &&
          other.id == this.id &&
          other.tiendaId == this.tiendaId &&
          other.nombre == this.nombre &&
          other.nombreNormalizado == this.nombreNormalizado &&
          other.telefono == this.telefono &&
          other.actualizadoEn == this.actualizadoEn);
}

class ClientesCompanion extends UpdateCompanion<FilaCliente> {
  final Value<String> id;
  final Value<String> tiendaId;
  final Value<String> nombre;
  final Value<String> nombreNormalizado;
  final Value<String> telefono;
  final Value<DateTime> actualizadoEn;
  final Value<int> rowid;
  const ClientesCompanion({
    this.id = const Value.absent(),
    this.tiendaId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.nombreNormalizado = const Value.absent(),
    this.telefono = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientesCompanion.insert({
    required String id,
    required String tiendaId,
    required String nombre,
    required String nombreNormalizado,
    this.telefono = const Value.absent(),
    required DateTime actualizadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tiendaId = Value(tiendaId),
       nombre = Value(nombre),
       nombreNormalizado = Value(nombreNormalizado),
       actualizadoEn = Value(actualizadoEn);
  static Insertable<FilaCliente> custom({
    Expression<String>? id,
    Expression<String>? tiendaId,
    Expression<String>? nombre,
    Expression<String>? nombreNormalizado,
    Expression<String>? telefono,
    Expression<DateTime>? actualizadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tiendaId != null) 'tienda_id': tiendaId,
      if (nombre != null) 'nombre': nombre,
      if (nombreNormalizado != null) 'nombre_normalizado': nombreNormalizado,
      if (telefono != null) 'telefono': telefono,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientesCompanion copyWith({
    Value<String>? id,
    Value<String>? tiendaId,
    Value<String>? nombre,
    Value<String>? nombreNormalizado,
    Value<String>? telefono,
    Value<DateTime>? actualizadoEn,
    Value<int>? rowid,
  }) {
    return ClientesCompanion(
      id: id ?? this.id,
      tiendaId: tiendaId ?? this.tiendaId,
      nombre: nombre ?? this.nombre,
      nombreNormalizado: nombreNormalizado ?? this.nombreNormalizado,
      telefono: telefono ?? this.telefono,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tiendaId.present) {
      map['tienda_id'] = Variable<String>(tiendaId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (nombreNormalizado.present) {
      map['nombre_normalizado'] = Variable<String>(nombreNormalizado.value);
    }
    if (telefono.present) {
      map['telefono'] = Variable<String>(telefono.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<DateTime>(
        $ClientesTable.$converteractualizadoEn.toSql(actualizadoEn.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientesCompanion(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('nombre: $nombre, ')
          ..write('nombreNormalizado: $nombreNormalizado, ')
          ..write('telefono: $telefono, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FiadosTable extends Fiados with TableInfo<$FiadosTable, FilaFiado> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FiadosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES formas_pago (id)',
    ),
  );
  static const VerificationMeta _tiendaIdMeta = const VerificationMeta(
    'tiendaId',
  );
  @override
  late final GeneratedColumn<String> tiendaId = GeneratedColumn<String>(
    'tienda_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clienteIdMeta = const VerificationMeta(
    'clienteId',
  );
  @override
  late final GeneratedColumn<String> clienteId = GeneratedColumn<String>(
    'cliente_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clientes (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> montoInicial =
      GeneratedColumn<String>(
        'monto_inicial',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($FiadosTable.$convertermontoInicial);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> saldoPendiente =
      GeneratedColumn<String>(
        'saldo_pendiente',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($FiadosTable.$convertersaldoPendiente);
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> fechaInicio =
      GeneratedColumn<DateTime>(
        'fecha_inicio',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($FiadosTable.$converterfechaInicio);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tiendaId,
    clienteId,
    montoInicial,
    saldoPendiente,
    estado,
    fechaInicio,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fiados';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaFiado> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tienda_id')) {
      context.handle(
        _tiendaIdMeta,
        tiendaId.isAcceptableOrUnknown(data['tienda_id']!, _tiendaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tiendaIdMeta);
    }
    if (data.containsKey('cliente_id')) {
      context.handle(
        _clienteIdMeta,
        clienteId.isAcceptableOrUnknown(data['cliente_id']!, _clienteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clienteIdMeta);
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    } else if (isInserting) {
      context.missing(_estadoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaFiado map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaFiado(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tiendaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tienda_id'],
      )!,
      clienteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cliente_id'],
      )!,
      montoInicial: $FiadosTable.$convertermontoInicial.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}monto_inicial'],
        )!,
      ),
      saldoPendiente: $FiadosTable.$convertersaldoPendiente.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}saldo_pendiente'],
        )!,
      ),
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      fechaInicio: $FiadosTable.$converterfechaInicio.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}fecha_inicio'],
        )!,
      ),
    );
  }

  @override
  $FiadosTable createAlias(String alias) {
    return $FiadosTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $convertermontoInicial =
      const ConversorDecimal();
  static TypeConverter<Decimal, String> $convertersaldoPendiente =
      const ConversorDecimal();
  static TypeConverter<DateTime, DateTime> $converterfechaInicio =
      const ConversorFechaUtc();
}

class FilaFiado extends DataClass implements Insertable<FilaFiado> {
  final String id;
  final String tiendaId;
  final String clienteId;
  final Decimal montoInicial;
  final Decimal saldoPendiente;
  final String estado;
  final DateTime fechaInicio;
  const FilaFiado({
    required this.id,
    required this.tiendaId,
    required this.clienteId,
    required this.montoInicial,
    required this.saldoPendiente,
    required this.estado,
    required this.fechaInicio,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tienda_id'] = Variable<String>(tiendaId);
    map['cliente_id'] = Variable<String>(clienteId);
    {
      map['monto_inicial'] = Variable<String>(
        $FiadosTable.$convertermontoInicial.toSql(montoInicial),
      );
    }
    {
      map['saldo_pendiente'] = Variable<String>(
        $FiadosTable.$convertersaldoPendiente.toSql(saldoPendiente),
      );
    }
    map['estado'] = Variable<String>(estado);
    {
      map['fecha_inicio'] = Variable<DateTime>(
        $FiadosTable.$converterfechaInicio.toSql(fechaInicio),
      );
    }
    return map;
  }

  FiadosCompanion toCompanion(bool nullToAbsent) {
    return FiadosCompanion(
      id: Value(id),
      tiendaId: Value(tiendaId),
      clienteId: Value(clienteId),
      montoInicial: Value(montoInicial),
      saldoPendiente: Value(saldoPendiente),
      estado: Value(estado),
      fechaInicio: Value(fechaInicio),
    );
  }

  factory FilaFiado.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaFiado(
      id: serializer.fromJson<String>(json['id']),
      tiendaId: serializer.fromJson<String>(json['tiendaId']),
      clienteId: serializer.fromJson<String>(json['clienteId']),
      montoInicial: serializer.fromJson<Decimal>(json['montoInicial']),
      saldoPendiente: serializer.fromJson<Decimal>(json['saldoPendiente']),
      estado: serializer.fromJson<String>(json['estado']),
      fechaInicio: serializer.fromJson<DateTime>(json['fechaInicio']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tiendaId': serializer.toJson<String>(tiendaId),
      'clienteId': serializer.toJson<String>(clienteId),
      'montoInicial': serializer.toJson<Decimal>(montoInicial),
      'saldoPendiente': serializer.toJson<Decimal>(saldoPendiente),
      'estado': serializer.toJson<String>(estado),
      'fechaInicio': serializer.toJson<DateTime>(fechaInicio),
    };
  }

  FilaFiado copyWith({
    String? id,
    String? tiendaId,
    String? clienteId,
    Decimal? montoInicial,
    Decimal? saldoPendiente,
    String? estado,
    DateTime? fechaInicio,
  }) => FilaFiado(
    id: id ?? this.id,
    tiendaId: tiendaId ?? this.tiendaId,
    clienteId: clienteId ?? this.clienteId,
    montoInicial: montoInicial ?? this.montoInicial,
    saldoPendiente: saldoPendiente ?? this.saldoPendiente,
    estado: estado ?? this.estado,
    fechaInicio: fechaInicio ?? this.fechaInicio,
  );
  FilaFiado copyWithCompanion(FiadosCompanion data) {
    return FilaFiado(
      id: data.id.present ? data.id.value : this.id,
      tiendaId: data.tiendaId.present ? data.tiendaId.value : this.tiendaId,
      clienteId: data.clienteId.present ? data.clienteId.value : this.clienteId,
      montoInicial: data.montoInicial.present
          ? data.montoInicial.value
          : this.montoInicial,
      saldoPendiente: data.saldoPendiente.present
          ? data.saldoPendiente.value
          : this.saldoPendiente,
      estado: data.estado.present ? data.estado.value : this.estado,
      fechaInicio: data.fechaInicio.present
          ? data.fechaInicio.value
          : this.fechaInicio,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaFiado(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('clienteId: $clienteId, ')
          ..write('montoInicial: $montoInicial, ')
          ..write('saldoPendiente: $saldoPendiente, ')
          ..write('estado: $estado, ')
          ..write('fechaInicio: $fechaInicio')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tiendaId,
    clienteId,
    montoInicial,
    saldoPendiente,
    estado,
    fechaInicio,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaFiado &&
          other.id == this.id &&
          other.tiendaId == this.tiendaId &&
          other.clienteId == this.clienteId &&
          other.montoInicial == this.montoInicial &&
          other.saldoPendiente == this.saldoPendiente &&
          other.estado == this.estado &&
          other.fechaInicio == this.fechaInicio);
}

class FiadosCompanion extends UpdateCompanion<FilaFiado> {
  final Value<String> id;
  final Value<String> tiendaId;
  final Value<String> clienteId;
  final Value<Decimal> montoInicial;
  final Value<Decimal> saldoPendiente;
  final Value<String> estado;
  final Value<DateTime> fechaInicio;
  final Value<int> rowid;
  const FiadosCompanion({
    this.id = const Value.absent(),
    this.tiendaId = const Value.absent(),
    this.clienteId = const Value.absent(),
    this.montoInicial = const Value.absent(),
    this.saldoPendiente = const Value.absent(),
    this.estado = const Value.absent(),
    this.fechaInicio = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FiadosCompanion.insert({
    required String id,
    required String tiendaId,
    required String clienteId,
    required Decimal montoInicial,
    required Decimal saldoPendiente,
    required String estado,
    required DateTime fechaInicio,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tiendaId = Value(tiendaId),
       clienteId = Value(clienteId),
       montoInicial = Value(montoInicial),
       saldoPendiente = Value(saldoPendiente),
       estado = Value(estado),
       fechaInicio = Value(fechaInicio);
  static Insertable<FilaFiado> custom({
    Expression<String>? id,
    Expression<String>? tiendaId,
    Expression<String>? clienteId,
    Expression<String>? montoInicial,
    Expression<String>? saldoPendiente,
    Expression<String>? estado,
    Expression<DateTime>? fechaInicio,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tiendaId != null) 'tienda_id': tiendaId,
      if (clienteId != null) 'cliente_id': clienteId,
      if (montoInicial != null) 'monto_inicial': montoInicial,
      if (saldoPendiente != null) 'saldo_pendiente': saldoPendiente,
      if (estado != null) 'estado': estado,
      if (fechaInicio != null) 'fecha_inicio': fechaInicio,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FiadosCompanion copyWith({
    Value<String>? id,
    Value<String>? tiendaId,
    Value<String>? clienteId,
    Value<Decimal>? montoInicial,
    Value<Decimal>? saldoPendiente,
    Value<String>? estado,
    Value<DateTime>? fechaInicio,
    Value<int>? rowid,
  }) {
    return FiadosCompanion(
      id: id ?? this.id,
      tiendaId: tiendaId ?? this.tiendaId,
      clienteId: clienteId ?? this.clienteId,
      montoInicial: montoInicial ?? this.montoInicial,
      saldoPendiente: saldoPendiente ?? this.saldoPendiente,
      estado: estado ?? this.estado,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tiendaId.present) {
      map['tienda_id'] = Variable<String>(tiendaId.value);
    }
    if (clienteId.present) {
      map['cliente_id'] = Variable<String>(clienteId.value);
    }
    if (montoInicial.present) {
      map['monto_inicial'] = Variable<String>(
        $FiadosTable.$convertermontoInicial.toSql(montoInicial.value),
      );
    }
    if (saldoPendiente.present) {
      map['saldo_pendiente'] = Variable<String>(
        $FiadosTable.$convertersaldoPendiente.toSql(saldoPendiente.value),
      );
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (fechaInicio.present) {
      map['fecha_inicio'] = Variable<DateTime>(
        $FiadosTable.$converterfechaInicio.toSql(fechaInicio.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FiadosCompanion(')
          ..write('id: $id, ')
          ..write('tiendaId: $tiendaId, ')
          ..write('clienteId: $clienteId, ')
          ..write('montoInicial: $montoInicial, ')
          ..write('saldoPendiente: $saldoPendiente, ')
          ..write('estado: $estado, ')
          ..write('fechaInicio: $fechaInicio, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BaseLocalDrift extends GeneratedDatabase {
  _$BaseLocalDrift(QueryExecutor e) : super(e);
  $BaseLocalDriftManager get managers => $BaseLocalDriftManager(this);
  late final $ColaPendientesTable colaPendientes = $ColaPendientesTable(this);
  late final $ProductosTable productos = $ProductosTable(this);
  late final $ItemsInventarioTable itemsInventario = $ItemsInventarioTable(
    this,
  );
  late final $VentasTable ventas = $VentasTable(this);
  late final $MovimientosInventarioTable movimientosInventario =
      $MovimientosInventarioTable(this);
  late final $CajasTable cajas = $CajasTable(this);
  late final $MovimientosCajaTable movimientosCaja = $MovimientosCajaTable(
    this,
  );
  late final $FormasPagoTable formasPago = $FormasPagoTable(this);
  late final $AlertasReabastecimientoTable alertasReabastecimiento =
      $AlertasReabastecimientoTable(this);
  late final $VentasPerdidasTable ventasPerdidas = $VentasPerdidasTable(this);
  late final $ClientesTable clientes = $ClientesTable(this);
  late final $FiadosTable fiados = $FiadosTable(this);
  late final Index productosTiendaCodigoIdx = Index(
    'productos_tienda_codigo_idx',
    'CREATE INDEX productos_tienda_codigo_idx ON productos (tienda_id, codigo)',
  );
  late final Index productosTiendaNombreIdx = Index(
    'productos_tienda_nombre_idx',
    'CREATE INDEX productos_tienda_nombre_idx ON productos (tienda_id, nombre_normalizado)',
  );
  late final Index itemsInventarioTiendaIdx = Index(
    'items_inventario_tienda_idx',
    'CREATE INDEX items_inventario_tienda_idx ON items_inventario (tienda_id)',
  );
  late final Index movimientosInventarioTiendaIdx = Index(
    'movimientos_inventario_tienda_idx',
    'CREATE INDEX movimientos_inventario_tienda_idx ON movimientos_inventario (tienda_id)',
  );
  late final Index movimientosInventarioItemTipoFechaIdx = Index(
    'movimientos_inventario_item_tipo_fecha_idx',
    'CREATE INDEX movimientos_inventario_item_tipo_fecha_idx ON movimientos_inventario (item_id, tipo, fecha)',
  );
  late final Index cajasTiendaIdx = Index(
    'cajas_tienda_idx',
    'CREATE INDEX cajas_tienda_idx ON cajas (tienda_id)',
  );
  late final Index movimientosCajaTiendaIdx = Index(
    'movimientos_caja_tienda_idx',
    'CREATE INDEX movimientos_caja_tienda_idx ON movimientos_caja (tienda_id)',
  );
  late final Index movimientosCajaCajaIdx = Index(
    'movimientos_caja_caja_idx',
    'CREATE INDEX movimientos_caja_caja_idx ON movimientos_caja (caja_id)',
  );
  late final Index ventasTiendaFechaIdx = Index(
    'ventas_tienda_fecha_idx',
    'CREATE INDEX ventas_tienda_fecha_idx ON ventas (tienda_id, fecha)',
  );
  late final Index formasPagoTiendaIdx = Index(
    'formas_pago_tienda_idx',
    'CREATE INDEX formas_pago_tienda_idx ON formas_pago (tienda_id)',
  );
  late final Index formasPagoVentaIdx = Index(
    'formas_pago_venta_idx',
    'CREATE INDEX formas_pago_venta_idx ON formas_pago (venta_id)',
  );
  late final Index alertasReabastecimientoTiendaFechaIdx = Index(
    'alertas_reabastecimiento_tienda_fecha_idx',
    'CREATE INDEX alertas_reabastecimiento_tienda_fecha_idx ON alertas_reabastecimiento (tienda_id, fecha)',
  );
  late final Index ventasPerdidasTiendaFechaIdx = Index(
    'ventas_perdidas_tienda_fecha_idx',
    'CREATE INDEX ventas_perdidas_tienda_fecha_idx ON ventas_perdidas (tienda_id, fecha)',
  );
  late final Index ventasPerdidasProductoFechaIdx = Index(
    'ventas_perdidas_producto_fecha_idx',
    'CREATE INDEX ventas_perdidas_producto_fecha_idx ON ventas_perdidas (producto_id, fecha)',
  );
  late final Index clientesTiendaNombreIdx = Index(
    'clientes_tienda_nombre_idx',
    'CREATE INDEX clientes_tienda_nombre_idx ON clientes (tienda_id, nombre_normalizado)',
  );
  late final Index fiadosTiendaIdx = Index(
    'fiados_tienda_idx',
    'CREATE INDEX fiados_tienda_idx ON fiados (tienda_id)',
  );
  late final Index fiadosClienteIdx = Index(
    'fiados_cliente_idx',
    'CREATE INDEX fiados_cliente_idx ON fiados (cliente_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    colaPendientes,
    productos,
    itemsInventario,
    ventas,
    movimientosInventario,
    cajas,
    movimientosCaja,
    formasPago,
    alertasReabastecimiento,
    ventasPerdidas,
    clientes,
    fiados,
    productosTiendaCodigoIdx,
    productosTiendaNombreIdx,
    itemsInventarioTiendaIdx,
    movimientosInventarioTiendaIdx,
    movimientosInventarioItemTipoFechaIdx,
    cajasTiendaIdx,
    movimientosCajaTiendaIdx,
    movimientosCajaCajaIdx,
    ventasTiendaFechaIdx,
    formasPagoTiendaIdx,
    formasPagoVentaIdx,
    alertasReabastecimientoTiendaFechaIdx,
    ventasPerdidasTiendaFechaIdx,
    ventasPerdidasProductoFechaIdx,
    clientesTiendaNombreIdx,
    fiadosTiendaIdx,
    fiadosClienteIdx,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ColaPendientesTableCreateCompanionBuilder =
    ColaPendientesCompanion Function({
      required String id,
      required String tiendaId,
      required String tabla,
      required String registroId,
      required String operacion,
      Value<int> intentos,
      required DateTime creadoEn,
      Value<int> rowid,
    });
typedef $$ColaPendientesTableUpdateCompanionBuilder =
    ColaPendientesCompanion Function({
      Value<String> id,
      Value<String> tiendaId,
      Value<String> tabla,
      Value<String> registroId,
      Value<String> operacion,
      Value<int> intentos,
      Value<DateTime> creadoEn,
      Value<int> rowid,
    });

class $$ColaPendientesTableFilterComposer
    extends Composer<_$BaseLocalDrift, $ColaPendientesTable> {
  $$ColaPendientesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tabla => $composableBuilder(
    column: $table.tabla,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registroId => $composableBuilder(
    column: $table.registroId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operacion => $composableBuilder(
    column: $table.operacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intentos => $composableBuilder(
    column: $table.intentos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get creadoEn =>
      $composableBuilder(
        column: $table.creadoEn,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$ColaPendientesTableOrderingComposer
    extends Composer<_$BaseLocalDrift, $ColaPendientesTable> {
  $$ColaPendientesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tabla => $composableBuilder(
    column: $table.tabla,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registroId => $composableBuilder(
    column: $table.registroId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operacion => $composableBuilder(
    column: $table.operacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intentos => $composableBuilder(
    column: $table.intentos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ColaPendientesTableAnnotationComposer
    extends Composer<_$BaseLocalDrift, $ColaPendientesTable> {
  $$ColaPendientesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tiendaId =>
      $composableBuilder(column: $table.tiendaId, builder: (column) => column);

  GeneratedColumn<String> get tabla =>
      $composableBuilder(column: $table.tabla, builder: (column) => column);

  GeneratedColumn<String> get registroId => $composableBuilder(
    column: $table.registroId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operacion =>
      $composableBuilder(column: $table.operacion, builder: (column) => column);

  GeneratedColumn<int> get intentos =>
      $composableBuilder(column: $table.intentos, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);
}

class $$ColaPendientesTableTableManager
    extends
        RootTableManager<
          _$BaseLocalDrift,
          $ColaPendientesTable,
          EntradaCola,
          $$ColaPendientesTableFilterComposer,
          $$ColaPendientesTableOrderingComposer,
          $$ColaPendientesTableAnnotationComposer,
          $$ColaPendientesTableCreateCompanionBuilder,
          $$ColaPendientesTableUpdateCompanionBuilder,
          (
            EntradaCola,
            BaseReferences<_$BaseLocalDrift, $ColaPendientesTable, EntradaCola>,
          ),
          EntradaCola,
          PrefetchHooks Function()
        > {
  $$ColaPendientesTableTableManager(
    _$BaseLocalDrift db,
    $ColaPendientesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ColaPendientesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ColaPendientesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ColaPendientesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tiendaId = const Value.absent(),
                Value<String> tabla = const Value.absent(),
                Value<String> registroId = const Value.absent(),
                Value<String> operacion = const Value.absent(),
                Value<int> intentos = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ColaPendientesCompanion(
                id: id,
                tiendaId: tiendaId,
                tabla: tabla,
                registroId: registroId,
                operacion: operacion,
                intentos: intentos,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tiendaId,
                required String tabla,
                required String registroId,
                required String operacion,
                Value<int> intentos = const Value.absent(),
                required DateTime creadoEn,
                Value<int> rowid = const Value.absent(),
              }) => ColaPendientesCompanion.insert(
                id: id,
                tiendaId: tiendaId,
                tabla: tabla,
                registroId: registroId,
                operacion: operacion,
                intentos: intentos,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ColaPendientesTable, EntradaCola>(table),
                  BaseReferences<
                    _$BaseLocalDrift,
                    $ColaPendientesTable,
                    EntradaCola
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ColaPendientesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocalDrift,
      $ColaPendientesTable,
      EntradaCola,
      $$ColaPendientesTableFilterComposer,
      $$ColaPendientesTableOrderingComposer,
      $$ColaPendientesTableAnnotationComposer,
      $$ColaPendientesTableCreateCompanionBuilder,
      $$ColaPendientesTableUpdateCompanionBuilder,
      (
        EntradaCola,
        BaseReferences<_$BaseLocalDrift, $ColaPendientesTable, EntradaCola>,
      ),
      EntradaCola,
      PrefetchHooks Function()
    >;
typedef $$ProductosTableCreateCompanionBuilder = ProductosCompanion Function({
  required String id,
  required String tiendaId,
  required String codigo,
  required String nombre,
  required String nombreNormalizado,
  required String unidadMedida,
  Value<Decimal?> precioCompra,
  required Decimal precioVenta,
  required DateTime actualizadoEn,
  Value<int> rowid,
});
typedef $$ProductosTableUpdateCompanionBuilder = ProductosCompanion Function({
  Value<String> id,
  Value<String> tiendaId,
  Value<String> codigo,
  Value<String> nombre,
  Value<String> nombreNormalizado,
  Value<String> unidadMedida,
  Value<Decimal?> precioCompra,
  Value<Decimal> precioVenta,
  Value<DateTime> actualizadoEn,
  Value<int> rowid,
});

final class $$ProductosTableReferences
    extends BaseReferences<_$BaseLocalDrift, $ProductosTable, FilaProducto> {
  $$ProductosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ItemsInventarioTable, List<FilaItemInventario>>
  _itemsInventarioRefsTable(_$BaseLocalDrift db) =>
      MultiTypedResultKey.fromTable(
        db.itemsInventario,
        aliasName: 'productos__id__items_inventario__producto_id',
      );

  $$ItemsInventarioTableProcessedTableManager get itemsInventarioRefs {
    final manager = $$ItemsInventarioTableTableManager(
      $_db,
      $_db.itemsInventario,
    ).filter((f) => f.productoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _itemsInventarioRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VentasPerdidasTable, List<FilaVentaPerdida>>
  _ventasPerdidasRefsTable(_$BaseLocalDrift db) =>
      MultiTypedResultKey.fromTable(
        db.ventasPerdidas,
        aliasName: 'productos__id__ventas_perdidas__producto_id',
      );

  $$VentasPerdidasTableProcessedTableManager get ventasPerdidasRefs {
    final manager = $$VentasPerdidasTableTableManager(
      $_db,
      $_db.ventasPerdidas,
    ).filter((f) => f.productoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ventasPerdidasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductosTableFilterComposer
    extends Composer<_$BaseLocalDrift, $ProductosTable> {
  $$ProductosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombreNormalizado => $composableBuilder(
    column: $table.nombreNormalizado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unidadMedida => $composableBuilder(
    column: $table.unidadMedida,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String> get precioCompra =>
      $composableBuilder(
        column: $table.precioCompra,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get precioVenta =>
      $composableBuilder(
        column: $table.precioVenta,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  Expression<bool> itemsInventarioRefs(
    Expression<bool> Function($$ItemsInventarioTableFilterComposer f) f,
  ) {
    final $$ItemsInventarioTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemsInventario,
      getReferencedColumn: (t) => t.productoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsInventarioTableFilterComposer(
            $db: $db,
            $table: $db.itemsInventario,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ventasPerdidasRefs(
    Expression<bool> Function($$VentasPerdidasTableFilterComposer f) f,
  ) {
    final $$VentasPerdidasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ventasPerdidas,
      getReferencedColumn: (t) => t.productoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasPerdidasTableFilterComposer(
            $db: $db,
            $table: $db.ventasPerdidas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductosTableOrderingComposer
    extends Composer<_$BaseLocalDrift, $ProductosTable> {
  $$ProductosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombreNormalizado => $composableBuilder(
    column: $table.nombreNormalizado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unidadMedida => $composableBuilder(
    column: $table.unidadMedida,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get precioCompra => $composableBuilder(
    column: $table.precioCompra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get precioVenta => $composableBuilder(
    column: $table.precioVenta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductosTableAnnotationComposer
    extends Composer<_$BaseLocalDrift, $ProductosTable> {
  $$ProductosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tiendaId =>
      $composableBuilder(column: $table.tiendaId, builder: (column) => column);

  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get nombreNormalizado => $composableBuilder(
    column: $table.nombreNormalizado,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unidadMedida => $composableBuilder(
    column: $table.unidadMedida,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal?, String> get precioCompra =>
      $composableBuilder(
        column: $table.precioCompra,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal, String> get precioVenta =>
      $composableBuilder(
        column: $table.precioVenta,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get actualizadoEn =>
      $composableBuilder(
        column: $table.actualizadoEn,
        builder: (column) => column,
      );

  Expression<T> itemsInventarioRefs<T extends Object>(
    Expression<T> Function($$ItemsInventarioTableAnnotationComposer a) f,
  ) {
    final $$ItemsInventarioTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemsInventario,
      getReferencedColumn: (t) => t.productoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsInventarioTableAnnotationComposer(
            $db: $db,
            $table: $db.itemsInventario,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ventasPerdidasRefs<T extends Object>(
    Expression<T> Function($$VentasPerdidasTableAnnotationComposer a) f,
  ) {
    final $$VentasPerdidasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ventasPerdidas,
      getReferencedColumn: (t) => t.productoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasPerdidasTableAnnotationComposer(
            $db: $db,
            $table: $db.ventasPerdidas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductosTableTableManager
    extends
        RootTableManager<
          _$BaseLocalDrift,
          $ProductosTable,
          FilaProducto,
          $$ProductosTableFilterComposer,
          $$ProductosTableOrderingComposer,
          $$ProductosTableAnnotationComposer,
          $$ProductosTableCreateCompanionBuilder,
          $$ProductosTableUpdateCompanionBuilder,
          (FilaProducto, $$ProductosTableReferences),
          FilaProducto,
          PrefetchHooks Function({
            bool itemsInventarioRefs,
            bool ventasPerdidasRefs,
          })
        > {
  $$ProductosTableTableManager(_$BaseLocalDrift db, $ProductosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tiendaId = const Value.absent(),
                Value<String> codigo = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> nombreNormalizado = const Value.absent(),
                Value<String> unidadMedida = const Value.absent(),
                Value<Decimal?> precioCompra = const Value.absent(),
                Value<Decimal> precioVenta = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductosCompanion(
                id: id,
                tiendaId: tiendaId,
                codigo: codigo,
                nombre: nombre,
                nombreNormalizado: nombreNormalizado,
                unidadMedida: unidadMedida,
                precioCompra: precioCompra,
                precioVenta: precioVenta,
                actualizadoEn: actualizadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tiendaId,
                required String codigo,
                required String nombre,
                required String nombreNormalizado,
                required String unidadMedida,
                Value<Decimal?> precioCompra = const Value.absent(),
                required Decimal precioVenta,
                required DateTime actualizadoEn,
                Value<int> rowid = const Value.absent(),
              }) => ProductosCompanion.insert(
                id: id,
                tiendaId: tiendaId,
                codigo: codigo,
                nombre: nombre,
                nombreNormalizado: nombreNormalizado,
                unidadMedida: unidadMedida,
                precioCompra: precioCompra,
                precioVenta: precioVenta,
                actualizadoEn: actualizadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductosTable, FilaProducto>(table),
                  $$ProductosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({itemsInventarioRefs = false, ventasPerdidasRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (itemsInventarioRefs) db.itemsInventario,
                    if (ventasPerdidasRefs) db.ventasPerdidas,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (itemsInventarioRefs)
                        await $_getPrefetchedDataByColumns<
                          FilaProducto,
                          $ProductosTable,
                          FilaItemInventario,
                          $ItemsInventarioTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProductosTableReferences
                              ._itemsInventarioRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductosTableReferences(
                                db,
                                table,
                                p0,
                              ).itemsInventarioRefs,
                          currentColumn: 'id',
                          referencedColumn: 'producto_id',
                          typedResults: items,
                        ),
                      if (ventasPerdidasRefs)
                        await $_getPrefetchedDataByColumns<
                          FilaProducto,
                          $ProductosTable,
                          FilaVentaPerdida,
                          $VentasPerdidasTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProductosTableReferences
                              ._ventasPerdidasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductosTableReferences(
                                db,
                                table,
                                p0,
                              ).ventasPerdidasRefs,
                          currentColumn: 'id',
                          referencedColumn: 'producto_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProductosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocalDrift,
      $ProductosTable,
      FilaProducto,
      $$ProductosTableFilterComposer,
      $$ProductosTableOrderingComposer,
      $$ProductosTableAnnotationComposer,
      $$ProductosTableCreateCompanionBuilder,
      $$ProductosTableUpdateCompanionBuilder,
      (FilaProducto, $$ProductosTableReferences),
      FilaProducto,
      PrefetchHooks Function({
        bool itemsInventarioRefs,
        bool ventasPerdidasRefs,
      })
    >;
typedef $$ItemsInventarioTableCreateCompanionBuilder =
    ItemsInventarioCompanion Function({
      required String id,
      required String tiendaId,
      required String productoId,
      required Decimal stockActual,
      Value<int> rowid,
    });
typedef $$ItemsInventarioTableUpdateCompanionBuilder =
    ItemsInventarioCompanion Function({
      Value<String> id,
      Value<String> tiendaId,
      Value<String> productoId,
      Value<Decimal> stockActual,
      Value<int> rowid,
    });

final class $$ItemsInventarioTableReferences
    extends
        BaseReferences<
          _$BaseLocalDrift,
          $ItemsInventarioTable,
          FilaItemInventario
        > {
  $$ItemsInventarioTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductosTable _productoIdTable(_$BaseLocalDrift db) =>
      db.productos.createAlias('items_inventario__producto_id__productos__id');

  $$ProductosTableProcessedTableManager get productoId {
    final $_column = $_itemColumn<String>('producto_id')!;

    final manager = $$ProductosTableTableManager(
      $_db,
      $_db.productos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $MovimientosInventarioTable,
    List<FilaMovimientoInventario>
  >
  _movimientosInventarioRefsTable(_$BaseLocalDrift db) =>
      MultiTypedResultKey.fromTable(
        db.movimientosInventario,
        aliasName: 'items_inventario__id__movimientos_inventario__item_id',
      );

  $$MovimientosInventarioTableProcessedTableManager
  get movimientosInventarioRefs {
    final manager = $$MovimientosInventarioTableTableManager(
      $_db,
      $_db.movimientosInventario,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _movimientosInventarioRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AlertasReabastecimientoTable, List<FilaAlerta>>
  _alertasReabastecimientoRefsTable(_$BaseLocalDrift db) =>
      MultiTypedResultKey.fromTable(
        db.alertasReabastecimiento,
        aliasName: 'items_inventario__id__alertas_reabastecimiento__item_id',
      );

  $$AlertasReabastecimientoTableProcessedTableManager
  get alertasReabastecimientoRefs {
    final manager = $$AlertasReabastecimientoTableTableManager(
      $_db,
      $_db.alertasReabastecimiento,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _alertasReabastecimientoRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemsInventarioTableFilterComposer
    extends Composer<_$BaseLocalDrift, $ItemsInventarioTable> {
  $$ItemsInventarioTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get stockActual =>
      $composableBuilder(
        column: $table.stockActual,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$ProductosTableFilterComposer get productoId {
    final $$ProductosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productoId,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableFilterComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> movimientosInventarioRefs(
    Expression<bool> Function($$MovimientosInventarioTableFilterComposer f) f,
  ) {
    final $$MovimientosInventarioTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.movimientosInventario,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MovimientosInventarioTableFilterComposer(
                $db: $db,
                $table: $db.movimientosInventario,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> alertasReabastecimientoRefs(
    Expression<bool> Function($$AlertasReabastecimientoTableFilterComposer f) f,
  ) {
    final $$AlertasReabastecimientoTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.alertasReabastecimiento,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AlertasReabastecimientoTableFilterComposer(
                $db: $db,
                $table: $db.alertasReabastecimiento,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ItemsInventarioTableOrderingComposer
    extends Composer<_$BaseLocalDrift, $ItemsInventarioTable> {
  $$ItemsInventarioTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stockActual => $composableBuilder(
    column: $table.stockActual,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductosTableOrderingComposer get productoId {
    final $$ProductosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productoId,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableOrderingComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsInventarioTableAnnotationComposer
    extends Composer<_$BaseLocalDrift, $ItemsInventarioTable> {
  $$ItemsInventarioTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tiendaId =>
      $composableBuilder(column: $table.tiendaId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get stockActual =>
      $composableBuilder(
        column: $table.stockActual,
        builder: (column) => column,
      );

  $$ProductosTableAnnotationComposer get productoId {
    final $$ProductosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productoId,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableAnnotationComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> movimientosInventarioRefs<T extends Object>(
    Expression<T> Function($$MovimientosInventarioTableAnnotationComposer a) f,
  ) {
    final $$MovimientosInventarioTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.movimientosInventario,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MovimientosInventarioTableAnnotationComposer(
                $db: $db,
                $table: $db.movimientosInventario,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> alertasReabastecimientoRefs<T extends Object>(
    Expression<T> Function($$AlertasReabastecimientoTableAnnotationComposer a)
    f,
  ) {
    final $$AlertasReabastecimientoTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.alertasReabastecimiento,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AlertasReabastecimientoTableAnnotationComposer(
                $db: $db,
                $table: $db.alertasReabastecimiento,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ItemsInventarioTableTableManager
    extends
        RootTableManager<
          _$BaseLocalDrift,
          $ItemsInventarioTable,
          FilaItemInventario,
          $$ItemsInventarioTableFilterComposer,
          $$ItemsInventarioTableOrderingComposer,
          $$ItemsInventarioTableAnnotationComposer,
          $$ItemsInventarioTableCreateCompanionBuilder,
          $$ItemsInventarioTableUpdateCompanionBuilder,
          (FilaItemInventario, $$ItemsInventarioTableReferences),
          FilaItemInventario,
          PrefetchHooks Function({
            bool productoId,
            bool movimientosInventarioRefs,
            bool alertasReabastecimientoRefs,
          })
        > {
  $$ItemsInventarioTableTableManager(
    _$BaseLocalDrift db,
    $ItemsInventarioTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsInventarioTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsInventarioTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsInventarioTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tiendaId = const Value.absent(),
                Value<String> productoId = const Value.absent(),
                Value<Decimal> stockActual = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsInventarioCompanion(
                id: id,
                tiendaId: tiendaId,
                productoId: productoId,
                stockActual: stockActual,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tiendaId,
                required String productoId,
                required Decimal stockActual,
                Value<int> rowid = const Value.absent(),
              }) => ItemsInventarioCompanion.insert(
                id: id,
                tiendaId: tiendaId,
                productoId: productoId,
                stockActual: stockActual,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsInventarioTable, FilaItemInventario>(table),
                  $$ItemsInventarioTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                productoId = false,
                movimientosInventarioRefs = false,
                alertasReabastecimientoRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (movimientosInventarioRefs) db.movimientosInventario,
                    if (alertasReabastecimientoRefs) db.alertasReabastecimiento,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (productoId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.productoId,
                            referencedTable: $$ItemsInventarioTableReferences
                                ._productoIdTable(db),
                            referencedColumn: $$ItemsInventarioTableReferences
                                ._productoIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (movimientosInventarioRefs)
                        await $_getPrefetchedDataByColumns<
                          FilaItemInventario,
                          $ItemsInventarioTable,
                          FilaMovimientoInventario,
                          $MovimientosInventarioTable
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsInventarioTableReferences
                              ._movimientosInventarioRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsInventarioTableReferences(
                                db,
                                table,
                                p0,
                              ).movimientosInventarioRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                      if (alertasReabastecimientoRefs)
                        await $_getPrefetchedDataByColumns<
                          FilaItemInventario,
                          $ItemsInventarioTable,
                          FilaAlerta,
                          $AlertasReabastecimientoTable
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsInventarioTableReferences
                              ._alertasReabastecimientoRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsInventarioTableReferences(
                                db,
                                table,
                                p0,
                              ).alertasReabastecimientoRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ItemsInventarioTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocalDrift,
      $ItemsInventarioTable,
      FilaItemInventario,
      $$ItemsInventarioTableFilterComposer,
      $$ItemsInventarioTableOrderingComposer,
      $$ItemsInventarioTableAnnotationComposer,
      $$ItemsInventarioTableCreateCompanionBuilder,
      $$ItemsInventarioTableUpdateCompanionBuilder,
      (FilaItemInventario, $$ItemsInventarioTableReferences),
      FilaItemInventario,
      PrefetchHooks Function({
        bool productoId,
        bool movimientosInventarioRefs,
        bool alertasReabastecimientoRefs,
      })
    >;
typedef $$VentasTableCreateCompanionBuilder = VentasCompanion Function({
  required String id,
  required String tiendaId,
  required DateTime fecha,
  required Decimal total,
  Value<int> rowid,
});
typedef $$VentasTableUpdateCompanionBuilder = VentasCompanion Function({
  Value<String> id,
  Value<String> tiendaId,
  Value<DateTime> fecha,
  Value<Decimal> total,
  Value<int> rowid,
});

final class $$VentasTableReferences
    extends BaseReferences<_$BaseLocalDrift, $VentasTable, FilaVenta> {
  $$VentasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $MovimientosInventarioTable,
    List<FilaMovimientoInventario>
  >
  _movimientosInventarioRefsTable(_$BaseLocalDrift db) =>
      MultiTypedResultKey.fromTable(
        db.movimientosInventario,
        aliasName: 'ventas__id__movimientos_inventario__venta_id',
      );

  $$MovimientosInventarioTableProcessedTableManager
  get movimientosInventarioRefs {
    final manager = $$MovimientosInventarioTableTableManager(
      $_db,
      $_db.movimientosInventario,
    ).filter((f) => f.ventaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _movimientosInventarioRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FormasPagoTable, List<FilaFormaPago>>
  _formasPagoRefsTable(_$BaseLocalDrift db) => MultiTypedResultKey.fromTable(
    db.formasPago,
    aliasName: 'ventas__id__formas_pago__venta_id',
  );

  $$FormasPagoTableProcessedTableManager get formasPagoRefs {
    final manager = $$FormasPagoTableTableManager(
      $_db,
      $_db.formasPago,
    ).filter((f) => f.ventaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_formasPagoRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VentasTableFilterComposer
    extends Composer<_$BaseLocalDrift, $VentasTable> {
  $$VentasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get fecha =>
      $composableBuilder(
        column: $table.fecha,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get total =>
      $composableBuilder(
        column: $table.total,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> movimientosInventarioRefs(
    Expression<bool> Function($$MovimientosInventarioTableFilterComposer f) f,
  ) {
    final $$MovimientosInventarioTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.movimientosInventario,
          getReferencedColumn: (t) => t.ventaId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MovimientosInventarioTableFilterComposer(
                $db: $db,
                $table: $db.movimientosInventario,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> formasPagoRefs(
    Expression<bool> Function($$FormasPagoTableFilterComposer f) f,
  ) {
    final $$FormasPagoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.formasPago,
      getReferencedColumn: (t) => t.ventaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormasPagoTableFilterComposer(
            $db: $db,
            $table: $db.formasPago,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VentasTableOrderingComposer
    extends Composer<_$BaseLocalDrift, $VentasTable> {
  $$VentasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VentasTableAnnotationComposer
    extends Composer<_$BaseLocalDrift, $VentasTable> {
  $$VentasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tiendaId =>
      $composableBuilder(column: $table.tiendaId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  Expression<T> movimientosInventarioRefs<T extends Object>(
    Expression<T> Function($$MovimientosInventarioTableAnnotationComposer a) f,
  ) {
    final $$MovimientosInventarioTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.movimientosInventario,
          getReferencedColumn: (t) => t.ventaId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MovimientosInventarioTableAnnotationComposer(
                $db: $db,
                $table: $db.movimientosInventario,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> formasPagoRefs<T extends Object>(
    Expression<T> Function($$FormasPagoTableAnnotationComposer a) f,
  ) {
    final $$FormasPagoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.formasPago,
      getReferencedColumn: (t) => t.ventaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormasPagoTableAnnotationComposer(
            $db: $db,
            $table: $db.formasPago,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VentasTableTableManager
    extends
        RootTableManager<
          _$BaseLocalDrift,
          $VentasTable,
          FilaVenta,
          $$VentasTableFilterComposer,
          $$VentasTableOrderingComposer,
          $$VentasTableAnnotationComposer,
          $$VentasTableCreateCompanionBuilder,
          $$VentasTableUpdateCompanionBuilder,
          (FilaVenta, $$VentasTableReferences),
          FilaVenta,
          PrefetchHooks Function({
            bool movimientosInventarioRefs,
            bool formasPagoRefs,
          })
        > {
  $$VentasTableTableManager(_$BaseLocalDrift db, $VentasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VentasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VentasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VentasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tiendaId = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<Decimal> total = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VentasCompanion(
                id: id,
                tiendaId: tiendaId,
                fecha: fecha,
                total: total,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tiendaId,
                required DateTime fecha,
                required Decimal total,
                Value<int> rowid = const Value.absent(),
              }) => VentasCompanion.insert(
                id: id,
                tiendaId: tiendaId,
                fecha: fecha,
                total: total,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VentasTable, FilaVenta>(table),
                  $$VentasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({movimientosInventarioRefs = false, formasPagoRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (movimientosInventarioRefs) db.movimientosInventario,
                    if (formasPagoRefs) db.formasPago,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (movimientosInventarioRefs)
                        await $_getPrefetchedDataByColumns<
                          FilaVenta,
                          $VentasTable,
                          FilaMovimientoInventario,
                          $MovimientosInventarioTable
                        >(
                          currentTable: table,
                          referencedTable: $$VentasTableReferences
                              ._movimientosInventarioRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VentasTableReferences(
                                db,
                                table,
                                p0,
                              ).movimientosInventarioRefs,
                          currentColumn: 'id',
                          referencedColumn: 'venta_id',
                          typedResults: items,
                        ),
                      if (formasPagoRefs)
                        await $_getPrefetchedDataByColumns<
                          FilaVenta,
                          $VentasTable,
                          FilaFormaPago,
                          $FormasPagoTable
                        >(
                          currentTable: table,
                          referencedTable: $$VentasTableReferences
                              ._formasPagoRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VentasTableReferences(
                                db,
                                table,
                                p0,
                              ).formasPagoRefs,
                          currentColumn: 'id',
                          referencedColumn: 'venta_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VentasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocalDrift,
      $VentasTable,
      FilaVenta,
      $$VentasTableFilterComposer,
      $$VentasTableOrderingComposer,
      $$VentasTableAnnotationComposer,
      $$VentasTableCreateCompanionBuilder,
      $$VentasTableUpdateCompanionBuilder,
      (FilaVenta, $$VentasTableReferences),
      FilaVenta,
      PrefetchHooks Function({
        bool movimientosInventarioRefs,
        bool formasPagoRefs,
      })
    >;
typedef $$MovimientosInventarioTableCreateCompanionBuilder =
    MovimientosInventarioCompanion Function({
      required String id,
      required String tiendaId,
      required String itemId,
      required String tipo,
      required Decimal cantidad,
      required DateTime fecha,
      required String estado,
      Value<Decimal?> costoUnitario,
      Value<String?> numeroFactura,
      Value<String?> ventaId,
      Value<Decimal?> precioUnitario,
      Value<String?> motivo,
      Value<Decimal?> cantidadContada,
      Value<int> rowid,
    });
typedef $$MovimientosInventarioTableUpdateCompanionBuilder =
    MovimientosInventarioCompanion Function({
      Value<String> id,
      Value<String> tiendaId,
      Value<String> itemId,
      Value<String> tipo,
      Value<Decimal> cantidad,
      Value<DateTime> fecha,
      Value<String> estado,
      Value<Decimal?> costoUnitario,
      Value<String?> numeroFactura,
      Value<String?> ventaId,
      Value<Decimal?> precioUnitario,
      Value<String?> motivo,
      Value<Decimal?> cantidadContada,
      Value<int> rowid,
    });

final class $$MovimientosInventarioTableReferences
    extends
        BaseReferences<
          _$BaseLocalDrift,
          $MovimientosInventarioTable,
          FilaMovimientoInventario
        > {
  $$MovimientosInventarioTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ItemsInventarioTable _itemIdTable(_$BaseLocalDrift db) => db
      .itemsInventario
      .createAlias('movimientos_inventario__item_id__items_inventario__id');

  $$ItemsInventarioTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsInventarioTableTableManager(
      $_db,
      $_db.itemsInventario,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VentasTable _ventaIdTable(_$BaseLocalDrift db) =>
      db.ventas.createAlias('movimientos_inventario__venta_id__ventas__id');

  $$VentasTableProcessedTableManager? get ventaId {
    final $_column = $_itemColumn<String>('venta_id');
    if ($_column == null) return null;
    final manager = $$VentasTableTableManager(
      $_db,
      $_db.ventas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ventaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MovimientosInventarioTableFilterComposer
    extends Composer<_$BaseLocalDrift, $MovimientosInventarioTable> {
  $$MovimientosInventarioTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get cantidad =>
      $composableBuilder(
        column: $table.cantidad,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get fecha =>
      $composableBuilder(
        column: $table.fecha,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String> get costoUnitario =>
      $composableBuilder(
        column: $table.costoUnitario,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get numeroFactura => $composableBuilder(
    column: $table.numeroFactura,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String>
  get precioUnitario => $composableBuilder(
    column: $table.precioUnitario,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String>
  get cantidadContada => $composableBuilder(
    column: $table.cantidadContada,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$ItemsInventarioTableFilterComposer get itemId {
    final $$ItemsInventarioTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.itemsInventario,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsInventarioTableFilterComposer(
            $db: $db,
            $table: $db.itemsInventario,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VentasTableFilterComposer get ventaId {
    final $$VentasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ventaId,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableFilterComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimientosInventarioTableOrderingComposer
    extends Composer<_$BaseLocalDrift, $MovimientosInventarioTable> {
  $$MovimientosInventarioTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costoUnitario => $composableBuilder(
    column: $table.costoUnitario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numeroFactura => $composableBuilder(
    column: $table.numeroFactura,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get precioUnitario => $composableBuilder(
    column: $table.precioUnitario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cantidadContada => $composableBuilder(
    column: $table.cantidadContada,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsInventarioTableOrderingComposer get itemId {
    final $$ItemsInventarioTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.itemsInventario,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsInventarioTableOrderingComposer(
            $db: $db,
            $table: $db.itemsInventario,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VentasTableOrderingComposer get ventaId {
    final $$VentasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ventaId,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableOrderingComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimientosInventarioTableAnnotationComposer
    extends Composer<_$BaseLocalDrift, $MovimientosInventarioTable> {
  $$MovimientosInventarioTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tiendaId =>
      $composableBuilder(column: $table.tiendaId, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get cantidad =>
      $composableBuilder(column: $table.cantidad, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal?, String> get costoUnitario =>
      $composableBuilder(
        column: $table.costoUnitario,
        builder: (column) => column,
      );

  GeneratedColumn<String> get numeroFactura => $composableBuilder(
    column: $table.numeroFactura,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal?, String> get precioUnitario =>
      $composableBuilder(
        column: $table.precioUnitario,
        builder: (column) => column,
      );

  GeneratedColumn<String> get motivo =>
      $composableBuilder(column: $table.motivo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal?, String> get cantidadContada =>
      $composableBuilder(
        column: $table.cantidadContada,
        builder: (column) => column,
      );

  $$ItemsInventarioTableAnnotationComposer get itemId {
    final $$ItemsInventarioTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.itemsInventario,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsInventarioTableAnnotationComposer(
            $db: $db,
            $table: $db.itemsInventario,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VentasTableAnnotationComposer get ventaId {
    final $$VentasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ventaId,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableAnnotationComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimientosInventarioTableTableManager
    extends
        RootTableManager<
          _$BaseLocalDrift,
          $MovimientosInventarioTable,
          FilaMovimientoInventario,
          $$MovimientosInventarioTableFilterComposer,
          $$MovimientosInventarioTableOrderingComposer,
          $$MovimientosInventarioTableAnnotationComposer,
          $$MovimientosInventarioTableCreateCompanionBuilder,
          $$MovimientosInventarioTableUpdateCompanionBuilder,
          (FilaMovimientoInventario, $$MovimientosInventarioTableReferences),
          FilaMovimientoInventario,
          PrefetchHooks Function({bool itemId, bool ventaId})
        > {
  $$MovimientosInventarioTableTableManager(
    _$BaseLocalDrift db,
    $MovimientosInventarioTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovimientosInventarioTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MovimientosInventarioTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MovimientosInventarioTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tiendaId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<Decimal> cantidad = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<Decimal?> costoUnitario = const Value.absent(),
                Value<String?> numeroFactura = const Value.absent(),
                Value<String?> ventaId = const Value.absent(),
                Value<Decimal?> precioUnitario = const Value.absent(),
                Value<String?> motivo = const Value.absent(),
                Value<Decimal?> cantidadContada = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovimientosInventarioCompanion(
                id: id,
                tiendaId: tiendaId,
                itemId: itemId,
                tipo: tipo,
                cantidad: cantidad,
                fecha: fecha,
                estado: estado,
                costoUnitario: costoUnitario,
                numeroFactura: numeroFactura,
                ventaId: ventaId,
                precioUnitario: precioUnitario,
                motivo: motivo,
                cantidadContada: cantidadContada,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tiendaId,
                required String itemId,
                required String tipo,
                required Decimal cantidad,
                required DateTime fecha,
                required String estado,
                Value<Decimal?> costoUnitario = const Value.absent(),
                Value<String?> numeroFactura = const Value.absent(),
                Value<String?> ventaId = const Value.absent(),
                Value<Decimal?> precioUnitario = const Value.absent(),
                Value<String?> motivo = const Value.absent(),
                Value<Decimal?> cantidadContada = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovimientosInventarioCompanion.insert(
                id: id,
                tiendaId: tiendaId,
                itemId: itemId,
                tipo: tipo,
                cantidad: cantidad,
                fecha: fecha,
                estado: estado,
                costoUnitario: costoUnitario,
                numeroFactura: numeroFactura,
                ventaId: ventaId,
                precioUnitario: precioUnitario,
                motivo: motivo,
                cantidadContada: cantidadContada,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $MovimientosInventarioTable,
                    FilaMovimientoInventario
                  >(table),
                  $$MovimientosInventarioTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false, ventaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$MovimientosInventarioTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$MovimientosInventarioTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (ventaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.ventaId,
                        referencedTable: $$MovimientosInventarioTableReferences
                            ._ventaIdTable(db),
                        referencedColumn: $$MovimientosInventarioTableReferences
                            ._ventaIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MovimientosInventarioTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocalDrift,
      $MovimientosInventarioTable,
      FilaMovimientoInventario,
      $$MovimientosInventarioTableFilterComposer,
      $$MovimientosInventarioTableOrderingComposer,
      $$MovimientosInventarioTableAnnotationComposer,
      $$MovimientosInventarioTableCreateCompanionBuilder,
      $$MovimientosInventarioTableUpdateCompanionBuilder,
      (FilaMovimientoInventario, $$MovimientosInventarioTableReferences),
      FilaMovimientoInventario,
      PrefetchHooks Function({bool itemId, bool ventaId})
    >;
typedef $$CajasTableCreateCompanionBuilder = CajasCompanion Function({
  required String id,
  required String tiendaId,
  required String fecha,
  Value<int> rowid,
});
typedef $$CajasTableUpdateCompanionBuilder = CajasCompanion Function({
  Value<String> id,
  Value<String> tiendaId,
  Value<String> fecha,
  Value<int> rowid,
});

final class $$CajasTableReferences
    extends BaseReferences<_$BaseLocalDrift, $CajasTable, FilaCaja> {
  $$CajasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MovimientosCajaTable, List<FilaMovimientoCaja>>
  _movimientosCajaRefsTable(_$BaseLocalDrift db) =>
      MultiTypedResultKey.fromTable(
        db.movimientosCaja,
        aliasName: 'cajas__id__movimientos_caja__caja_id',
      );

  $$MovimientosCajaTableProcessedTableManager get movimientosCajaRefs {
    final manager = $$MovimientosCajaTableTableManager(
      $_db,
      $_db.movimientosCaja,
    ).filter((f) => f.cajaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _movimientosCajaRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CajasTableFilterComposer
    extends Composer<_$BaseLocalDrift, $CajasTable> {
  $$CajasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> movimientosCajaRefs(
    Expression<bool> Function($$MovimientosCajaTableFilterComposer f) f,
  ) {
    final $$MovimientosCajaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimientosCaja,
      getReferencedColumn: (t) => t.cajaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosCajaTableFilterComposer(
            $db: $db,
            $table: $db.movimientosCaja,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CajasTableOrderingComposer
    extends Composer<_$BaseLocalDrift, $CajasTable> {
  $$CajasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CajasTableAnnotationComposer
    extends Composer<_$BaseLocalDrift, $CajasTable> {
  $$CajasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tiendaId =>
      $composableBuilder(column: $table.tiendaId, builder: (column) => column);

  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  Expression<T> movimientosCajaRefs<T extends Object>(
    Expression<T> Function($$MovimientosCajaTableAnnotationComposer a) f,
  ) {
    final $$MovimientosCajaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimientosCaja,
      getReferencedColumn: (t) => t.cajaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosCajaTableAnnotationComposer(
            $db: $db,
            $table: $db.movimientosCaja,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CajasTableTableManager
    extends
        RootTableManager<
          _$BaseLocalDrift,
          $CajasTable,
          FilaCaja,
          $$CajasTableFilterComposer,
          $$CajasTableOrderingComposer,
          $$CajasTableAnnotationComposer,
          $$CajasTableCreateCompanionBuilder,
          $$CajasTableUpdateCompanionBuilder,
          (FilaCaja, $$CajasTableReferences),
          FilaCaja,
          PrefetchHooks Function({bool movimientosCajaRefs})
        > {
  $$CajasTableTableManager(_$BaseLocalDrift db, $CajasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CajasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CajasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CajasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tiendaId = const Value.absent(),
                Value<String> fecha = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CajasCompanion(
                id: id,
                tiendaId: tiendaId,
                fecha: fecha,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tiendaId,
                required String fecha,
                Value<int> rowid = const Value.absent(),
              }) => CajasCompanion.insert(
                id: id,
                tiendaId: tiendaId,
                fecha: fecha,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CajasTable, FilaCaja>(table),
                  $$CajasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({movimientosCajaRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (movimientosCajaRefs) db.movimientosCaja,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (movimientosCajaRefs)
                    await $_getPrefetchedDataByColumns<
                      FilaCaja,
                      $CajasTable,
                      FilaMovimientoCaja,
                      $MovimientosCajaTable
                    >(
                      currentTable: table,
                      referencedTable: $$CajasTableReferences
                          ._movimientosCajaRefsTable(db),
                      managerFromTypedResult: (p0) => $$CajasTableReferences(
                        db,
                        table,
                        p0,
                      ).movimientosCajaRefs,
                      currentColumn: 'id',
                      referencedColumn: 'caja_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CajasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocalDrift,
      $CajasTable,
      FilaCaja,
      $$CajasTableFilterComposer,
      $$CajasTableOrderingComposer,
      $$CajasTableAnnotationComposer,
      $$CajasTableCreateCompanionBuilder,
      $$CajasTableUpdateCompanionBuilder,
      (FilaCaja, $$CajasTableReferences),
      FilaCaja,
      PrefetchHooks Function({bool movimientosCajaRefs})
    >;
typedef $$MovimientosCajaTableCreateCompanionBuilder =
    MovimientosCajaCompanion Function({
      required String id,
      required String tiendaId,
      required String cajaId,
      required String tipo,
      required String clasificacion,
      required Decimal valor,
      required String descripcion,
      required DateTime fecha,
      Value<int> rowid,
    });
typedef $$MovimientosCajaTableUpdateCompanionBuilder =
    MovimientosCajaCompanion Function({
      Value<String> id,
      Value<String> tiendaId,
      Value<String> cajaId,
      Value<String> tipo,
      Value<String> clasificacion,
      Value<Decimal> valor,
      Value<String> descripcion,
      Value<DateTime> fecha,
      Value<int> rowid,
    });

final class $$MovimientosCajaTableReferences
    extends
        BaseReferences<
          _$BaseLocalDrift,
          $MovimientosCajaTable,
          FilaMovimientoCaja
        > {
  $$MovimientosCajaTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CajasTable _cajaIdTable(_$BaseLocalDrift db) =>
      db.cajas.createAlias('movimientos_caja__caja_id__cajas__id');

  $$CajasTableProcessedTableManager get cajaId {
    final $_column = $_itemColumn<String>('caja_id')!;

    final manager = $$CajasTableTableManager(
      $_db,
      $_db.cajas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cajaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MovimientosCajaTableFilterComposer
    extends Composer<_$BaseLocalDrift, $MovimientosCajaTable> {
  $$MovimientosCajaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clasificacion => $composableBuilder(
    column: $table.clasificacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get valor =>
      $composableBuilder(
        column: $table.valor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get fecha =>
      $composableBuilder(
        column: $table.fecha,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$CajasTableFilterComposer get cajaId {
    final $$CajasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cajaId,
      referencedTable: $db.cajas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CajasTableFilterComposer(
            $db: $db,
            $table: $db.cajas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimientosCajaTableOrderingComposer
    extends Composer<_$BaseLocalDrift, $MovimientosCajaTable> {
  $$MovimientosCajaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clasificacion => $composableBuilder(
    column: $table.clasificacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  $$CajasTableOrderingComposer get cajaId {
    final $$CajasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cajaId,
      referencedTable: $db.cajas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CajasTableOrderingComposer(
            $db: $db,
            $table: $db.cajas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimientosCajaTableAnnotationComposer
    extends Composer<_$BaseLocalDrift, $MovimientosCajaTable> {
  $$MovimientosCajaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tiendaId =>
      $composableBuilder(column: $table.tiendaId, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get clasificacion => $composableBuilder(
    column: $table.clasificacion,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal, String> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  $$CajasTableAnnotationComposer get cajaId {
    final $$CajasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cajaId,
      referencedTable: $db.cajas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CajasTableAnnotationComposer(
            $db: $db,
            $table: $db.cajas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimientosCajaTableTableManager
    extends
        RootTableManager<
          _$BaseLocalDrift,
          $MovimientosCajaTable,
          FilaMovimientoCaja,
          $$MovimientosCajaTableFilterComposer,
          $$MovimientosCajaTableOrderingComposer,
          $$MovimientosCajaTableAnnotationComposer,
          $$MovimientosCajaTableCreateCompanionBuilder,
          $$MovimientosCajaTableUpdateCompanionBuilder,
          (FilaMovimientoCaja, $$MovimientosCajaTableReferences),
          FilaMovimientoCaja,
          PrefetchHooks Function({bool cajaId})
        > {
  $$MovimientosCajaTableTableManager(
    _$BaseLocalDrift db,
    $MovimientosCajaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovimientosCajaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovimientosCajaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovimientosCajaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tiendaId = const Value.absent(),
                Value<String> cajaId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> clasificacion = const Value.absent(),
                Value<Decimal> valor = const Value.absent(),
                Value<String> descripcion = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovimientosCajaCompanion(
                id: id,
                tiendaId: tiendaId,
                cajaId: cajaId,
                tipo: tipo,
                clasificacion: clasificacion,
                valor: valor,
                descripcion: descripcion,
                fecha: fecha,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tiendaId,
                required String cajaId,
                required String tipo,
                required String clasificacion,
                required Decimal valor,
                required String descripcion,
                required DateTime fecha,
                Value<int> rowid = const Value.absent(),
              }) => MovimientosCajaCompanion.insert(
                id: id,
                tiendaId: tiendaId,
                cajaId: cajaId,
                tipo: tipo,
                clasificacion: clasificacion,
                valor: valor,
                descripcion: descripcion,
                fecha: fecha,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MovimientosCajaTable, FilaMovimientoCaja>(table),
                  $$MovimientosCajaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cajaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cajaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.cajaId,
                        referencedTable: $$MovimientosCajaTableReferences
                            ._cajaIdTable(db),
                        referencedColumn: $$MovimientosCajaTableReferences
                            ._cajaIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MovimientosCajaTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocalDrift,
      $MovimientosCajaTable,
      FilaMovimientoCaja,
      $$MovimientosCajaTableFilterComposer,
      $$MovimientosCajaTableOrderingComposer,
      $$MovimientosCajaTableAnnotationComposer,
      $$MovimientosCajaTableCreateCompanionBuilder,
      $$MovimientosCajaTableUpdateCompanionBuilder,
      (FilaMovimientoCaja, $$MovimientosCajaTableReferences),
      FilaMovimientoCaja,
      PrefetchHooks Function({bool cajaId})
    >;
typedef $$FormasPagoTableCreateCompanionBuilder = FormasPagoCompanion Function({
  required String id,
  required String tiendaId,
  required String ventaId,
  required String tipo,
  Value<Decimal?> montoRecibido,
  Value<Decimal?> cambio,
  Value<Decimal?> monto,
  Value<String?> referencia,
  Value<int> rowid,
});
typedef $$FormasPagoTableUpdateCompanionBuilder = FormasPagoCompanion Function({
  Value<String> id,
  Value<String> tiendaId,
  Value<String> ventaId,
  Value<String> tipo,
  Value<Decimal?> montoRecibido,
  Value<Decimal?> cambio,
  Value<Decimal?> monto,
  Value<String?> referencia,
  Value<int> rowid,
});

final class $$FormasPagoTableReferences
    extends BaseReferences<_$BaseLocalDrift, $FormasPagoTable, FilaFormaPago> {
  $$FormasPagoTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VentasTable _ventaIdTable(_$BaseLocalDrift db) =>
      db.ventas.createAlias('formas_pago__venta_id__ventas__id');

  $$VentasTableProcessedTableManager get ventaId {
    final $_column = $_itemColumn<String>('venta_id')!;

    final manager = $$VentasTableTableManager(
      $_db,
      $_db.ventas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ventaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FiadosTable, List<FilaFiado>> _fiadosRefsTable(
    _$BaseLocalDrift db,
  ) => MultiTypedResultKey.fromTable(
    db.fiados,
    aliasName: 'formas_pago__id__fiados__id',
  );

  $$FiadosTableProcessedTableManager get fiadosRefs {
    final manager = $$FiadosTableTableManager(
      $_db,
      $_db.fiados,
    ).filter((f) => f.id.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fiadosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FormasPagoTableFilterComposer
    extends Composer<_$BaseLocalDrift, $FormasPagoTable> {
  $$FormasPagoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String> get montoRecibido =>
      $composableBuilder(
        column: $table.montoRecibido,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String> get cambio =>
      $composableBuilder(
        column: $table.cambio,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String> get monto =>
      $composableBuilder(
        column: $table.monto,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get referencia => $composableBuilder(
    column: $table.referencia,
    builder: (column) => ColumnFilters(column),
  );

  $$VentasTableFilterComposer get ventaId {
    final $$VentasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ventaId,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableFilterComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> fiadosRefs(
    Expression<bool> Function($$FiadosTableFilterComposer f) f,
  ) {
    final $$FiadosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fiados,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FiadosTableFilterComposer(
            $db: $db,
            $table: $db.fiados,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FormasPagoTableOrderingComposer
    extends Composer<_$BaseLocalDrift, $FormasPagoTable> {
  $$FormasPagoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get montoRecibido => $composableBuilder(
    column: $table.montoRecibido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cambio => $composableBuilder(
    column: $table.cambio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referencia => $composableBuilder(
    column: $table.referencia,
    builder: (column) => ColumnOrderings(column),
  );

  $$VentasTableOrderingComposer get ventaId {
    final $$VentasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ventaId,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableOrderingComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FormasPagoTableAnnotationComposer
    extends Composer<_$BaseLocalDrift, $FormasPagoTable> {
  $$FormasPagoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tiendaId =>
      $composableBuilder(column: $table.tiendaId, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal?, String> get montoRecibido =>
      $composableBuilder(
        column: $table.montoRecibido,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal?, String> get cambio =>
      $composableBuilder(column: $table.cambio, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal?, String> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get referencia => $composableBuilder(
    column: $table.referencia,
    builder: (column) => column,
  );

  $$VentasTableAnnotationComposer get ventaId {
    final $$VentasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ventaId,
      referencedTable: $db.ventas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VentasTableAnnotationComposer(
            $db: $db,
            $table: $db.ventas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> fiadosRefs<T extends Object>(
    Expression<T> Function($$FiadosTableAnnotationComposer a) f,
  ) {
    final $$FiadosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fiados,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FiadosTableAnnotationComposer(
            $db: $db,
            $table: $db.fiados,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FormasPagoTableTableManager
    extends
        RootTableManager<
          _$BaseLocalDrift,
          $FormasPagoTable,
          FilaFormaPago,
          $$FormasPagoTableFilterComposer,
          $$FormasPagoTableOrderingComposer,
          $$FormasPagoTableAnnotationComposer,
          $$FormasPagoTableCreateCompanionBuilder,
          $$FormasPagoTableUpdateCompanionBuilder,
          (FilaFormaPago, $$FormasPagoTableReferences),
          FilaFormaPago,
          PrefetchHooks Function({bool ventaId, bool fiadosRefs})
        > {
  $$FormasPagoTableTableManager(_$BaseLocalDrift db, $FormasPagoTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FormasPagoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FormasPagoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FormasPagoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tiendaId = const Value.absent(),
                Value<String> ventaId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<Decimal?> montoRecibido = const Value.absent(),
                Value<Decimal?> cambio = const Value.absent(),
                Value<Decimal?> monto = const Value.absent(),
                Value<String?> referencia = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FormasPagoCompanion(
                id: id,
                tiendaId: tiendaId,
                ventaId: ventaId,
                tipo: tipo,
                montoRecibido: montoRecibido,
                cambio: cambio,
                monto: monto,
                referencia: referencia,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tiendaId,
                required String ventaId,
                required String tipo,
                Value<Decimal?> montoRecibido = const Value.absent(),
                Value<Decimal?> cambio = const Value.absent(),
                Value<Decimal?> monto = const Value.absent(),
                Value<String?> referencia = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FormasPagoCompanion.insert(
                id: id,
                tiendaId: tiendaId,
                ventaId: ventaId,
                tipo: tipo,
                montoRecibido: montoRecibido,
                cambio: cambio,
                monto: monto,
                referencia: referencia,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FormasPagoTable, FilaFormaPago>(table),
                  $$FormasPagoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ventaId = false, fiadosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (fiadosRefs) db.fiados],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ventaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.ventaId,
                        referencedTable: $$FormasPagoTableReferences
                            ._ventaIdTable(db),
                        referencedColumn: $$FormasPagoTableReferences
                            ._ventaIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (fiadosRefs)
                    await $_getPrefetchedDataByColumns<
                      FilaFormaPago,
                      $FormasPagoTable,
                      FilaFiado,
                      $FiadosTable
                    >(
                      currentTable: table,
                      referencedTable: $$FormasPagoTableReferences
                          ._fiadosRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FormasPagoTableReferences(db, table, p0).fiadosRefs,
                      currentColumn: 'id',
                      referencedColumn: 'id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FormasPagoTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocalDrift,
      $FormasPagoTable,
      FilaFormaPago,
      $$FormasPagoTableFilterComposer,
      $$FormasPagoTableOrderingComposer,
      $$FormasPagoTableAnnotationComposer,
      $$FormasPagoTableCreateCompanionBuilder,
      $$FormasPagoTableUpdateCompanionBuilder,
      (FilaFormaPago, $$FormasPagoTableReferences),
      FilaFormaPago,
      PrefetchHooks Function({bool ventaId, bool fiadosRefs})
    >;
typedef $$AlertasReabastecimientoTableCreateCompanionBuilder =
    AlertasReabastecimientoCompanion Function({
      required String id,
      required String tiendaId,
      required String itemId,
      required String fecha,
      required Decimal existencia,
      required Decimal consumoPromedioDiario,
      required Decimal diasCobertura,
      required bool provisional,
      Value<int> rowid,
    });
typedef $$AlertasReabastecimientoTableUpdateCompanionBuilder =
    AlertasReabastecimientoCompanion Function({
      Value<String> id,
      Value<String> tiendaId,
      Value<String> itemId,
      Value<String> fecha,
      Value<Decimal> existencia,
      Value<Decimal> consumoPromedioDiario,
      Value<Decimal> diasCobertura,
      Value<bool> provisional,
      Value<int> rowid,
    });

final class $$AlertasReabastecimientoTableReferences
    extends
        BaseReferences<
          _$BaseLocalDrift,
          $AlertasReabastecimientoTable,
          FilaAlerta
        > {
  $$AlertasReabastecimientoTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ItemsInventarioTable _itemIdTable(_$BaseLocalDrift db) => db
      .itemsInventario
      .createAlias('alertas_reabastecimiento__item_id__items_inventario__id');

  $$ItemsInventarioTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsInventarioTableTableManager(
      $_db,
      $_db.itemsInventario,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AlertasReabastecimientoTableFilterComposer
    extends Composer<_$BaseLocalDrift, $AlertasReabastecimientoTable> {
  $$AlertasReabastecimientoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get existencia =>
      $composableBuilder(
        column: $table.existencia,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String>
  get consumoPromedioDiario => $composableBuilder(
    column: $table.consumoPromedioDiario,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get diasCobertura =>
      $composableBuilder(
        column: $table.diasCobertura,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get provisional => $composableBuilder(
    column: $table.provisional,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsInventarioTableFilterComposer get itemId {
    final $$ItemsInventarioTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.itemsInventario,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsInventarioTableFilterComposer(
            $db: $db,
            $table: $db.itemsInventario,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertasReabastecimientoTableOrderingComposer
    extends Composer<_$BaseLocalDrift, $AlertasReabastecimientoTable> {
  $$AlertasReabastecimientoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get existencia => $composableBuilder(
    column: $table.existencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consumoPromedioDiario => $composableBuilder(
    column: $table.consumoPromedioDiario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get diasCobertura => $composableBuilder(
    column: $table.diasCobertura,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get provisional => $composableBuilder(
    column: $table.provisional,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsInventarioTableOrderingComposer get itemId {
    final $$ItemsInventarioTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.itemsInventario,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsInventarioTableOrderingComposer(
            $db: $db,
            $table: $db.itemsInventario,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertasReabastecimientoTableAnnotationComposer
    extends Composer<_$BaseLocalDrift, $AlertasReabastecimientoTable> {
  $$AlertasReabastecimientoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tiendaId =>
      $composableBuilder(column: $table.tiendaId, builder: (column) => column);

  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get existencia =>
      $composableBuilder(
        column: $table.existencia,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal, String> get consumoPromedioDiario =>
      $composableBuilder(
        column: $table.consumoPromedioDiario,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal, String> get diasCobertura =>
      $composableBuilder(
        column: $table.diasCobertura,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get provisional => $composableBuilder(
    column: $table.provisional,
    builder: (column) => column,
  );

  $$ItemsInventarioTableAnnotationComposer get itemId {
    final $$ItemsInventarioTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.itemsInventario,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsInventarioTableAnnotationComposer(
            $db: $db,
            $table: $db.itemsInventario,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertasReabastecimientoTableTableManager
    extends
        RootTableManager<
          _$BaseLocalDrift,
          $AlertasReabastecimientoTable,
          FilaAlerta,
          $$AlertasReabastecimientoTableFilterComposer,
          $$AlertasReabastecimientoTableOrderingComposer,
          $$AlertasReabastecimientoTableAnnotationComposer,
          $$AlertasReabastecimientoTableCreateCompanionBuilder,
          $$AlertasReabastecimientoTableUpdateCompanionBuilder,
          (FilaAlerta, $$AlertasReabastecimientoTableReferences),
          FilaAlerta,
          PrefetchHooks Function({bool itemId})
        > {
  $$AlertasReabastecimientoTableTableManager(
    _$BaseLocalDrift db,
    $AlertasReabastecimientoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertasReabastecimientoTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AlertasReabastecimientoTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AlertasReabastecimientoTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tiendaId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> fecha = const Value.absent(),
                Value<Decimal> existencia = const Value.absent(),
                Value<Decimal> consumoPromedioDiario = const Value.absent(),
                Value<Decimal> diasCobertura = const Value.absent(),
                Value<bool> provisional = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertasReabastecimientoCompanion(
                id: id,
                tiendaId: tiendaId,
                itemId: itemId,
                fecha: fecha,
                existencia: existencia,
                consumoPromedioDiario: consumoPromedioDiario,
                diasCobertura: diasCobertura,
                provisional: provisional,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tiendaId,
                required String itemId,
                required String fecha,
                required Decimal existencia,
                required Decimal consumoPromedioDiario,
                required Decimal diasCobertura,
                required bool provisional,
                Value<int> rowid = const Value.absent(),
              }) => AlertasReabastecimientoCompanion.insert(
                id: id,
                tiendaId: tiendaId,
                itemId: itemId,
                fecha: fecha,
                existencia: existencia,
                consumoPromedioDiario: consumoPromedioDiario,
                diasCobertura: diasCobertura,
                provisional: provisional,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlertasReabastecimientoTable, FilaAlerta>(table),
                  $$AlertasReabastecimientoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable:
                            $$AlertasReabastecimientoTableReferences
                                ._itemIdTable(db),
                        referencedColumn:
                            $$AlertasReabastecimientoTableReferences
                                ._itemIdTable(db)
                                .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AlertasReabastecimientoTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocalDrift,
      $AlertasReabastecimientoTable,
      FilaAlerta,
      $$AlertasReabastecimientoTableFilterComposer,
      $$AlertasReabastecimientoTableOrderingComposer,
      $$AlertasReabastecimientoTableAnnotationComposer,
      $$AlertasReabastecimientoTableCreateCompanionBuilder,
      $$AlertasReabastecimientoTableUpdateCompanionBuilder,
      (FilaAlerta, $$AlertasReabastecimientoTableReferences),
      FilaAlerta,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$VentasPerdidasTableCreateCompanionBuilder =
    VentasPerdidasCompanion Function({
      required String id,
      required String tiendaId,
      required String productoId,
      required DateTime fecha,
      Value<int> rowid,
    });
typedef $$VentasPerdidasTableUpdateCompanionBuilder =
    VentasPerdidasCompanion Function({
      Value<String> id,
      Value<String> tiendaId,
      Value<String> productoId,
      Value<DateTime> fecha,
      Value<int> rowid,
    });

final class $$VentasPerdidasTableReferences
    extends
        BaseReferences<
          _$BaseLocalDrift,
          $VentasPerdidasTable,
          FilaVentaPerdida
        > {
  $$VentasPerdidasTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductosTable _productoIdTable(_$BaseLocalDrift db) =>
      db.productos.createAlias('ventas_perdidas__producto_id__productos__id');

  $$ProductosTableProcessedTableManager get productoId {
    final $_column = $_itemColumn<String>('producto_id')!;

    final manager = $$ProductosTableTableManager(
      $_db,
      $_db.productos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VentasPerdidasTableFilterComposer
    extends Composer<_$BaseLocalDrift, $VentasPerdidasTable> {
  $$VentasPerdidasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get fecha =>
      $composableBuilder(
        column: $table.fecha,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$ProductosTableFilterComposer get productoId {
    final $$ProductosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productoId,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableFilterComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VentasPerdidasTableOrderingComposer
    extends Composer<_$BaseLocalDrift, $VentasPerdidasTable> {
  $$VentasPerdidasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductosTableOrderingComposer get productoId {
    final $$ProductosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productoId,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableOrderingComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VentasPerdidasTableAnnotationComposer
    extends Composer<_$BaseLocalDrift, $VentasPerdidasTable> {
  $$VentasPerdidasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tiendaId =>
      $composableBuilder(column: $table.tiendaId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  $$ProductosTableAnnotationComposer get productoId {
    final $$ProductosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productoId,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableAnnotationComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VentasPerdidasTableTableManager
    extends
        RootTableManager<
          _$BaseLocalDrift,
          $VentasPerdidasTable,
          FilaVentaPerdida,
          $$VentasPerdidasTableFilterComposer,
          $$VentasPerdidasTableOrderingComposer,
          $$VentasPerdidasTableAnnotationComposer,
          $$VentasPerdidasTableCreateCompanionBuilder,
          $$VentasPerdidasTableUpdateCompanionBuilder,
          (FilaVentaPerdida, $$VentasPerdidasTableReferences),
          FilaVentaPerdida,
          PrefetchHooks Function({bool productoId})
        > {
  $$VentasPerdidasTableTableManager(
    _$BaseLocalDrift db,
    $VentasPerdidasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VentasPerdidasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VentasPerdidasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VentasPerdidasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tiendaId = const Value.absent(),
                Value<String> productoId = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VentasPerdidasCompanion(
                id: id,
                tiendaId: tiendaId,
                productoId: productoId,
                fecha: fecha,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tiendaId,
                required String productoId,
                required DateTime fecha,
                Value<int> rowid = const Value.absent(),
              }) => VentasPerdidasCompanion.insert(
                id: id,
                tiendaId: tiendaId,
                productoId: productoId,
                fecha: fecha,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VentasPerdidasTable, FilaVentaPerdida>(table),
                  $$VentasPerdidasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productoId,
                        referencedTable: $$VentasPerdidasTableReferences
                            ._productoIdTable(db),
                        referencedColumn: $$VentasPerdidasTableReferences
                            ._productoIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VentasPerdidasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocalDrift,
      $VentasPerdidasTable,
      FilaVentaPerdida,
      $$VentasPerdidasTableFilterComposer,
      $$VentasPerdidasTableOrderingComposer,
      $$VentasPerdidasTableAnnotationComposer,
      $$VentasPerdidasTableCreateCompanionBuilder,
      $$VentasPerdidasTableUpdateCompanionBuilder,
      (FilaVentaPerdida, $$VentasPerdidasTableReferences),
      FilaVentaPerdida,
      PrefetchHooks Function({bool productoId})
    >;
typedef $$ClientesTableCreateCompanionBuilder = ClientesCompanion Function({
  required String id,
  required String tiendaId,
  required String nombre,
  required String nombreNormalizado,
  Value<String> telefono,
  required DateTime actualizadoEn,
  Value<int> rowid,
});
typedef $$ClientesTableUpdateCompanionBuilder = ClientesCompanion Function({
  Value<String> id,
  Value<String> tiendaId,
  Value<String> nombre,
  Value<String> nombreNormalizado,
  Value<String> telefono,
  Value<DateTime> actualizadoEn,
  Value<int> rowid,
});

final class $$ClientesTableReferences
    extends BaseReferences<_$BaseLocalDrift, $ClientesTable, FilaCliente> {
  $$ClientesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FiadosTable, List<FilaFiado>> _fiadosRefsTable(
    _$BaseLocalDrift db,
  ) => MultiTypedResultKey.fromTable(
    db.fiados,
    aliasName: 'clientes__id__fiados__cliente_id',
  );

  $$FiadosTableProcessedTableManager get fiadosRefs {
    final manager = $$FiadosTableTableManager(
      $_db,
      $_db.fiados,
    ).filter((f) => f.clienteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fiadosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClientesTableFilterComposer
    extends Composer<_$BaseLocalDrift, $ClientesTable> {
  $$ClientesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombreNormalizado => $composableBuilder(
    column: $table.nombreNormalizado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  Expression<bool> fiadosRefs(
    Expression<bool> Function($$FiadosTableFilterComposer f) f,
  ) {
    final $$FiadosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fiados,
      getReferencedColumn: (t) => t.clienteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FiadosTableFilterComposer(
            $db: $db,
            $table: $db.fiados,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClientesTableOrderingComposer
    extends Composer<_$BaseLocalDrift, $ClientesTable> {
  $$ClientesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombreNormalizado => $composableBuilder(
    column: $table.nombreNormalizado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientesTableAnnotationComposer
    extends Composer<_$BaseLocalDrift, $ClientesTable> {
  $$ClientesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tiendaId =>
      $composableBuilder(column: $table.tiendaId, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get nombreNormalizado => $composableBuilder(
    column: $table.nombreNormalizado,
    builder: (column) => column,
  );

  GeneratedColumn<String> get telefono =>
      $composableBuilder(column: $table.telefono, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get actualizadoEn =>
      $composableBuilder(
        column: $table.actualizadoEn,
        builder: (column) => column,
      );

  Expression<T> fiadosRefs<T extends Object>(
    Expression<T> Function($$FiadosTableAnnotationComposer a) f,
  ) {
    final $$FiadosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fiados,
      getReferencedColumn: (t) => t.clienteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FiadosTableAnnotationComposer(
            $db: $db,
            $table: $db.fiados,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClientesTableTableManager
    extends
        RootTableManager<
          _$BaseLocalDrift,
          $ClientesTable,
          FilaCliente,
          $$ClientesTableFilterComposer,
          $$ClientesTableOrderingComposer,
          $$ClientesTableAnnotationComposer,
          $$ClientesTableCreateCompanionBuilder,
          $$ClientesTableUpdateCompanionBuilder,
          (FilaCliente, $$ClientesTableReferences),
          FilaCliente,
          PrefetchHooks Function({bool fiadosRefs})
        > {
  $$ClientesTableTableManager(_$BaseLocalDrift db, $ClientesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tiendaId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> nombreNormalizado = const Value.absent(),
                Value<String> telefono = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientesCompanion(
                id: id,
                tiendaId: tiendaId,
                nombre: nombre,
                nombreNormalizado: nombreNormalizado,
                telefono: telefono,
                actualizadoEn: actualizadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tiendaId,
                required String nombre,
                required String nombreNormalizado,
                Value<String> telefono = const Value.absent(),
                required DateTime actualizadoEn,
                Value<int> rowid = const Value.absent(),
              }) => ClientesCompanion.insert(
                id: id,
                tiendaId: tiendaId,
                nombre: nombre,
                nombreNormalizado: nombreNormalizado,
                telefono: telefono,
                actualizadoEn: actualizadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClientesTable, FilaCliente>(table),
                  $$ClientesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fiadosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (fiadosRefs) db.fiados],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (fiadosRefs)
                    await $_getPrefetchedDataByColumns<
                      FilaCliente,
                      $ClientesTable,
                      FilaFiado,
                      $FiadosTable
                    >(
                      currentTable: table,
                      referencedTable: $$ClientesTableReferences
                          ._fiadosRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ClientesTableReferences(db, table, p0).fiadosRefs,
                      currentColumn: 'id',
                      referencedColumn: 'cliente_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ClientesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocalDrift,
      $ClientesTable,
      FilaCliente,
      $$ClientesTableFilterComposer,
      $$ClientesTableOrderingComposer,
      $$ClientesTableAnnotationComposer,
      $$ClientesTableCreateCompanionBuilder,
      $$ClientesTableUpdateCompanionBuilder,
      (FilaCliente, $$ClientesTableReferences),
      FilaCliente,
      PrefetchHooks Function({bool fiadosRefs})
    >;
typedef $$FiadosTableCreateCompanionBuilder = FiadosCompanion Function({
  required String id,
  required String tiendaId,
  required String clienteId,
  required Decimal montoInicial,
  required Decimal saldoPendiente,
  required String estado,
  required DateTime fechaInicio,
  Value<int> rowid,
});
typedef $$FiadosTableUpdateCompanionBuilder = FiadosCompanion Function({
  Value<String> id,
  Value<String> tiendaId,
  Value<String> clienteId,
  Value<Decimal> montoInicial,
  Value<Decimal> saldoPendiente,
  Value<String> estado,
  Value<DateTime> fechaInicio,
  Value<int> rowid,
});

final class $$FiadosTableReferences
    extends BaseReferences<_$BaseLocalDrift, $FiadosTable, FilaFiado> {
  $$FiadosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FormasPagoTable _idTable(_$BaseLocalDrift db) =>
      db.formasPago.createAlias('fiados__id__formas_pago__id');

  $$FormasPagoTableProcessedTableManager get id {
    final $_column = $_itemColumn<String>('id')!;

    final manager = $$FormasPagoTableTableManager(
      $_db,
      $_db.formasPago,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_idTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ClientesTable _clienteIdTable(_$BaseLocalDrift db) =>
      db.clientes.createAlias('fiados__cliente_id__clientes__id');

  $$ClientesTableProcessedTableManager get clienteId {
    final $_column = $_itemColumn<String>('cliente_id')!;

    final manager = $$ClientesTableTableManager(
      $_db,
      $_db.clientes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clienteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FiadosTableFilterComposer
    extends Composer<_$BaseLocalDrift, $FiadosTable> {
  $$FiadosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get montoInicial =>
      $composableBuilder(
        column: $table.montoInicial,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get saldoPendiente =>
      $composableBuilder(
        column: $table.saldoPendiente,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get fechaInicio => $composableBuilder(
    column: $table.fechaInicio,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$FormasPagoTableFilterComposer get id {
    final $$FormasPagoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.formasPago,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormasPagoTableFilterComposer(
            $db: $db,
            $table: $db.formasPago,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClientesTableFilterComposer get clienteId {
    final $$ClientesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clienteId,
      referencedTable: $db.clientes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientesTableFilterComposer(
            $db: $db,
            $table: $db.clientes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FiadosTableOrderingComposer
    extends Composer<_$BaseLocalDrift, $FiadosTable> {
  $$FiadosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tiendaId => $composableBuilder(
    column: $table.tiendaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get montoInicial => $composableBuilder(
    column: $table.montoInicial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saldoPendiente => $composableBuilder(
    column: $table.saldoPendiente,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaInicio => $composableBuilder(
    column: $table.fechaInicio,
    builder: (column) => ColumnOrderings(column),
  );

  $$FormasPagoTableOrderingComposer get id {
    final $$FormasPagoTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.formasPago,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormasPagoTableOrderingComposer(
            $db: $db,
            $table: $db.formasPago,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClientesTableOrderingComposer get clienteId {
    final $$ClientesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clienteId,
      referencedTable: $db.clientes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientesTableOrderingComposer(
            $db: $db,
            $table: $db.clientes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FiadosTableAnnotationComposer
    extends Composer<_$BaseLocalDrift, $FiadosTable> {
  $$FiadosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tiendaId =>
      $composableBuilder(column: $table.tiendaId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get montoInicial =>
      $composableBuilder(
        column: $table.montoInicial,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal, String> get saldoPendiente =>
      $composableBuilder(
        column: $table.saldoPendiente,
        builder: (column) => column,
      );

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get fechaInicio =>
      $composableBuilder(
        column: $table.fechaInicio,
        builder: (column) => column,
      );

  $$FormasPagoTableAnnotationComposer get id {
    final $$FormasPagoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.formasPago,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormasPagoTableAnnotationComposer(
            $db: $db,
            $table: $db.formasPago,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClientesTableAnnotationComposer get clienteId {
    final $$ClientesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clienteId,
      referencedTable: $db.clientes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientesTableAnnotationComposer(
            $db: $db,
            $table: $db.clientes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FiadosTableTableManager
    extends
        RootTableManager<
          _$BaseLocalDrift,
          $FiadosTable,
          FilaFiado,
          $$FiadosTableFilterComposer,
          $$FiadosTableOrderingComposer,
          $$FiadosTableAnnotationComposer,
          $$FiadosTableCreateCompanionBuilder,
          $$FiadosTableUpdateCompanionBuilder,
          (FilaFiado, $$FiadosTableReferences),
          FilaFiado,
          PrefetchHooks Function({bool id, bool clienteId})
        > {
  $$FiadosTableTableManager(_$BaseLocalDrift db, $FiadosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FiadosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FiadosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FiadosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tiendaId = const Value.absent(),
                Value<String> clienteId = const Value.absent(),
                Value<Decimal> montoInicial = const Value.absent(),
                Value<Decimal> saldoPendiente = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<DateTime> fechaInicio = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FiadosCompanion(
                id: id,
                tiendaId: tiendaId,
                clienteId: clienteId,
                montoInicial: montoInicial,
                saldoPendiente: saldoPendiente,
                estado: estado,
                fechaInicio: fechaInicio,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tiendaId,
                required String clienteId,
                required Decimal montoInicial,
                required Decimal saldoPendiente,
                required String estado,
                required DateTime fechaInicio,
                Value<int> rowid = const Value.absent(),
              }) => FiadosCompanion.insert(
                id: id,
                tiendaId: tiendaId,
                clienteId: clienteId,
                montoInicial: montoInicial,
                saldoPendiente: saldoPendiente,
                estado: estado,
                fechaInicio: fechaInicio,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FiadosTable, FilaFiado>(table),
                  $$FiadosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({id = false, clienteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (id) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.id,
                        referencedTable: $$FiadosTableReferences._idTable(db),
                        referencedColumn: $$FiadosTableReferences
                            ._idTable(db)
                            .id,
                      ) as T;
                    }
                    if (clienteId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.clienteId,
                        referencedTable: $$FiadosTableReferences
                            ._clienteIdTable(db),
                        referencedColumn: $$FiadosTableReferences
                            ._clienteIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FiadosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocalDrift,
      $FiadosTable,
      FilaFiado,
      $$FiadosTableFilterComposer,
      $$FiadosTableOrderingComposer,
      $$FiadosTableAnnotationComposer,
      $$FiadosTableCreateCompanionBuilder,
      $$FiadosTableUpdateCompanionBuilder,
      (FilaFiado, $$FiadosTableReferences),
      FilaFiado,
      PrefetchHooks Function({bool id, bool clienteId})
    >;

class $BaseLocalDriftManager {
  final _$BaseLocalDrift _db;
  $BaseLocalDriftManager(this._db);
  $$ColaPendientesTableTableManager get colaPendientes =>
      $$ColaPendientesTableTableManager(_db, _db.colaPendientes);
  $$ProductosTableTableManager get productos =>
      $$ProductosTableTableManager(_db, _db.productos);
  $$ItemsInventarioTableTableManager get itemsInventario =>
      $$ItemsInventarioTableTableManager(_db, _db.itemsInventario);
  $$VentasTableTableManager get ventas =>
      $$VentasTableTableManager(_db, _db.ventas);
  $$MovimientosInventarioTableTableManager get movimientosInventario =>
      $$MovimientosInventarioTableTableManager(_db, _db.movimientosInventario);
  $$CajasTableTableManager get cajas =>
      $$CajasTableTableManager(_db, _db.cajas);
  $$MovimientosCajaTableTableManager get movimientosCaja =>
      $$MovimientosCajaTableTableManager(_db, _db.movimientosCaja);
  $$FormasPagoTableTableManager get formasPago =>
      $$FormasPagoTableTableManager(_db, _db.formasPago);
  $$AlertasReabastecimientoTableTableManager get alertasReabastecimiento =>
      $$AlertasReabastecimientoTableTableManager(
        _db,
        _db.alertasReabastecimiento,
      );
  $$VentasPerdidasTableTableManager get ventasPerdidas =>
      $$VentasPerdidasTableTableManager(_db, _db.ventasPerdidas);
  $$ClientesTableTableManager get clientes =>
      $$ClientesTableTableManager(_db, _db.clientes);
  $$FiadosTableTableManager get fiados =>
      $$FiadosTableTableManager(_db, _db.fiados);
}
