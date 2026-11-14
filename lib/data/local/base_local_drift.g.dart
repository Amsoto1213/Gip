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
          ..write('numeroFactura: $numeroFactura')
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
          other.numeroFactura == this.numeroFactura);
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
  late final $MovimientosInventarioTable movimientosInventario =
      $MovimientosInventarioTable(this);
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    colaPendientes,
    productos,
    itemsInventario,
    movimientosInventario,
    productosTiendaCodigoIdx,
    productosTiendaNombreIdx,
    itemsInventarioTiendaIdx,
    movimientosInventarioTiendaIdx,
    movimientosInventarioItemTipoFechaIdx,
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
          PrefetchHooks Function({bool itemsInventarioRefs})
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
          prefetchHooksCallback: ({itemsInventarioRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (itemsInventarioRefs) db.itemsInventario,
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
      PrefetchHooks Function({bool itemsInventarioRefs})
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
              ({productoId = false, movimientosInventarioRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (movimientosInventarioRefs) db.movimientosInventario,
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
      PrefetchHooks Function({bool productoId, bool movimientosInventarioRefs})
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
          PrefetchHooks Function({bool itemId})
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
                        referencedTable: $$MovimientosInventarioTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$MovimientosInventarioTableReferences
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
      PrefetchHooks Function({bool itemId})
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
  $$MovimientosInventarioTableTableManager get movimientosInventario =>
      $$MovimientosInventarioTableTableManager(_db, _db.movimientosInventario);
}
