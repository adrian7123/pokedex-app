// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_database.dart';

// ignore_for_file: type=lint
class $AdventuresTable extends Adventures
    with TableInfo<$AdventuresTable, Adventure> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdventuresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionGroupIdMeta = const VerificationMeta(
    'versionGroupId',
  );
  @override
  late final GeneratedColumn<int> versionGroupId = GeneratedColumn<int>(
    'version_group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionIdMeta = const VerificationMeta(
    'versionId',
  );
  @override
  late final GeneratedColumn<int> versionId = GeneratedColumn<int>(
    'version_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isNuzlockeMeta = const VerificationMeta(
    'isNuzlocke',
  );
  @override
  late final GeneratedColumn<bool> isNuzlocke = GeneratedColumn<bool>(
    'is_nuzlocke',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_nuzlocke" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nuzlockeRulesMeta = const VerificationMeta(
    'nuzlockeRules',
  );
  @override
  late final GeneratedColumn<String> nuzlockeRules = GeneratedColumn<String>(
    'nuzlocke_rules',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    versionGroupId,
    versionId,
    isNuzlocke,
    nuzlockeRules,
    archived,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adventures';
  @override
  VerificationContext validateIntegrity(
    Insertable<Adventure> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('version_group_id')) {
      context.handle(
        _versionGroupIdMeta,
        versionGroupId.isAcceptableOrUnknown(
          data['version_group_id']!,
          _versionGroupIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionGroupIdMeta);
    }
    if (data.containsKey('version_id')) {
      context.handle(
        _versionIdMeta,
        versionId.isAcceptableOrUnknown(data['version_id']!, _versionIdMeta),
      );
    }
    if (data.containsKey('is_nuzlocke')) {
      context.handle(
        _isNuzlockeMeta,
        isNuzlocke.isAcceptableOrUnknown(data['is_nuzlocke']!, _isNuzlockeMeta),
      );
    }
    if (data.containsKey('nuzlocke_rules')) {
      context.handle(
        _nuzlockeRulesMeta,
        nuzlockeRules.isAcceptableOrUnknown(
          data['nuzlocke_rules']!,
          _nuzlockeRulesMeta,
        ),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Adventure map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Adventure(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      versionGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version_group_id'],
      )!,
      versionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version_id'],
      ),
      isNuzlocke: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_nuzlocke'],
      )!,
      nuzlockeRules: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nuzlocke_rules'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AdventuresTable createAlias(String alias) {
    return $AdventuresTable(attachedDatabase, alias);
  }
}

class Adventure extends DataClass implements Insertable<Adventure> {
  final String id;
  final String name;

  /// version_groups.id do banco de referência (jogo base, nunca DLC).
  final int versionGroupId;

  /// versions.id (cartucho: FireRed ou LeafGreen); define encontros e exclusivos.
  final int? versionId;
  final bool isNuzlocke;
  final String? nuzlockeRules;
  final bool archived;
  final DateTime createdAt;
  const Adventure({
    required this.id,
    required this.name,
    required this.versionGroupId,
    this.versionId,
    required this.isNuzlocke,
    this.nuzlockeRules,
    required this.archived,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['version_group_id'] = Variable<int>(versionGroupId);
    if (!nullToAbsent || versionId != null) {
      map['version_id'] = Variable<int>(versionId);
    }
    map['is_nuzlocke'] = Variable<bool>(isNuzlocke);
    if (!nullToAbsent || nuzlockeRules != null) {
      map['nuzlocke_rules'] = Variable<String>(nuzlockeRules);
    }
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AdventuresCompanion toCompanion(bool nullToAbsent) {
    return AdventuresCompanion(
      id: Value(id),
      name: Value(name),
      versionGroupId: Value(versionGroupId),
      versionId: versionId == null && nullToAbsent
          ? const Value.absent()
          : Value(versionId),
      isNuzlocke: Value(isNuzlocke),
      nuzlockeRules: nuzlockeRules == null && nullToAbsent
          ? const Value.absent()
          : Value(nuzlockeRules),
      archived: Value(archived),
      createdAt: Value(createdAt),
    );
  }

  factory Adventure.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Adventure(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      versionGroupId: serializer.fromJson<int>(json['versionGroupId']),
      versionId: serializer.fromJson<int?>(json['versionId']),
      isNuzlocke: serializer.fromJson<bool>(json['isNuzlocke']),
      nuzlockeRules: serializer.fromJson<String?>(json['nuzlockeRules']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'versionGroupId': serializer.toJson<int>(versionGroupId),
      'versionId': serializer.toJson<int?>(versionId),
      'isNuzlocke': serializer.toJson<bool>(isNuzlocke),
      'nuzlockeRules': serializer.toJson<String?>(nuzlockeRules),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Adventure copyWith({
    String? id,
    String? name,
    int? versionGroupId,
    Value<int?> versionId = const Value.absent(),
    bool? isNuzlocke,
    Value<String?> nuzlockeRules = const Value.absent(),
    bool? archived,
    DateTime? createdAt,
  }) => Adventure(
    id: id ?? this.id,
    name: name ?? this.name,
    versionGroupId: versionGroupId ?? this.versionGroupId,
    versionId: versionId.present ? versionId.value : this.versionId,
    isNuzlocke: isNuzlocke ?? this.isNuzlocke,
    nuzlockeRules: nuzlockeRules.present
        ? nuzlockeRules.value
        : this.nuzlockeRules,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
  );
  Adventure copyWithCompanion(AdventuresCompanion data) {
    return Adventure(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      versionGroupId: data.versionGroupId.present
          ? data.versionGroupId.value
          : this.versionGroupId,
      versionId: data.versionId.present ? data.versionId.value : this.versionId,
      isNuzlocke: data.isNuzlocke.present
          ? data.isNuzlocke.value
          : this.isNuzlocke,
      nuzlockeRules: data.nuzlockeRules.present
          ? data.nuzlockeRules.value
          : this.nuzlockeRules,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Adventure(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('versionGroupId: $versionGroupId, ')
          ..write('versionId: $versionId, ')
          ..write('isNuzlocke: $isNuzlocke, ')
          ..write('nuzlockeRules: $nuzlockeRules, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    versionGroupId,
    versionId,
    isNuzlocke,
    nuzlockeRules,
    archived,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Adventure &&
          other.id == this.id &&
          other.name == this.name &&
          other.versionGroupId == this.versionGroupId &&
          other.versionId == this.versionId &&
          other.isNuzlocke == this.isNuzlocke &&
          other.nuzlockeRules == this.nuzlockeRules &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt);
}

class AdventuresCompanion extends UpdateCompanion<Adventure> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> versionGroupId;
  final Value<int?> versionId;
  final Value<bool> isNuzlocke;
  final Value<String?> nuzlockeRules;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AdventuresCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.versionGroupId = const Value.absent(),
    this.versionId = const Value.absent(),
    this.isNuzlocke = const Value.absent(),
    this.nuzlockeRules = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdventuresCompanion.insert({
    required String id,
    required String name,
    required int versionGroupId,
    this.versionId = const Value.absent(),
    this.isNuzlocke = const Value.absent(),
    this.nuzlockeRules = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       versionGroupId = Value(versionGroupId),
       createdAt = Value(createdAt);
  static Insertable<Adventure> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? versionGroupId,
    Expression<int>? versionId,
    Expression<bool>? isNuzlocke,
    Expression<String>? nuzlockeRules,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (versionGroupId != null) 'version_group_id': versionGroupId,
      if (versionId != null) 'version_id': versionId,
      if (isNuzlocke != null) 'is_nuzlocke': isNuzlocke,
      if (nuzlockeRules != null) 'nuzlocke_rules': nuzlockeRules,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdventuresCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? versionGroupId,
    Value<int?>? versionId,
    Value<bool>? isNuzlocke,
    Value<String?>? nuzlockeRules,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AdventuresCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      versionGroupId: versionGroupId ?? this.versionGroupId,
      versionId: versionId ?? this.versionId,
      isNuzlocke: isNuzlocke ?? this.isNuzlocke,
      nuzlockeRules: nuzlockeRules ?? this.nuzlockeRules,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (versionGroupId.present) {
      map['version_group_id'] = Variable<int>(versionGroupId.value);
    }
    if (versionId.present) {
      map['version_id'] = Variable<int>(versionId.value);
    }
    if (isNuzlocke.present) {
      map['is_nuzlocke'] = Variable<bool>(isNuzlocke.value);
    }
    if (nuzlockeRules.present) {
      map['nuzlocke_rules'] = Variable<String>(nuzlockeRules.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdventuresCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('versionGroupId: $versionGroupId, ')
          ..write('versionId: $versionId, ')
          ..write('isNuzlocke: $isNuzlocke, ')
          ..write('nuzlockeRules: $nuzlockeRules, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SpecimensTable extends Specimens
    with TableInfo<$SpecimensTable, Specimen> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpecimensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adventureIdMeta = const VerificationMeta(
    'adventureId',
  );
  @override
  late final GeneratedColumn<String> adventureId = GeneratedColumn<String>(
    'adventure_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES adventures (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _speciesIdMeta = const VerificationMeta(
    'speciesId',
  );
  @override
  late final GeneratedColumn<int> speciesId = GeneratedColumn<int>(
    'species_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pokemonIdMeta = const VerificationMeta(
    'pokemonId',
  );
  @override
  late final GeneratedColumn<int> pokemonId = GeneratedColumn<int>(
    'pokemon_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isShinyMeta = const VerificationMeta(
    'isShiny',
  );
  @override
  late final GeneratedColumn<bool> isShiny = GeneratedColumn<bool>(
    'is_shiny',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_shiny" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _natureMeta = const VerificationMeta('nature');
  @override
  late final GeneratedColumn<String> nature = GeneratedColumn<String>(
    'nature',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _abilityIdMeta = const VerificationMeta(
    'abilityId',
  );
  @override
  late final GeneratedColumn<int> abilityId = GeneratedColumn<int>(
    'ability_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ballItemIdMeta = const VerificationMeta(
    'ballItemId',
  );
  @override
  late final GeneratedColumn<int> ballItemId = GeneratedColumn<int>(
    'ball_item_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caughtWhereMeta = const VerificationMeta(
    'caughtWhere',
  );
  @override
  late final GeneratedColumn<String> caughtWhere = GeneratedColumn<String>(
    'caught_where',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heldItemIdMeta = const VerificationMeta(
    'heldItemId',
  );
  @override
  late final GeneratedColumn<int> heldItemId = GeneratedColumn<int>(
    'held_item_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ivsMeta = const VerificationMeta('ivs');
  @override
  late final GeneratedColumn<String> ivs = GeneratedColumn<String>(
    'ivs',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _evsMeta = const VerificationMeta('evs');
  @override
  late final GeneratedColumn<String> evs = GeneratedColumn<String>(
    'evs',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _movesMeta = const VerificationMeta('moves');
  @override
  late final GeneratedColumn<String> moves = GeneratedColumn<String>(
    'moves',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teamSlotMeta = const VerificationMeta(
    'teamSlot',
  );
  @override
  late final GeneratedColumn<int> teamSlot = GeneratedColumn<int>(
    'team_slot',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAliveMeta = const VerificationMeta(
    'isAlive',
  );
  @override
  late final GeneratedColumn<bool> isAlive = GeneratedColumn<bool>(
    'is_alive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_alive" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _caughtAtMeta = const VerificationMeta(
    'caughtAt',
  );
  @override
  late final GeneratedColumn<DateTime> caughtAt = GeneratedColumn<DateTime>(
    'caught_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    adventureId,
    speciesId,
    pokemonId,
    isShiny,
    nickname,
    level,
    nature,
    abilityId,
    gender,
    ballItemId,
    caughtWhere,
    heldItemId,
    ivs,
    evs,
    moves,
    notes,
    teamSlot,
    isAlive,
    caughtAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'specimens';
  @override
  VerificationContext validateIntegrity(
    Insertable<Specimen> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('adventure_id')) {
      context.handle(
        _adventureIdMeta,
        adventureId.isAcceptableOrUnknown(
          data['adventure_id']!,
          _adventureIdMeta,
        ),
      );
    }
    if (data.containsKey('species_id')) {
      context.handle(
        _speciesIdMeta,
        speciesId.isAcceptableOrUnknown(data['species_id']!, _speciesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_speciesIdMeta);
    }
    if (data.containsKey('pokemon_id')) {
      context.handle(
        _pokemonIdMeta,
        pokemonId.isAcceptableOrUnknown(data['pokemon_id']!, _pokemonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pokemonIdMeta);
    }
    if (data.containsKey('is_shiny')) {
      context.handle(
        _isShinyMeta,
        isShiny.isAcceptableOrUnknown(data['is_shiny']!, _isShinyMeta),
      );
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('nature')) {
      context.handle(
        _natureMeta,
        nature.isAcceptableOrUnknown(data['nature']!, _natureMeta),
      );
    }
    if (data.containsKey('ability_id')) {
      context.handle(
        _abilityIdMeta,
        abilityId.isAcceptableOrUnknown(data['ability_id']!, _abilityIdMeta),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('ball_item_id')) {
      context.handle(
        _ballItemIdMeta,
        ballItemId.isAcceptableOrUnknown(
          data['ball_item_id']!,
          _ballItemIdMeta,
        ),
      );
    }
    if (data.containsKey('caught_where')) {
      context.handle(
        _caughtWhereMeta,
        caughtWhere.isAcceptableOrUnknown(
          data['caught_where']!,
          _caughtWhereMeta,
        ),
      );
    }
    if (data.containsKey('held_item_id')) {
      context.handle(
        _heldItemIdMeta,
        heldItemId.isAcceptableOrUnknown(
          data['held_item_id']!,
          _heldItemIdMeta,
        ),
      );
    }
    if (data.containsKey('ivs')) {
      context.handle(
        _ivsMeta,
        ivs.isAcceptableOrUnknown(data['ivs']!, _ivsMeta),
      );
    }
    if (data.containsKey('evs')) {
      context.handle(
        _evsMeta,
        evs.isAcceptableOrUnknown(data['evs']!, _evsMeta),
      );
    }
    if (data.containsKey('moves')) {
      context.handle(
        _movesMeta,
        moves.isAcceptableOrUnknown(data['moves']!, _movesMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('team_slot')) {
      context.handle(
        _teamSlotMeta,
        teamSlot.isAcceptableOrUnknown(data['team_slot']!, _teamSlotMeta),
      );
    }
    if (data.containsKey('is_alive')) {
      context.handle(
        _isAliveMeta,
        isAlive.isAcceptableOrUnknown(data['is_alive']!, _isAliveMeta),
      );
    }
    if (data.containsKey('caught_at')) {
      context.handle(
        _caughtAtMeta,
        caughtAt.isAcceptableOrUnknown(data['caught_at']!, _caughtAtMeta),
      );
    } else if (isInserting) {
      context.missing(_caughtAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Specimen map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Specimen(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      adventureId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adventure_id'],
      ),
      speciesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}species_id'],
      )!,
      pokemonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pokemon_id'],
      )!,
      isShiny: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_shiny'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      ),
      nature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nature'],
      ),
      abilityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ability_id'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      ballItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ball_item_id'],
      ),
      caughtWhere: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caught_where'],
      ),
      heldItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}held_item_id'],
      ),
      ivs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ivs'],
      ),
      evs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evs'],
      ),
      moves: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}moves'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      teamSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_slot'],
      ),
      isAlive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_alive'],
      )!,
      caughtAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}caught_at'],
      )!,
    );
  }

  @override
  $SpecimensTable createAlias(String alias) {
    return $SpecimensTable(attachedDatabase, alias);
  }
}

class Specimen extends DataClass implements Insertable<Specimen> {
  final String id;
  final String? adventureId;
  final int speciesId;
  final int pokemonId;
  final bool isShiny;
  final String? nickname;
  final int? level;
  final String? nature;
  final int? abilityId;

  /// 'm', 'f' ou null
  final String? gender;
  final int? ballItemId;
  final String? caughtWhere;
  final int? heldItemId;

  /// "hp,atk,def,spa,spd,spe"; null quando não informado.
  final String? ivs;
  final String? evs;

  /// Até 4 move ids separados por vírgula.
  final String? moves;
  final String? notes;

  /// Posição no time (1–6) da aventura; null fora do time.
  final int? teamSlot;

  /// Nuzlocke: false = no cemitério.
  final bool isAlive;
  final DateTime caughtAt;
  const Specimen({
    required this.id,
    this.adventureId,
    required this.speciesId,
    required this.pokemonId,
    required this.isShiny,
    this.nickname,
    this.level,
    this.nature,
    this.abilityId,
    this.gender,
    this.ballItemId,
    this.caughtWhere,
    this.heldItemId,
    this.ivs,
    this.evs,
    this.moves,
    this.notes,
    this.teamSlot,
    required this.isAlive,
    required this.caughtAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || adventureId != null) {
      map['adventure_id'] = Variable<String>(adventureId);
    }
    map['species_id'] = Variable<int>(speciesId);
    map['pokemon_id'] = Variable<int>(pokemonId);
    map['is_shiny'] = Variable<bool>(isShiny);
    if (!nullToAbsent || nickname != null) {
      map['nickname'] = Variable<String>(nickname);
    }
    if (!nullToAbsent || level != null) {
      map['level'] = Variable<int>(level);
    }
    if (!nullToAbsent || nature != null) {
      map['nature'] = Variable<String>(nature);
    }
    if (!nullToAbsent || abilityId != null) {
      map['ability_id'] = Variable<int>(abilityId);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || ballItemId != null) {
      map['ball_item_id'] = Variable<int>(ballItemId);
    }
    if (!nullToAbsent || caughtWhere != null) {
      map['caught_where'] = Variable<String>(caughtWhere);
    }
    if (!nullToAbsent || heldItemId != null) {
      map['held_item_id'] = Variable<int>(heldItemId);
    }
    if (!nullToAbsent || ivs != null) {
      map['ivs'] = Variable<String>(ivs);
    }
    if (!nullToAbsent || evs != null) {
      map['evs'] = Variable<String>(evs);
    }
    if (!nullToAbsent || moves != null) {
      map['moves'] = Variable<String>(moves);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || teamSlot != null) {
      map['team_slot'] = Variable<int>(teamSlot);
    }
    map['is_alive'] = Variable<bool>(isAlive);
    map['caught_at'] = Variable<DateTime>(caughtAt);
    return map;
  }

  SpecimensCompanion toCompanion(bool nullToAbsent) {
    return SpecimensCompanion(
      id: Value(id),
      adventureId: adventureId == null && nullToAbsent
          ? const Value.absent()
          : Value(adventureId),
      speciesId: Value(speciesId),
      pokemonId: Value(pokemonId),
      isShiny: Value(isShiny),
      nickname: nickname == null && nullToAbsent
          ? const Value.absent()
          : Value(nickname),
      level: level == null && nullToAbsent
          ? const Value.absent()
          : Value(level),
      nature: nature == null && nullToAbsent
          ? const Value.absent()
          : Value(nature),
      abilityId: abilityId == null && nullToAbsent
          ? const Value.absent()
          : Value(abilityId),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      ballItemId: ballItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(ballItemId),
      caughtWhere: caughtWhere == null && nullToAbsent
          ? const Value.absent()
          : Value(caughtWhere),
      heldItemId: heldItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(heldItemId),
      ivs: ivs == null && nullToAbsent ? const Value.absent() : Value(ivs),
      evs: evs == null && nullToAbsent ? const Value.absent() : Value(evs),
      moves: moves == null && nullToAbsent
          ? const Value.absent()
          : Value(moves),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      teamSlot: teamSlot == null && nullToAbsent
          ? const Value.absent()
          : Value(teamSlot),
      isAlive: Value(isAlive),
      caughtAt: Value(caughtAt),
    );
  }

  factory Specimen.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Specimen(
      id: serializer.fromJson<String>(json['id']),
      adventureId: serializer.fromJson<String?>(json['adventureId']),
      speciesId: serializer.fromJson<int>(json['speciesId']),
      pokemonId: serializer.fromJson<int>(json['pokemonId']),
      isShiny: serializer.fromJson<bool>(json['isShiny']),
      nickname: serializer.fromJson<String?>(json['nickname']),
      level: serializer.fromJson<int?>(json['level']),
      nature: serializer.fromJson<String?>(json['nature']),
      abilityId: serializer.fromJson<int?>(json['abilityId']),
      gender: serializer.fromJson<String?>(json['gender']),
      ballItemId: serializer.fromJson<int?>(json['ballItemId']),
      caughtWhere: serializer.fromJson<String?>(json['caughtWhere']),
      heldItemId: serializer.fromJson<int?>(json['heldItemId']),
      ivs: serializer.fromJson<String?>(json['ivs']),
      evs: serializer.fromJson<String?>(json['evs']),
      moves: serializer.fromJson<String?>(json['moves']),
      notes: serializer.fromJson<String?>(json['notes']),
      teamSlot: serializer.fromJson<int?>(json['teamSlot']),
      isAlive: serializer.fromJson<bool>(json['isAlive']),
      caughtAt: serializer.fromJson<DateTime>(json['caughtAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'adventureId': serializer.toJson<String?>(adventureId),
      'speciesId': serializer.toJson<int>(speciesId),
      'pokemonId': serializer.toJson<int>(pokemonId),
      'isShiny': serializer.toJson<bool>(isShiny),
      'nickname': serializer.toJson<String?>(nickname),
      'level': serializer.toJson<int?>(level),
      'nature': serializer.toJson<String?>(nature),
      'abilityId': serializer.toJson<int?>(abilityId),
      'gender': serializer.toJson<String?>(gender),
      'ballItemId': serializer.toJson<int?>(ballItemId),
      'caughtWhere': serializer.toJson<String?>(caughtWhere),
      'heldItemId': serializer.toJson<int?>(heldItemId),
      'ivs': serializer.toJson<String?>(ivs),
      'evs': serializer.toJson<String?>(evs),
      'moves': serializer.toJson<String?>(moves),
      'notes': serializer.toJson<String?>(notes),
      'teamSlot': serializer.toJson<int?>(teamSlot),
      'isAlive': serializer.toJson<bool>(isAlive),
      'caughtAt': serializer.toJson<DateTime>(caughtAt),
    };
  }

  Specimen copyWith({
    String? id,
    Value<String?> adventureId = const Value.absent(),
    int? speciesId,
    int? pokemonId,
    bool? isShiny,
    Value<String?> nickname = const Value.absent(),
    Value<int?> level = const Value.absent(),
    Value<String?> nature = const Value.absent(),
    Value<int?> abilityId = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    Value<int?> ballItemId = const Value.absent(),
    Value<String?> caughtWhere = const Value.absent(),
    Value<int?> heldItemId = const Value.absent(),
    Value<String?> ivs = const Value.absent(),
    Value<String?> evs = const Value.absent(),
    Value<String?> moves = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> teamSlot = const Value.absent(),
    bool? isAlive,
    DateTime? caughtAt,
  }) => Specimen(
    id: id ?? this.id,
    adventureId: adventureId.present ? adventureId.value : this.adventureId,
    speciesId: speciesId ?? this.speciesId,
    pokemonId: pokemonId ?? this.pokemonId,
    isShiny: isShiny ?? this.isShiny,
    nickname: nickname.present ? nickname.value : this.nickname,
    level: level.present ? level.value : this.level,
    nature: nature.present ? nature.value : this.nature,
    abilityId: abilityId.present ? abilityId.value : this.abilityId,
    gender: gender.present ? gender.value : this.gender,
    ballItemId: ballItemId.present ? ballItemId.value : this.ballItemId,
    caughtWhere: caughtWhere.present ? caughtWhere.value : this.caughtWhere,
    heldItemId: heldItemId.present ? heldItemId.value : this.heldItemId,
    ivs: ivs.present ? ivs.value : this.ivs,
    evs: evs.present ? evs.value : this.evs,
    moves: moves.present ? moves.value : this.moves,
    notes: notes.present ? notes.value : this.notes,
    teamSlot: teamSlot.present ? teamSlot.value : this.teamSlot,
    isAlive: isAlive ?? this.isAlive,
    caughtAt: caughtAt ?? this.caughtAt,
  );
  Specimen copyWithCompanion(SpecimensCompanion data) {
    return Specimen(
      id: data.id.present ? data.id.value : this.id,
      adventureId: data.adventureId.present
          ? data.adventureId.value
          : this.adventureId,
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      pokemonId: data.pokemonId.present ? data.pokemonId.value : this.pokemonId,
      isShiny: data.isShiny.present ? data.isShiny.value : this.isShiny,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      level: data.level.present ? data.level.value : this.level,
      nature: data.nature.present ? data.nature.value : this.nature,
      abilityId: data.abilityId.present ? data.abilityId.value : this.abilityId,
      gender: data.gender.present ? data.gender.value : this.gender,
      ballItemId: data.ballItemId.present
          ? data.ballItemId.value
          : this.ballItemId,
      caughtWhere: data.caughtWhere.present
          ? data.caughtWhere.value
          : this.caughtWhere,
      heldItemId: data.heldItemId.present
          ? data.heldItemId.value
          : this.heldItemId,
      ivs: data.ivs.present ? data.ivs.value : this.ivs,
      evs: data.evs.present ? data.evs.value : this.evs,
      moves: data.moves.present ? data.moves.value : this.moves,
      notes: data.notes.present ? data.notes.value : this.notes,
      teamSlot: data.teamSlot.present ? data.teamSlot.value : this.teamSlot,
      isAlive: data.isAlive.present ? data.isAlive.value : this.isAlive,
      caughtAt: data.caughtAt.present ? data.caughtAt.value : this.caughtAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Specimen(')
          ..write('id: $id, ')
          ..write('adventureId: $adventureId, ')
          ..write('speciesId: $speciesId, ')
          ..write('pokemonId: $pokemonId, ')
          ..write('isShiny: $isShiny, ')
          ..write('nickname: $nickname, ')
          ..write('level: $level, ')
          ..write('nature: $nature, ')
          ..write('abilityId: $abilityId, ')
          ..write('gender: $gender, ')
          ..write('ballItemId: $ballItemId, ')
          ..write('caughtWhere: $caughtWhere, ')
          ..write('heldItemId: $heldItemId, ')
          ..write('ivs: $ivs, ')
          ..write('evs: $evs, ')
          ..write('moves: $moves, ')
          ..write('notes: $notes, ')
          ..write('teamSlot: $teamSlot, ')
          ..write('isAlive: $isAlive, ')
          ..write('caughtAt: $caughtAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    adventureId,
    speciesId,
    pokemonId,
    isShiny,
    nickname,
    level,
    nature,
    abilityId,
    gender,
    ballItemId,
    caughtWhere,
    heldItemId,
    ivs,
    evs,
    moves,
    notes,
    teamSlot,
    isAlive,
    caughtAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Specimen &&
          other.id == this.id &&
          other.adventureId == this.adventureId &&
          other.speciesId == this.speciesId &&
          other.pokemonId == this.pokemonId &&
          other.isShiny == this.isShiny &&
          other.nickname == this.nickname &&
          other.level == this.level &&
          other.nature == this.nature &&
          other.abilityId == this.abilityId &&
          other.gender == this.gender &&
          other.ballItemId == this.ballItemId &&
          other.caughtWhere == this.caughtWhere &&
          other.heldItemId == this.heldItemId &&
          other.ivs == this.ivs &&
          other.evs == this.evs &&
          other.moves == this.moves &&
          other.notes == this.notes &&
          other.teamSlot == this.teamSlot &&
          other.isAlive == this.isAlive &&
          other.caughtAt == this.caughtAt);
}

class SpecimensCompanion extends UpdateCompanion<Specimen> {
  final Value<String> id;
  final Value<String?> adventureId;
  final Value<int> speciesId;
  final Value<int> pokemonId;
  final Value<bool> isShiny;
  final Value<String?> nickname;
  final Value<int?> level;
  final Value<String?> nature;
  final Value<int?> abilityId;
  final Value<String?> gender;
  final Value<int?> ballItemId;
  final Value<String?> caughtWhere;
  final Value<int?> heldItemId;
  final Value<String?> ivs;
  final Value<String?> evs;
  final Value<String?> moves;
  final Value<String?> notes;
  final Value<int?> teamSlot;
  final Value<bool> isAlive;
  final Value<DateTime> caughtAt;
  final Value<int> rowid;
  const SpecimensCompanion({
    this.id = const Value.absent(),
    this.adventureId = const Value.absent(),
    this.speciesId = const Value.absent(),
    this.pokemonId = const Value.absent(),
    this.isShiny = const Value.absent(),
    this.nickname = const Value.absent(),
    this.level = const Value.absent(),
    this.nature = const Value.absent(),
    this.abilityId = const Value.absent(),
    this.gender = const Value.absent(),
    this.ballItemId = const Value.absent(),
    this.caughtWhere = const Value.absent(),
    this.heldItemId = const Value.absent(),
    this.ivs = const Value.absent(),
    this.evs = const Value.absent(),
    this.moves = const Value.absent(),
    this.notes = const Value.absent(),
    this.teamSlot = const Value.absent(),
    this.isAlive = const Value.absent(),
    this.caughtAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SpecimensCompanion.insert({
    required String id,
    this.adventureId = const Value.absent(),
    required int speciesId,
    required int pokemonId,
    this.isShiny = const Value.absent(),
    this.nickname = const Value.absent(),
    this.level = const Value.absent(),
    this.nature = const Value.absent(),
    this.abilityId = const Value.absent(),
    this.gender = const Value.absent(),
    this.ballItemId = const Value.absent(),
    this.caughtWhere = const Value.absent(),
    this.heldItemId = const Value.absent(),
    this.ivs = const Value.absent(),
    this.evs = const Value.absent(),
    this.moves = const Value.absent(),
    this.notes = const Value.absent(),
    this.teamSlot = const Value.absent(),
    this.isAlive = const Value.absent(),
    required DateTime caughtAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       speciesId = Value(speciesId),
       pokemonId = Value(pokemonId),
       caughtAt = Value(caughtAt);
  static Insertable<Specimen> custom({
    Expression<String>? id,
    Expression<String>? adventureId,
    Expression<int>? speciesId,
    Expression<int>? pokemonId,
    Expression<bool>? isShiny,
    Expression<String>? nickname,
    Expression<int>? level,
    Expression<String>? nature,
    Expression<int>? abilityId,
    Expression<String>? gender,
    Expression<int>? ballItemId,
    Expression<String>? caughtWhere,
    Expression<int>? heldItemId,
    Expression<String>? ivs,
    Expression<String>? evs,
    Expression<String>? moves,
    Expression<String>? notes,
    Expression<int>? teamSlot,
    Expression<bool>? isAlive,
    Expression<DateTime>? caughtAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (adventureId != null) 'adventure_id': adventureId,
      if (speciesId != null) 'species_id': speciesId,
      if (pokemonId != null) 'pokemon_id': pokemonId,
      if (isShiny != null) 'is_shiny': isShiny,
      if (nickname != null) 'nickname': nickname,
      if (level != null) 'level': level,
      if (nature != null) 'nature': nature,
      if (abilityId != null) 'ability_id': abilityId,
      if (gender != null) 'gender': gender,
      if (ballItemId != null) 'ball_item_id': ballItemId,
      if (caughtWhere != null) 'caught_where': caughtWhere,
      if (heldItemId != null) 'held_item_id': heldItemId,
      if (ivs != null) 'ivs': ivs,
      if (evs != null) 'evs': evs,
      if (moves != null) 'moves': moves,
      if (notes != null) 'notes': notes,
      if (teamSlot != null) 'team_slot': teamSlot,
      if (isAlive != null) 'is_alive': isAlive,
      if (caughtAt != null) 'caught_at': caughtAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SpecimensCompanion copyWith({
    Value<String>? id,
    Value<String?>? adventureId,
    Value<int>? speciesId,
    Value<int>? pokemonId,
    Value<bool>? isShiny,
    Value<String?>? nickname,
    Value<int?>? level,
    Value<String?>? nature,
    Value<int?>? abilityId,
    Value<String?>? gender,
    Value<int?>? ballItemId,
    Value<String?>? caughtWhere,
    Value<int?>? heldItemId,
    Value<String?>? ivs,
    Value<String?>? evs,
    Value<String?>? moves,
    Value<String?>? notes,
    Value<int?>? teamSlot,
    Value<bool>? isAlive,
    Value<DateTime>? caughtAt,
    Value<int>? rowid,
  }) {
    return SpecimensCompanion(
      id: id ?? this.id,
      adventureId: adventureId ?? this.adventureId,
      speciesId: speciesId ?? this.speciesId,
      pokemonId: pokemonId ?? this.pokemonId,
      isShiny: isShiny ?? this.isShiny,
      nickname: nickname ?? this.nickname,
      level: level ?? this.level,
      nature: nature ?? this.nature,
      abilityId: abilityId ?? this.abilityId,
      gender: gender ?? this.gender,
      ballItemId: ballItemId ?? this.ballItemId,
      caughtWhere: caughtWhere ?? this.caughtWhere,
      heldItemId: heldItemId ?? this.heldItemId,
      ivs: ivs ?? this.ivs,
      evs: evs ?? this.evs,
      moves: moves ?? this.moves,
      notes: notes ?? this.notes,
      teamSlot: teamSlot ?? this.teamSlot,
      isAlive: isAlive ?? this.isAlive,
      caughtAt: caughtAt ?? this.caughtAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (adventureId.present) {
      map['adventure_id'] = Variable<String>(adventureId.value);
    }
    if (speciesId.present) {
      map['species_id'] = Variable<int>(speciesId.value);
    }
    if (pokemonId.present) {
      map['pokemon_id'] = Variable<int>(pokemonId.value);
    }
    if (isShiny.present) {
      map['is_shiny'] = Variable<bool>(isShiny.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (nature.present) {
      map['nature'] = Variable<String>(nature.value);
    }
    if (abilityId.present) {
      map['ability_id'] = Variable<int>(abilityId.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (ballItemId.present) {
      map['ball_item_id'] = Variable<int>(ballItemId.value);
    }
    if (caughtWhere.present) {
      map['caught_where'] = Variable<String>(caughtWhere.value);
    }
    if (heldItemId.present) {
      map['held_item_id'] = Variable<int>(heldItemId.value);
    }
    if (ivs.present) {
      map['ivs'] = Variable<String>(ivs.value);
    }
    if (evs.present) {
      map['evs'] = Variable<String>(evs.value);
    }
    if (moves.present) {
      map['moves'] = Variable<String>(moves.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (teamSlot.present) {
      map['team_slot'] = Variable<int>(teamSlot.value);
    }
    if (isAlive.present) {
      map['is_alive'] = Variable<bool>(isAlive.value);
    }
    if (caughtAt.present) {
      map['caught_at'] = Variable<DateTime>(caughtAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpecimensCompanion(')
          ..write('id: $id, ')
          ..write('adventureId: $adventureId, ')
          ..write('speciesId: $speciesId, ')
          ..write('pokemonId: $pokemonId, ')
          ..write('isShiny: $isShiny, ')
          ..write('nickname: $nickname, ')
          ..write('level: $level, ')
          ..write('nature: $nature, ')
          ..write('abilityId: $abilityId, ')
          ..write('gender: $gender, ')
          ..write('ballItemId: $ballItemId, ')
          ..write('caughtWhere: $caughtWhere, ')
          ..write('heldItemId: $heldItemId, ')
          ..write('ivs: $ivs, ')
          ..write('evs: $evs, ')
          ..write('moves: $moves, ')
          ..write('notes: $notes, ')
          ..write('teamSlot: $teamSlot, ')
          ..write('isAlive: $isAlive, ')
          ..write('caughtAt: $caughtAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SpeciesMarksTable extends SpeciesMarks
    with TableInfo<$SpeciesMarksTable, SpeciesMark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpeciesMarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _speciesIdMeta = const VerificationMeta(
    'speciesId',
  );
  @override
  late final GeneratedColumn<int> speciesId = GeneratedColumn<int>(
    'species_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _marksMeta = const VerificationMeta('marks');
  @override
  late final GeneratedColumn<int> marks = GeneratedColumn<int>(
    'marks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [speciesId, favorite, marks];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'species_marks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SpeciesMark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('species_id')) {
      context.handle(
        _speciesIdMeta,
        speciesId.isAcceptableOrUnknown(data['species_id']!, _speciesIdMeta),
      );
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    }
    if (data.containsKey('marks')) {
      context.handle(
        _marksMeta,
        marks.isAcceptableOrUnknown(data['marks']!, _marksMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {speciesId};
  @override
  SpeciesMark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpeciesMark(
      speciesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}species_id'],
      )!,
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      marks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}marks'],
      )!,
    );
  }

  @override
  $SpeciesMarksTable createAlias(String alias) {
    return $SpeciesMarksTable(attachedDatabase, alias);
  }
}

class SpeciesMark extends DataClass implements Insertable<SpeciesMark> {
  final int speciesId;
  final bool favorite;

  /// Bits: 1 estrela, 2 círculo, 4 triângulo, 8 quadrado, 16 coração, 32 losango.
  final int marks;
  const SpeciesMark({
    required this.speciesId,
    required this.favorite,
    required this.marks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['species_id'] = Variable<int>(speciesId);
    map['favorite'] = Variable<bool>(favorite);
    map['marks'] = Variable<int>(marks);
    return map;
  }

  SpeciesMarksCompanion toCompanion(bool nullToAbsent) {
    return SpeciesMarksCompanion(
      speciesId: Value(speciesId),
      favorite: Value(favorite),
      marks: Value(marks),
    );
  }

  factory SpeciesMark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpeciesMark(
      speciesId: serializer.fromJson<int>(json['speciesId']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      marks: serializer.fromJson<int>(json['marks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'speciesId': serializer.toJson<int>(speciesId),
      'favorite': serializer.toJson<bool>(favorite),
      'marks': serializer.toJson<int>(marks),
    };
  }

  SpeciesMark copyWith({int? speciesId, bool? favorite, int? marks}) =>
      SpeciesMark(
        speciesId: speciesId ?? this.speciesId,
        favorite: favorite ?? this.favorite,
        marks: marks ?? this.marks,
      );
  SpeciesMark copyWithCompanion(SpeciesMarksCompanion data) {
    return SpeciesMark(
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      marks: data.marks.present ? data.marks.value : this.marks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpeciesMark(')
          ..write('speciesId: $speciesId, ')
          ..write('favorite: $favorite, ')
          ..write('marks: $marks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(speciesId, favorite, marks);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpeciesMark &&
          other.speciesId == this.speciesId &&
          other.favorite == this.favorite &&
          other.marks == this.marks);
}

class SpeciesMarksCompanion extends UpdateCompanion<SpeciesMark> {
  final Value<int> speciesId;
  final Value<bool> favorite;
  final Value<int> marks;
  const SpeciesMarksCompanion({
    this.speciesId = const Value.absent(),
    this.favorite = const Value.absent(),
    this.marks = const Value.absent(),
  });
  SpeciesMarksCompanion.insert({
    this.speciesId = const Value.absent(),
    this.favorite = const Value.absent(),
    this.marks = const Value.absent(),
  });
  static Insertable<SpeciesMark> custom({
    Expression<int>? speciesId,
    Expression<bool>? favorite,
    Expression<int>? marks,
  }) {
    return RawValuesInsertable({
      if (speciesId != null) 'species_id': speciesId,
      if (favorite != null) 'favorite': favorite,
      if (marks != null) 'marks': marks,
    });
  }

  SpeciesMarksCompanion copyWith({
    Value<int>? speciesId,
    Value<bool>? favorite,
    Value<int>? marks,
  }) {
    return SpeciesMarksCompanion(
      speciesId: speciesId ?? this.speciesId,
      favorite: favorite ?? this.favorite,
      marks: marks ?? this.marks,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (speciesId.present) {
      map['species_id'] = Variable<int>(speciesId.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (marks.present) {
      map['marks'] = Variable<int>(marks.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpeciesMarksCompanion(')
          ..write('speciesId: $speciesId, ')
          ..write('favorite: $favorite, ')
          ..write('marks: $marks')
          ..write(')'))
        .toString();
  }
}

class $CustomListsTable extends CustomLists
    with TableInfo<$CustomListsTable, CustomList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomList(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CustomListsTable createAlias(String alias) {
    return $CustomListsTable(attachedDatabase, alias);
  }
}

class CustomList extends DataClass implements Insertable<CustomList> {
  final String id;
  final String name;
  final DateTime createdAt;
  const CustomList({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomListsCompanion toCompanion(bool nullToAbsent) {
    return CustomListsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory CustomList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomList(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CustomList copyWith({String? id, String? name, DateTime? createdAt}) =>
      CustomList(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  CustomList copyWithCompanion(CustomListsCompanion data) {
    return CustomList(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomList(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomList &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class CustomListsCompanion extends UpdateCompanion<CustomList> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CustomListsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomListsCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<CustomList> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomListsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CustomListsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomListsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomListItemsTable extends CustomListItems
    with TableInfo<$CustomListItemsTable, CustomListItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomListItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES custom_lists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pokemonIdMeta = const VerificationMeta(
    'pokemonId',
  );
  @override
  late final GeneratedColumn<int> pokemonId = GeneratedColumn<int>(
    'pokemon_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [listId, pokemonId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_list_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomListItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('pokemon_id')) {
      context.handle(
        _pokemonIdMeta,
        pokemonId.isAcceptableOrUnknown(data['pokemon_id']!, _pokemonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pokemonIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {listId, pokemonId};
  @override
  CustomListItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomListItem(
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      )!,
      pokemonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pokemon_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CustomListItemsTable createAlias(String alias) {
    return $CustomListItemsTable(attachedDatabase, alias);
  }
}

class CustomListItem extends DataClass implements Insertable<CustomListItem> {
  final String listId;
  final int pokemonId;
  final int position;
  const CustomListItem({
    required this.listId,
    required this.pokemonId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['list_id'] = Variable<String>(listId);
    map['pokemon_id'] = Variable<int>(pokemonId);
    map['position'] = Variable<int>(position);
    return map;
  }

  CustomListItemsCompanion toCompanion(bool nullToAbsent) {
    return CustomListItemsCompanion(
      listId: Value(listId),
      pokemonId: Value(pokemonId),
      position: Value(position),
    );
  }

  factory CustomListItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomListItem(
      listId: serializer.fromJson<String>(json['listId']),
      pokemonId: serializer.fromJson<int>(json['pokemonId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'listId': serializer.toJson<String>(listId),
      'pokemonId': serializer.toJson<int>(pokemonId),
      'position': serializer.toJson<int>(position),
    };
  }

  CustomListItem copyWith({String? listId, int? pokemonId, int? position}) =>
      CustomListItem(
        listId: listId ?? this.listId,
        pokemonId: pokemonId ?? this.pokemonId,
        position: position ?? this.position,
      );
  CustomListItem copyWithCompanion(CustomListItemsCompanion data) {
    return CustomListItem(
      listId: data.listId.present ? data.listId.value : this.listId,
      pokemonId: data.pokemonId.present ? data.pokemonId.value : this.pokemonId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomListItem(')
          ..write('listId: $listId, ')
          ..write('pokemonId: $pokemonId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(listId, pokemonId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomListItem &&
          other.listId == this.listId &&
          other.pokemonId == this.pokemonId &&
          other.position == this.position);
}

class CustomListItemsCompanion extends UpdateCompanion<CustomListItem> {
  final Value<String> listId;
  final Value<int> pokemonId;
  final Value<int> position;
  final Value<int> rowid;
  const CustomListItemsCompanion({
    this.listId = const Value.absent(),
    this.pokemonId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomListItemsCompanion.insert({
    required String listId,
    required int pokemonId,
    required int position,
    this.rowid = const Value.absent(),
  }) : listId = Value(listId),
       pokemonId = Value(pokemonId),
       position = Value(position);
  static Insertable<CustomListItem> custom({
    Expression<String>? listId,
    Expression<int>? pokemonId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (listId != null) 'list_id': listId,
      if (pokemonId != null) 'pokemon_id': pokemonId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomListItemsCompanion copyWith({
    Value<String>? listId,
    Value<int>? pokemonId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return CustomListItemsCompanion(
      listId: listId ?? this.listId,
      pokemonId: pokemonId ?? this.pokemonId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (pokemonId.present) {
      map['pokemon_id'] = Variable<int>(pokemonId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomListItemsCompanion(')
          ..write('listId: $listId, ')
          ..write('pokemonId: $pokemonId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NuzlockeEncountersTable extends NuzlockeEncounters
    with TableInfo<$NuzlockeEncountersTable, NuzlockeEncounter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NuzlockeEncountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adventureIdMeta = const VerificationMeta(
    'adventureId',
  );
  @override
  late final GeneratedColumn<String> adventureId = GeneratedColumn<String>(
    'adventure_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES adventures (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _locationAreaIdMeta = const VerificationMeta(
    'locationAreaId',
  );
  @override
  late final GeneratedColumn<int> locationAreaId = GeneratedColumn<int>(
    'location_area_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationLabelMeta = const VerificationMeta(
    'locationLabel',
  );
  @override
  late final GeneratedColumn<String> locationLabel = GeneratedColumn<String>(
    'location_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speciesIdMeta = const VerificationMeta(
    'speciesId',
  );
  @override
  late final GeneratedColumn<int> speciesId = GeneratedColumn<int>(
    'species_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _specimenIdMeta = const VerificationMeta(
    'specimenId',
  );
  @override
  late final GeneratedColumn<String> specimenId = GeneratedColumn<String>(
    'specimen_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    adventureId,
    locationAreaId,
    locationLabel,
    speciesId,
    specimenId,
    outcome,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nuzlocke_encounters';
  @override
  VerificationContext validateIntegrity(
    Insertable<NuzlockeEncounter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('adventure_id')) {
      context.handle(
        _adventureIdMeta,
        adventureId.isAcceptableOrUnknown(
          data['adventure_id']!,
          _adventureIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_adventureIdMeta);
    }
    if (data.containsKey('location_area_id')) {
      context.handle(
        _locationAreaIdMeta,
        locationAreaId.isAcceptableOrUnknown(
          data['location_area_id']!,
          _locationAreaIdMeta,
        ),
      );
    }
    if (data.containsKey('location_label')) {
      context.handle(
        _locationLabelMeta,
        locationLabel.isAcceptableOrUnknown(
          data['location_label']!,
          _locationLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_locationLabelMeta);
    }
    if (data.containsKey('species_id')) {
      context.handle(
        _speciesIdMeta,
        speciesId.isAcceptableOrUnknown(data['species_id']!, _speciesIdMeta),
      );
    }
    if (data.containsKey('specimen_id')) {
      context.handle(
        _specimenIdMeta,
        specimenId.isAcceptableOrUnknown(data['specimen_id']!, _specimenIdMeta),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NuzlockeEncounter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NuzlockeEncounter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      adventureId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adventure_id'],
      )!,
      locationAreaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}location_area_id'],
      ),
      locationLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_label'],
      )!,
      speciesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}species_id'],
      ),
      specimenId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}specimen_id'],
      ),
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $NuzlockeEncountersTable createAlias(String alias) {
    return $NuzlockeEncountersTable(attachedDatabase, alias);
  }
}

class NuzlockeEncounter extends DataClass
    implements Insertable<NuzlockeEncounter> {
  final String id;
  final String adventureId;

  /// location_areas.id ou locations.id do banco de referência; null quando é texto livre.
  final int? locationAreaId;
  final String locationLabel;
  final int? speciesId;
  final String? specimenId;

  /// caught / fainted / fled / skipped
  final String outcome;
  final DateTime createdAt;
  const NuzlockeEncounter({
    required this.id,
    required this.adventureId,
    this.locationAreaId,
    required this.locationLabel,
    this.speciesId,
    this.specimenId,
    required this.outcome,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['adventure_id'] = Variable<String>(adventureId);
    if (!nullToAbsent || locationAreaId != null) {
      map['location_area_id'] = Variable<int>(locationAreaId);
    }
    map['location_label'] = Variable<String>(locationLabel);
    if (!nullToAbsent || speciesId != null) {
      map['species_id'] = Variable<int>(speciesId);
    }
    if (!nullToAbsent || specimenId != null) {
      map['specimen_id'] = Variable<String>(specimenId);
    }
    map['outcome'] = Variable<String>(outcome);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NuzlockeEncountersCompanion toCompanion(bool nullToAbsent) {
    return NuzlockeEncountersCompanion(
      id: Value(id),
      adventureId: Value(adventureId),
      locationAreaId: locationAreaId == null && nullToAbsent
          ? const Value.absent()
          : Value(locationAreaId),
      locationLabel: Value(locationLabel),
      speciesId: speciesId == null && nullToAbsent
          ? const Value.absent()
          : Value(speciesId),
      specimenId: specimenId == null && nullToAbsent
          ? const Value.absent()
          : Value(specimenId),
      outcome: Value(outcome),
      createdAt: Value(createdAt),
    );
  }

  factory NuzlockeEncounter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NuzlockeEncounter(
      id: serializer.fromJson<String>(json['id']),
      adventureId: serializer.fromJson<String>(json['adventureId']),
      locationAreaId: serializer.fromJson<int?>(json['locationAreaId']),
      locationLabel: serializer.fromJson<String>(json['locationLabel']),
      speciesId: serializer.fromJson<int?>(json['speciesId']),
      specimenId: serializer.fromJson<String?>(json['specimenId']),
      outcome: serializer.fromJson<String>(json['outcome']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'adventureId': serializer.toJson<String>(adventureId),
      'locationAreaId': serializer.toJson<int?>(locationAreaId),
      'locationLabel': serializer.toJson<String>(locationLabel),
      'speciesId': serializer.toJson<int?>(speciesId),
      'specimenId': serializer.toJson<String?>(specimenId),
      'outcome': serializer.toJson<String>(outcome),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NuzlockeEncounter copyWith({
    String? id,
    String? adventureId,
    Value<int?> locationAreaId = const Value.absent(),
    String? locationLabel,
    Value<int?> speciesId = const Value.absent(),
    Value<String?> specimenId = const Value.absent(),
    String? outcome,
    DateTime? createdAt,
  }) => NuzlockeEncounter(
    id: id ?? this.id,
    adventureId: adventureId ?? this.adventureId,
    locationAreaId: locationAreaId.present
        ? locationAreaId.value
        : this.locationAreaId,
    locationLabel: locationLabel ?? this.locationLabel,
    speciesId: speciesId.present ? speciesId.value : this.speciesId,
    specimenId: specimenId.present ? specimenId.value : this.specimenId,
    outcome: outcome ?? this.outcome,
    createdAt: createdAt ?? this.createdAt,
  );
  NuzlockeEncounter copyWithCompanion(NuzlockeEncountersCompanion data) {
    return NuzlockeEncounter(
      id: data.id.present ? data.id.value : this.id,
      adventureId: data.adventureId.present
          ? data.adventureId.value
          : this.adventureId,
      locationAreaId: data.locationAreaId.present
          ? data.locationAreaId.value
          : this.locationAreaId,
      locationLabel: data.locationLabel.present
          ? data.locationLabel.value
          : this.locationLabel,
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      specimenId: data.specimenId.present
          ? data.specimenId.value
          : this.specimenId,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NuzlockeEncounter(')
          ..write('id: $id, ')
          ..write('adventureId: $adventureId, ')
          ..write('locationAreaId: $locationAreaId, ')
          ..write('locationLabel: $locationLabel, ')
          ..write('speciesId: $speciesId, ')
          ..write('specimenId: $specimenId, ')
          ..write('outcome: $outcome, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    adventureId,
    locationAreaId,
    locationLabel,
    speciesId,
    specimenId,
    outcome,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NuzlockeEncounter &&
          other.id == this.id &&
          other.adventureId == this.adventureId &&
          other.locationAreaId == this.locationAreaId &&
          other.locationLabel == this.locationLabel &&
          other.speciesId == this.speciesId &&
          other.specimenId == this.specimenId &&
          other.outcome == this.outcome &&
          other.createdAt == this.createdAt);
}

class NuzlockeEncountersCompanion extends UpdateCompanion<NuzlockeEncounter> {
  final Value<String> id;
  final Value<String> adventureId;
  final Value<int?> locationAreaId;
  final Value<String> locationLabel;
  final Value<int?> speciesId;
  final Value<String?> specimenId;
  final Value<String> outcome;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const NuzlockeEncountersCompanion({
    this.id = const Value.absent(),
    this.adventureId = const Value.absent(),
    this.locationAreaId = const Value.absent(),
    this.locationLabel = const Value.absent(),
    this.speciesId = const Value.absent(),
    this.specimenId = const Value.absent(),
    this.outcome = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NuzlockeEncountersCompanion.insert({
    required String id,
    required String adventureId,
    this.locationAreaId = const Value.absent(),
    required String locationLabel,
    this.speciesId = const Value.absent(),
    this.specimenId = const Value.absent(),
    required String outcome,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       adventureId = Value(adventureId),
       locationLabel = Value(locationLabel),
       outcome = Value(outcome),
       createdAt = Value(createdAt);
  static Insertable<NuzlockeEncounter> custom({
    Expression<String>? id,
    Expression<String>? adventureId,
    Expression<int>? locationAreaId,
    Expression<String>? locationLabel,
    Expression<int>? speciesId,
    Expression<String>? specimenId,
    Expression<String>? outcome,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (adventureId != null) 'adventure_id': adventureId,
      if (locationAreaId != null) 'location_area_id': locationAreaId,
      if (locationLabel != null) 'location_label': locationLabel,
      if (speciesId != null) 'species_id': speciesId,
      if (specimenId != null) 'specimen_id': specimenId,
      if (outcome != null) 'outcome': outcome,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NuzlockeEncountersCompanion copyWith({
    Value<String>? id,
    Value<String>? adventureId,
    Value<int?>? locationAreaId,
    Value<String>? locationLabel,
    Value<int?>? speciesId,
    Value<String?>? specimenId,
    Value<String>? outcome,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return NuzlockeEncountersCompanion(
      id: id ?? this.id,
      adventureId: adventureId ?? this.adventureId,
      locationAreaId: locationAreaId ?? this.locationAreaId,
      locationLabel: locationLabel ?? this.locationLabel,
      speciesId: speciesId ?? this.speciesId,
      specimenId: specimenId ?? this.specimenId,
      outcome: outcome ?? this.outcome,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (adventureId.present) {
      map['adventure_id'] = Variable<String>(adventureId.value);
    }
    if (locationAreaId.present) {
      map['location_area_id'] = Variable<int>(locationAreaId.value);
    }
    if (locationLabel.present) {
      map['location_label'] = Variable<String>(locationLabel.value);
    }
    if (speciesId.present) {
      map['species_id'] = Variable<int>(speciesId.value);
    }
    if (specimenId.present) {
      map['specimen_id'] = Variable<String>(specimenId.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NuzlockeEncountersCompanion(')
          ..write('id: $id, ')
          ..write('adventureId: $adventureId, ')
          ..write('locationAreaId: $locationAreaId, ')
          ..write('locationLabel: $locationLabel, ')
          ..write('speciesId: $speciesId, ')
          ..write('specimenId: $specimenId, ')
          ..write('outcome: $outcome, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDatabase extends GeneratedDatabase {
  _$UserDatabase(QueryExecutor e) : super(e);
  $UserDatabaseManager get managers => $UserDatabaseManager(this);
  late final $AdventuresTable adventures = $AdventuresTable(this);
  late final $SpecimensTable specimens = $SpecimensTable(this);
  late final $SpeciesMarksTable speciesMarks = $SpeciesMarksTable(this);
  late final $CustomListsTable customLists = $CustomListsTable(this);
  late final $CustomListItemsTable customListItems = $CustomListItemsTable(
    this,
  );
  late final $NuzlockeEncountersTable nuzlockeEncounters =
      $NuzlockeEncountersTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    adventures,
    specimens,
    speciesMarks,
    customLists,
    customListItems,
    nuzlockeEncounters,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'adventures',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('specimens', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'custom_lists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('custom_list_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'adventures',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('nuzlocke_encounters', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AdventuresTableCreateCompanionBuilder = AdventuresCompanion Function({
  required String id,
  required String name,
  required int versionGroupId,
  Value<int?> versionId,
  Value<bool> isNuzlocke,
  Value<String?> nuzlockeRules,
  Value<bool> archived,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$AdventuresTableUpdateCompanionBuilder = AdventuresCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> versionGroupId,
  Value<int?> versionId,
  Value<bool> isNuzlocke,
  Value<String?> nuzlockeRules,
  Value<bool> archived,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$AdventuresTableReferences
    extends BaseReferences<_$UserDatabase, $AdventuresTable, Adventure> {
  $$AdventuresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SpecimensTable, List<Specimen>>
  _specimensRefsTable(_$UserDatabase db) => MultiTypedResultKey.fromTable(
    db.specimens,
    aliasName: 'adventures__id__specimens__adventure_id',
  );

  $$SpecimensTableProcessedTableManager get specimensRefs {
    final manager = $$SpecimensTableTableManager(
      $_db,
      $_db.specimens,
    ).filter((f) => f.adventureId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_specimensRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NuzlockeEncountersTable, List<NuzlockeEncounter>>
  _nuzlockeEncountersRefsTable(_$UserDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.nuzlockeEncounters,
        aliasName: 'adventures__id__nuzlocke_encounters__adventure_id',
      );

  $$NuzlockeEncountersTableProcessedTableManager get nuzlockeEncountersRefs {
    final manager = $$NuzlockeEncountersTableTableManager(
      $_db,
      $_db.nuzlockeEncounters,
    ).filter((f) => f.adventureId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _nuzlockeEncountersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AdventuresTableFilterComposer
    extends Composer<_$UserDatabase, $AdventuresTable> {
  $$AdventuresTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versionGroupId => $composableBuilder(
    column: $table.versionGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versionId => $composableBuilder(
    column: $table.versionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isNuzlocke => $composableBuilder(
    column: $table.isNuzlocke,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nuzlockeRules => $composableBuilder(
    column: $table.nuzlockeRules,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> specimensRefs(
    Expression<bool> Function($$SpecimensTableFilterComposer f) f,
  ) {
    final $$SpecimensTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.specimens,
      getReferencedColumn: (t) => t.adventureId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpecimensTableFilterComposer(
            $db: $db,
            $table: $db.specimens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> nuzlockeEncountersRefs(
    Expression<bool> Function($$NuzlockeEncountersTableFilterComposer f) f,
  ) {
    final $$NuzlockeEncountersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nuzlockeEncounters,
      getReferencedColumn: (t) => t.adventureId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NuzlockeEncountersTableFilterComposer(
            $db: $db,
            $table: $db.nuzlockeEncounters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AdventuresTableOrderingComposer
    extends Composer<_$UserDatabase, $AdventuresTable> {
  $$AdventuresTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versionGroupId => $composableBuilder(
    column: $table.versionGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versionId => $composableBuilder(
    column: $table.versionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isNuzlocke => $composableBuilder(
    column: $table.isNuzlocke,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nuzlockeRules => $composableBuilder(
    column: $table.nuzlockeRules,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdventuresTableAnnotationComposer
    extends Composer<_$UserDatabase, $AdventuresTable> {
  $$AdventuresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get versionGroupId => $composableBuilder(
    column: $table.versionGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get versionId =>
      $composableBuilder(column: $table.versionId, builder: (column) => column);

  GeneratedColumn<bool> get isNuzlocke => $composableBuilder(
    column: $table.isNuzlocke,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nuzlockeRules => $composableBuilder(
    column: $table.nuzlockeRules,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> specimensRefs<T extends Object>(
    Expression<T> Function($$SpecimensTableAnnotationComposer a) f,
  ) {
    final $$SpecimensTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.specimens,
      getReferencedColumn: (t) => t.adventureId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpecimensTableAnnotationComposer(
            $db: $db,
            $table: $db.specimens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> nuzlockeEncountersRefs<T extends Object>(
    Expression<T> Function($$NuzlockeEncountersTableAnnotationComposer a) f,
  ) {
    final $$NuzlockeEncountersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.nuzlockeEncounters,
          getReferencedColumn: (t) => t.adventureId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$NuzlockeEncountersTableAnnotationComposer(
                $db: $db,
                $table: $db.nuzlockeEncounters,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AdventuresTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $AdventuresTable,
          Adventure,
          $$AdventuresTableFilterComposer,
          $$AdventuresTableOrderingComposer,
          $$AdventuresTableAnnotationComposer,
          $$AdventuresTableCreateCompanionBuilder,
          $$AdventuresTableUpdateCompanionBuilder,
          (Adventure, $$AdventuresTableReferences),
          Adventure,
          PrefetchHooks Function({
            bool specimensRefs,
            bool nuzlockeEncountersRefs,
          })
        > {
  $$AdventuresTableTableManager(_$UserDatabase db, $AdventuresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdventuresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdventuresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdventuresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> versionGroupId = const Value.absent(),
                Value<int?> versionId = const Value.absent(),
                Value<bool> isNuzlocke = const Value.absent(),
                Value<String?> nuzlockeRules = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdventuresCompanion(
                id: id,
                name: name,
                versionGroupId: versionGroupId,
                versionId: versionId,
                isNuzlocke: isNuzlocke,
                nuzlockeRules: nuzlockeRules,
                archived: archived,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int versionGroupId,
                Value<int?> versionId = const Value.absent(),
                Value<bool> isNuzlocke = const Value.absent(),
                Value<String?> nuzlockeRules = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AdventuresCompanion.insert(
                id: id,
                name: name,
                versionGroupId: versionGroupId,
                versionId: versionId,
                isNuzlocke: isNuzlocke,
                nuzlockeRules: nuzlockeRules,
                archived: archived,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AdventuresTable, Adventure>(table),
                  $$AdventuresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({specimensRefs = false, nuzlockeEncountersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (specimensRefs) db.specimens,
                    if (nuzlockeEncountersRefs) db.nuzlockeEncounters,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (specimensRefs)
                        await $_getPrefetchedData<
                          Adventure,
                          $AdventuresTable,
                          Specimen
                        >(
                          currentTable: table,
                          referencedTable: $$AdventuresTableReferences
                              ._specimensRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AdventuresTableReferences(
                                db,
                                table,
                                p0,
                              ).specimensRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.adventureId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (nuzlockeEncountersRefs)
                        await $_getPrefetchedData<
                          Adventure,
                          $AdventuresTable,
                          NuzlockeEncounter
                        >(
                          currentTable: table,
                          referencedTable: $$AdventuresTableReferences
                              ._nuzlockeEncountersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AdventuresTableReferences(
                                db,
                                table,
                                p0,
                              ).nuzlockeEncountersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.adventureId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AdventuresTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $AdventuresTable,
      Adventure,
      $$AdventuresTableFilterComposer,
      $$AdventuresTableOrderingComposer,
      $$AdventuresTableAnnotationComposer,
      $$AdventuresTableCreateCompanionBuilder,
      $$AdventuresTableUpdateCompanionBuilder,
      (Adventure, $$AdventuresTableReferences),
      Adventure,
      PrefetchHooks Function({bool specimensRefs, bool nuzlockeEncountersRefs})
    >;
typedef $$SpecimensTableCreateCompanionBuilder = SpecimensCompanion Function({
  required String id,
  Value<String?> adventureId,
  required int speciesId,
  required int pokemonId,
  Value<bool> isShiny,
  Value<String?> nickname,
  Value<int?> level,
  Value<String?> nature,
  Value<int?> abilityId,
  Value<String?> gender,
  Value<int?> ballItemId,
  Value<String?> caughtWhere,
  Value<int?> heldItemId,
  Value<String?> ivs,
  Value<String?> evs,
  Value<String?> moves,
  Value<String?> notes,
  Value<int?> teamSlot,
  Value<bool> isAlive,
  required DateTime caughtAt,
  Value<int> rowid,
});
typedef $$SpecimensTableUpdateCompanionBuilder = SpecimensCompanion Function({
  Value<String> id,
  Value<String?> adventureId,
  Value<int> speciesId,
  Value<int> pokemonId,
  Value<bool> isShiny,
  Value<String?> nickname,
  Value<int?> level,
  Value<String?> nature,
  Value<int?> abilityId,
  Value<String?> gender,
  Value<int?> ballItemId,
  Value<String?> caughtWhere,
  Value<int?> heldItemId,
  Value<String?> ivs,
  Value<String?> evs,
  Value<String?> moves,
  Value<String?> notes,
  Value<int?> teamSlot,
  Value<bool> isAlive,
  Value<DateTime> caughtAt,
  Value<int> rowid,
});

final class $$SpecimensTableReferences
    extends BaseReferences<_$UserDatabase, $SpecimensTable, Specimen> {
  $$SpecimensTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AdventuresTable _adventureIdTable(_$UserDatabase db) =>
      db.adventures.createAlias('specimens__adventure_id__adventures__id');

  $$AdventuresTableProcessedTableManager? get adventureId {
    final $_column = $_itemColumn<String>('adventure_id');
    if ($_column == null) return null;
    final manager = $$AdventuresTableTableManager(
      $_db,
      $_db.adventures,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_adventureIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SpecimensTableFilterComposer
    extends Composer<_$UserDatabase, $SpecimensTable> {
  $$SpecimensTableFilterComposer({
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

  ColumnFilters<int> get speciesId => $composableBuilder(
    column: $table.speciesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pokemonId => $composableBuilder(
    column: $table.pokemonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isShiny => $composableBuilder(
    column: $table.isShiny,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nature => $composableBuilder(
    column: $table.nature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get abilityId => $composableBuilder(
    column: $table.abilityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ballItemId => $composableBuilder(
    column: $table.ballItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caughtWhere => $composableBuilder(
    column: $table.caughtWhere,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heldItemId => $composableBuilder(
    column: $table.heldItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ivs => $composableBuilder(
    column: $table.ivs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evs => $composableBuilder(
    column: $table.evs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamSlot => $composableBuilder(
    column: $table.teamSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAlive => $composableBuilder(
    column: $table.isAlive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get caughtAt => $composableBuilder(
    column: $table.caughtAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AdventuresTableFilterComposer get adventureId {
    final $$AdventuresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adventureId,
      referencedTable: $db.adventures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdventuresTableFilterComposer(
            $db: $db,
            $table: $db.adventures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SpecimensTableOrderingComposer
    extends Composer<_$UserDatabase, $SpecimensTable> {
  $$SpecimensTableOrderingComposer({
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

  ColumnOrderings<int> get speciesId => $composableBuilder(
    column: $table.speciesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pokemonId => $composableBuilder(
    column: $table.pokemonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isShiny => $composableBuilder(
    column: $table.isShiny,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nature => $composableBuilder(
    column: $table.nature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get abilityId => $composableBuilder(
    column: $table.abilityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ballItemId => $composableBuilder(
    column: $table.ballItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caughtWhere => $composableBuilder(
    column: $table.caughtWhere,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heldItemId => $composableBuilder(
    column: $table.heldItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ivs => $composableBuilder(
    column: $table.ivs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evs => $composableBuilder(
    column: $table.evs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamSlot => $composableBuilder(
    column: $table.teamSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAlive => $composableBuilder(
    column: $table.isAlive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get caughtAt => $composableBuilder(
    column: $table.caughtAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AdventuresTableOrderingComposer get adventureId {
    final $$AdventuresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adventureId,
      referencedTable: $db.adventures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdventuresTableOrderingComposer(
            $db: $db,
            $table: $db.adventures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SpecimensTableAnnotationComposer
    extends Composer<_$UserDatabase, $SpecimensTable> {
  $$SpecimensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get speciesId =>
      $composableBuilder(column: $table.speciesId, builder: (column) => column);

  GeneratedColumn<int> get pokemonId =>
      $composableBuilder(column: $table.pokemonId, builder: (column) => column);

  GeneratedColumn<bool> get isShiny =>
      $composableBuilder(column: $table.isShiny, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get nature =>
      $composableBuilder(column: $table.nature, builder: (column) => column);

  GeneratedColumn<int> get abilityId =>
      $composableBuilder(column: $table.abilityId, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<int> get ballItemId => $composableBuilder(
    column: $table.ballItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get caughtWhere => $composableBuilder(
    column: $table.caughtWhere,
    builder: (column) => column,
  );

  GeneratedColumn<int> get heldItemId => $composableBuilder(
    column: $table.heldItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ivs =>
      $composableBuilder(column: $table.ivs, builder: (column) => column);

  GeneratedColumn<String> get evs =>
      $composableBuilder(column: $table.evs, builder: (column) => column);

  GeneratedColumn<String> get moves =>
      $composableBuilder(column: $table.moves, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get teamSlot =>
      $composableBuilder(column: $table.teamSlot, builder: (column) => column);

  GeneratedColumn<bool> get isAlive =>
      $composableBuilder(column: $table.isAlive, builder: (column) => column);

  GeneratedColumn<DateTime> get caughtAt =>
      $composableBuilder(column: $table.caughtAt, builder: (column) => column);

  $$AdventuresTableAnnotationComposer get adventureId {
    final $$AdventuresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adventureId,
      referencedTable: $db.adventures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdventuresTableAnnotationComposer(
            $db: $db,
            $table: $db.adventures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SpecimensTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $SpecimensTable,
          Specimen,
          $$SpecimensTableFilterComposer,
          $$SpecimensTableOrderingComposer,
          $$SpecimensTableAnnotationComposer,
          $$SpecimensTableCreateCompanionBuilder,
          $$SpecimensTableUpdateCompanionBuilder,
          (Specimen, $$SpecimensTableReferences),
          Specimen,
          PrefetchHooks Function({bool adventureId})
        > {
  $$SpecimensTableTableManager(_$UserDatabase db, $SpecimensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpecimensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpecimensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpecimensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> adventureId = const Value.absent(),
                Value<int> speciesId = const Value.absent(),
                Value<int> pokemonId = const Value.absent(),
                Value<bool> isShiny = const Value.absent(),
                Value<String?> nickname = const Value.absent(),
                Value<int?> level = const Value.absent(),
                Value<String?> nature = const Value.absent(),
                Value<int?> abilityId = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<int?> ballItemId = const Value.absent(),
                Value<String?> caughtWhere = const Value.absent(),
                Value<int?> heldItemId = const Value.absent(),
                Value<String?> ivs = const Value.absent(),
                Value<String?> evs = const Value.absent(),
                Value<String?> moves = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> teamSlot = const Value.absent(),
                Value<bool> isAlive = const Value.absent(),
                Value<DateTime> caughtAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SpecimensCompanion(
                id: id,
                adventureId: adventureId,
                speciesId: speciesId,
                pokemonId: pokemonId,
                isShiny: isShiny,
                nickname: nickname,
                level: level,
                nature: nature,
                abilityId: abilityId,
                gender: gender,
                ballItemId: ballItemId,
                caughtWhere: caughtWhere,
                heldItemId: heldItemId,
                ivs: ivs,
                evs: evs,
                moves: moves,
                notes: notes,
                teamSlot: teamSlot,
                isAlive: isAlive,
                caughtAt: caughtAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> adventureId = const Value.absent(),
                required int speciesId,
                required int pokemonId,
                Value<bool> isShiny = const Value.absent(),
                Value<String?> nickname = const Value.absent(),
                Value<int?> level = const Value.absent(),
                Value<String?> nature = const Value.absent(),
                Value<int?> abilityId = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<int?> ballItemId = const Value.absent(),
                Value<String?> caughtWhere = const Value.absent(),
                Value<int?> heldItemId = const Value.absent(),
                Value<String?> ivs = const Value.absent(),
                Value<String?> evs = const Value.absent(),
                Value<String?> moves = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> teamSlot = const Value.absent(),
                Value<bool> isAlive = const Value.absent(),
                required DateTime caughtAt,
                Value<int> rowid = const Value.absent(),
              }) => SpecimensCompanion.insert(
                id: id,
                adventureId: adventureId,
                speciesId: speciesId,
                pokemonId: pokemonId,
                isShiny: isShiny,
                nickname: nickname,
                level: level,
                nature: nature,
                abilityId: abilityId,
                gender: gender,
                ballItemId: ballItemId,
                caughtWhere: caughtWhere,
                heldItemId: heldItemId,
                ivs: ivs,
                evs: evs,
                moves: moves,
                notes: notes,
                teamSlot: teamSlot,
                isAlive: isAlive,
                caughtAt: caughtAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SpecimensTable, Specimen>(table),
                  $$SpecimensTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({adventureId = false}) {
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
                    if (adventureId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.adventureId,
                        referencedTable: $$SpecimensTableReferences
                            ._adventureIdTable(db),
                        referencedColumn: $$SpecimensTableReferences
                            ._adventureIdTable(db)
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

typedef $$SpecimensTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $SpecimensTable,
      Specimen,
      $$SpecimensTableFilterComposer,
      $$SpecimensTableOrderingComposer,
      $$SpecimensTableAnnotationComposer,
      $$SpecimensTableCreateCompanionBuilder,
      $$SpecimensTableUpdateCompanionBuilder,
      (Specimen, $$SpecimensTableReferences),
      Specimen,
      PrefetchHooks Function({bool adventureId})
    >;
typedef $$SpeciesMarksTableCreateCompanionBuilder =
    SpeciesMarksCompanion Function({
      Value<int> speciesId,
      Value<bool> favorite,
      Value<int> marks,
    });
typedef $$SpeciesMarksTableUpdateCompanionBuilder =
    SpeciesMarksCompanion Function({
      Value<int> speciesId,
      Value<bool> favorite,
      Value<int> marks,
    });

class $$SpeciesMarksTableFilterComposer
    extends Composer<_$UserDatabase, $SpeciesMarksTable> {
  $$SpeciesMarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get speciesId => $composableBuilder(
    column: $table.speciesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get marks => $composableBuilder(
    column: $table.marks,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SpeciesMarksTableOrderingComposer
    extends Composer<_$UserDatabase, $SpeciesMarksTable> {
  $$SpeciesMarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get speciesId => $composableBuilder(
    column: $table.speciesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get marks => $composableBuilder(
    column: $table.marks,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SpeciesMarksTableAnnotationComposer
    extends Composer<_$UserDatabase, $SpeciesMarksTable> {
  $$SpeciesMarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get speciesId =>
      $composableBuilder(column: $table.speciesId, builder: (column) => column);

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<int> get marks =>
      $composableBuilder(column: $table.marks, builder: (column) => column);
}

class $$SpeciesMarksTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $SpeciesMarksTable,
          SpeciesMark,
          $$SpeciesMarksTableFilterComposer,
          $$SpeciesMarksTableOrderingComposer,
          $$SpeciesMarksTableAnnotationComposer,
          $$SpeciesMarksTableCreateCompanionBuilder,
          $$SpeciesMarksTableUpdateCompanionBuilder,
          (
            SpeciesMark,
            BaseReferences<_$UserDatabase, $SpeciesMarksTable, SpeciesMark>,
          ),
          SpeciesMark,
          PrefetchHooks Function()
        > {
  $$SpeciesMarksTableTableManager(_$UserDatabase db, $SpeciesMarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpeciesMarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpeciesMarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpeciesMarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> speciesId = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<int> marks = const Value.absent(),
              }) => SpeciesMarksCompanion(
                speciesId: speciesId,
                favorite: favorite,
                marks: marks,
              ),
          createCompanionCallback:
              ({
                Value<int> speciesId = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<int> marks = const Value.absent(),
              }) => SpeciesMarksCompanion.insert(
                speciesId: speciesId,
                favorite: favorite,
                marks: marks,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SpeciesMarksTable, SpeciesMark>(table),
                  BaseReferences<
                    _$UserDatabase,
                    $SpeciesMarksTable,
                    SpeciesMark
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SpeciesMarksTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $SpeciesMarksTable,
      SpeciesMark,
      $$SpeciesMarksTableFilterComposer,
      $$SpeciesMarksTableOrderingComposer,
      $$SpeciesMarksTableAnnotationComposer,
      $$SpeciesMarksTableCreateCompanionBuilder,
      $$SpeciesMarksTableUpdateCompanionBuilder,
      (
        SpeciesMark,
        BaseReferences<_$UserDatabase, $SpeciesMarksTable, SpeciesMark>,
      ),
      SpeciesMark,
      PrefetchHooks Function()
    >;
typedef $$CustomListsTableCreateCompanionBuilder =
    CustomListsCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CustomListsTableUpdateCompanionBuilder =
    CustomListsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CustomListsTableReferences
    extends BaseReferences<_$UserDatabase, $CustomListsTable, CustomList> {
  $$CustomListsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CustomListItemsTable, List<CustomListItem>>
  _customListItemsRefsTable(_$UserDatabase db) => MultiTypedResultKey.fromTable(
    db.customListItems,
    aliasName: 'custom_lists__id__custom_list_items__list_id',
  );

  $$CustomListItemsTableProcessedTableManager get customListItemsRefs {
    final manager = $$CustomListItemsTableTableManager(
      $_db,
      $_db.customListItems,
    ).filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _customListItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomListsTableFilterComposer
    extends Composer<_$UserDatabase, $CustomListsTable> {
  $$CustomListsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> customListItemsRefs(
    Expression<bool> Function($$CustomListItemsTableFilterComposer f) f,
  ) {
    final $$CustomListItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customListItems,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomListItemsTableFilterComposer(
            $db: $db,
            $table: $db.customListItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomListsTableOrderingComposer
    extends Composer<_$UserDatabase, $CustomListsTable> {
  $$CustomListsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomListsTableAnnotationComposer
    extends Composer<_$UserDatabase, $CustomListsTable> {
  $$CustomListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> customListItemsRefs<T extends Object>(
    Expression<T> Function($$CustomListItemsTableAnnotationComposer a) f,
  ) {
    final $$CustomListItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customListItems,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomListItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.customListItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomListsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $CustomListsTable,
          CustomList,
          $$CustomListsTableFilterComposer,
          $$CustomListsTableOrderingComposer,
          $$CustomListsTableAnnotationComposer,
          $$CustomListsTableCreateCompanionBuilder,
          $$CustomListsTableUpdateCompanionBuilder,
          (CustomList, $$CustomListsTableReferences),
          CustomList,
          PrefetchHooks Function({bool customListItemsRefs})
        > {
  $$CustomListsTableTableManager(_$UserDatabase db, $CustomListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomListsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CustomListsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomListsTable, CustomList>(table),
                  $$CustomListsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({customListItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (customListItemsRefs) db.customListItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (customListItemsRefs)
                    await $_getPrefetchedData<
                      CustomList,
                      $CustomListsTable,
                      CustomListItem
                    >(
                      currentTable: table,
                      referencedTable: $$CustomListsTableReferences
                          ._customListItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CustomListsTableReferences(
                            db,
                            table,
                            p0,
                          ).customListItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.listId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CustomListsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $CustomListsTable,
      CustomList,
      $$CustomListsTableFilterComposer,
      $$CustomListsTableOrderingComposer,
      $$CustomListsTableAnnotationComposer,
      $$CustomListsTableCreateCompanionBuilder,
      $$CustomListsTableUpdateCompanionBuilder,
      (CustomList, $$CustomListsTableReferences),
      CustomList,
      PrefetchHooks Function({bool customListItemsRefs})
    >;
typedef $$CustomListItemsTableCreateCompanionBuilder =
    CustomListItemsCompanion Function({
      required String listId,
      required int pokemonId,
      required int position,
      Value<int> rowid,
    });
typedef $$CustomListItemsTableUpdateCompanionBuilder =
    CustomListItemsCompanion Function({
      Value<String> listId,
      Value<int> pokemonId,
      Value<int> position,
      Value<int> rowid,
    });

final class $$CustomListItemsTableReferences
    extends
        BaseReferences<_$UserDatabase, $CustomListItemsTable, CustomListItem> {
  $$CustomListItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CustomListsTable _listIdTable(_$UserDatabase db) => db.customLists
      .createAlias('custom_list_items__list_id__custom_lists__id');

  $$CustomListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<String>('list_id')!;

    final manager = $$CustomListsTableTableManager(
      $_db,
      $_db.customLists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CustomListItemsTableFilterComposer
    extends Composer<_$UserDatabase, $CustomListItemsTable> {
  $$CustomListItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get pokemonId => $composableBuilder(
    column: $table.pokemonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomListsTableFilterComposer get listId {
    final $$CustomListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.customLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomListsTableFilterComposer(
            $db: $db,
            $table: $db.customLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomListItemsTableOrderingComposer
    extends Composer<_$UserDatabase, $CustomListItemsTable> {
  $$CustomListItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get pokemonId => $composableBuilder(
    column: $table.pokemonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomListsTableOrderingComposer get listId {
    final $$CustomListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.customLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomListsTableOrderingComposer(
            $db: $db,
            $table: $db.customLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomListItemsTableAnnotationComposer
    extends Composer<_$UserDatabase, $CustomListItemsTable> {
  $$CustomListItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get pokemonId =>
      $composableBuilder(column: $table.pokemonId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$CustomListsTableAnnotationComposer get listId {
    final $$CustomListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.customLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomListsTableAnnotationComposer(
            $db: $db,
            $table: $db.customLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomListItemsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $CustomListItemsTable,
          CustomListItem,
          $$CustomListItemsTableFilterComposer,
          $$CustomListItemsTableOrderingComposer,
          $$CustomListItemsTableAnnotationComposer,
          $$CustomListItemsTableCreateCompanionBuilder,
          $$CustomListItemsTableUpdateCompanionBuilder,
          (CustomListItem, $$CustomListItemsTableReferences),
          CustomListItem,
          PrefetchHooks Function({bool listId})
        > {
  $$CustomListItemsTableTableManager(
    _$UserDatabase db,
    $CustomListItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomListItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomListItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomListItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> listId = const Value.absent(),
                Value<int> pokemonId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomListItemsCompanion(
                listId: listId,
                pokemonId: pokemonId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String listId,
                required int pokemonId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => CustomListItemsCompanion.insert(
                listId: listId,
                pokemonId: pokemonId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomListItemsTable, CustomListItem>(table),
                  $$CustomListItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listId = false}) {
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
                    if (listId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.listId,
                        referencedTable: $$CustomListItemsTableReferences
                            ._listIdTable(db),
                        referencedColumn: $$CustomListItemsTableReferences
                            ._listIdTable(db)
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

typedef $$CustomListItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $CustomListItemsTable,
      CustomListItem,
      $$CustomListItemsTableFilterComposer,
      $$CustomListItemsTableOrderingComposer,
      $$CustomListItemsTableAnnotationComposer,
      $$CustomListItemsTableCreateCompanionBuilder,
      $$CustomListItemsTableUpdateCompanionBuilder,
      (CustomListItem, $$CustomListItemsTableReferences),
      CustomListItem,
      PrefetchHooks Function({bool listId})
    >;
typedef $$NuzlockeEncountersTableCreateCompanionBuilder =
    NuzlockeEncountersCompanion Function({
      required String id,
      required String adventureId,
      Value<int?> locationAreaId,
      required String locationLabel,
      Value<int?> speciesId,
      Value<String?> specimenId,
      required String outcome,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$NuzlockeEncountersTableUpdateCompanionBuilder =
    NuzlockeEncountersCompanion Function({
      Value<String> id,
      Value<String> adventureId,
      Value<int?> locationAreaId,
      Value<String> locationLabel,
      Value<int?> speciesId,
      Value<String?> specimenId,
      Value<String> outcome,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$NuzlockeEncountersTableReferences
    extends
        BaseReferences<
          _$UserDatabase,
          $NuzlockeEncountersTable,
          NuzlockeEncounter
        > {
  $$NuzlockeEncountersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AdventuresTable _adventureIdTable(_$UserDatabase db) => db.adventures
      .createAlias('nuzlocke_encounters__adventure_id__adventures__id');

  $$AdventuresTableProcessedTableManager get adventureId {
    final $_column = $_itemColumn<String>('adventure_id')!;

    final manager = $$AdventuresTableTableManager(
      $_db,
      $_db.adventures,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_adventureIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NuzlockeEncountersTableFilterComposer
    extends Composer<_$UserDatabase, $NuzlockeEncountersTable> {
  $$NuzlockeEncountersTableFilterComposer({
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

  ColumnFilters<int> get locationAreaId => $composableBuilder(
    column: $table.locationAreaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationLabel => $composableBuilder(
    column: $table.locationLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get speciesId => $composableBuilder(
    column: $table.speciesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specimenId => $composableBuilder(
    column: $table.specimenId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AdventuresTableFilterComposer get adventureId {
    final $$AdventuresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adventureId,
      referencedTable: $db.adventures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdventuresTableFilterComposer(
            $db: $db,
            $table: $db.adventures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NuzlockeEncountersTableOrderingComposer
    extends Composer<_$UserDatabase, $NuzlockeEncountersTable> {
  $$NuzlockeEncountersTableOrderingComposer({
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

  ColumnOrderings<int> get locationAreaId => $composableBuilder(
    column: $table.locationAreaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationLabel => $composableBuilder(
    column: $table.locationLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get speciesId => $composableBuilder(
    column: $table.speciesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specimenId => $composableBuilder(
    column: $table.specimenId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AdventuresTableOrderingComposer get adventureId {
    final $$AdventuresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adventureId,
      referencedTable: $db.adventures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdventuresTableOrderingComposer(
            $db: $db,
            $table: $db.adventures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NuzlockeEncountersTableAnnotationComposer
    extends Composer<_$UserDatabase, $NuzlockeEncountersTable> {
  $$NuzlockeEncountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get locationAreaId => $composableBuilder(
    column: $table.locationAreaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationLabel => $composableBuilder(
    column: $table.locationLabel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get speciesId =>
      $composableBuilder(column: $table.speciesId, builder: (column) => column);

  GeneratedColumn<String> get specimenId => $composableBuilder(
    column: $table.specimenId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AdventuresTableAnnotationComposer get adventureId {
    final $$AdventuresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adventureId,
      referencedTable: $db.adventures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdventuresTableAnnotationComposer(
            $db: $db,
            $table: $db.adventures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NuzlockeEncountersTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $NuzlockeEncountersTable,
          NuzlockeEncounter,
          $$NuzlockeEncountersTableFilterComposer,
          $$NuzlockeEncountersTableOrderingComposer,
          $$NuzlockeEncountersTableAnnotationComposer,
          $$NuzlockeEncountersTableCreateCompanionBuilder,
          $$NuzlockeEncountersTableUpdateCompanionBuilder,
          (NuzlockeEncounter, $$NuzlockeEncountersTableReferences),
          NuzlockeEncounter,
          PrefetchHooks Function({bool adventureId})
        > {
  $$NuzlockeEncountersTableTableManager(
    _$UserDatabase db,
    $NuzlockeEncountersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NuzlockeEncountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NuzlockeEncountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NuzlockeEncountersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> adventureId = const Value.absent(),
                Value<int?> locationAreaId = const Value.absent(),
                Value<String> locationLabel = const Value.absent(),
                Value<int?> speciesId = const Value.absent(),
                Value<String?> specimenId = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NuzlockeEncountersCompanion(
                id: id,
                adventureId: adventureId,
                locationAreaId: locationAreaId,
                locationLabel: locationLabel,
                speciesId: speciesId,
                specimenId: specimenId,
                outcome: outcome,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String adventureId,
                Value<int?> locationAreaId = const Value.absent(),
                required String locationLabel,
                Value<int?> speciesId = const Value.absent(),
                Value<String?> specimenId = const Value.absent(),
                required String outcome,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => NuzlockeEncountersCompanion.insert(
                id: id,
                adventureId: adventureId,
                locationAreaId: locationAreaId,
                locationLabel: locationLabel,
                speciesId: speciesId,
                specimenId: specimenId,
                outcome: outcome,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NuzlockeEncountersTable, NuzlockeEncounter>(
                    table,
                  ),
                  $$NuzlockeEncountersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({adventureId = false}) {
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
                    if (adventureId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.adventureId,
                        referencedTable: $$NuzlockeEncountersTableReferences
                            ._adventureIdTable(db),
                        referencedColumn: $$NuzlockeEncountersTableReferences
                            ._adventureIdTable(db)
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

typedef $$NuzlockeEncountersTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $NuzlockeEncountersTable,
      NuzlockeEncounter,
      $$NuzlockeEncountersTableFilterComposer,
      $$NuzlockeEncountersTableOrderingComposer,
      $$NuzlockeEncountersTableAnnotationComposer,
      $$NuzlockeEncountersTableCreateCompanionBuilder,
      $$NuzlockeEncountersTableUpdateCompanionBuilder,
      (NuzlockeEncounter, $$NuzlockeEncountersTableReferences),
      NuzlockeEncounter,
      PrefetchHooks Function({bool adventureId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$UserDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$UserDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$UserDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$UserDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$UserDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$UserDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$UserDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $UserDatabaseManager {
  final _$UserDatabase _db;
  $UserDatabaseManager(this._db);
  $$AdventuresTableTableManager get adventures =>
      $$AdventuresTableTableManager(_db, _db.adventures);
  $$SpecimensTableTableManager get specimens =>
      $$SpecimensTableTableManager(_db, _db.specimens);
  $$SpeciesMarksTableTableManager get speciesMarks =>
      $$SpeciesMarksTableTableManager(_db, _db.speciesMarks);
  $$CustomListsTableTableManager get customLists =>
      $$CustomListsTableTableManager(_db, _db.customLists);
  $$CustomListItemsTableTableManager get customListItems =>
      $$CustomListItemsTableTableManager(_db, _db.customListItems);
  $$NuzlockeEncountersTableTableManager get nuzlockeEncounters =>
      $$NuzlockeEncountersTableTableManager(_db, _db.nuzlockeEncounters);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
