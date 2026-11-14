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

abstract class _$BaseLocalDrift extends GeneratedDatabase {
  _$BaseLocalDrift(QueryExecutor e) : super(e);
  $BaseLocalDriftManager get managers => $BaseLocalDriftManager(this);
  late final $ColaPendientesTable colaPendientes = $ColaPendientesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [colaPendientes];
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

class $BaseLocalDriftManager {
  final _$BaseLocalDrift _db;
  $BaseLocalDriftManager(this._db);
  $$ColaPendientesTableTableManager get colaPendientes =>
      $$ColaPendientesTableTableManager(_db, _db.colaPendientes);
}
