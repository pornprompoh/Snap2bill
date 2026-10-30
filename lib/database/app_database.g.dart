// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedBillsTable extends CachedBills
    with TableInfo<$CachedBillsTable, CachedBill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedBillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopNameMeta = const VerificationMeta(
    'shopName',
  );
  @override
  late final GeneratedColumn<String> shopName = GeneratedColumn<String>(
    'shop_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _receiptDateMeta = const VerificationMeta(
    'receiptDate',
  );
  @override
  late final GeneratedColumn<String> receiptDate = GeneratedColumn<String>(
    'receipt_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _receiptJsonMeta = const VerificationMeta(
    'receiptJson',
  );
  @override
  late final GeneratedColumn<String> receiptJson = GeneratedColumn<String>(
    'receipt_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sharersJsonMeta = const VerificationMeta(
    'sharersJson',
  );
  @override
  late final GeneratedColumn<String> sharersJson = GeneratedColumn<String>(
    'sharers_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopName,
    totalAmount,
    receiptDate,
    status,
    receiptJson,
    sharersJson,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_bills';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedBill> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_name')) {
      context.handle(
        _shopNameMeta,
        shopName.isAcceptableOrUnknown(data['shop_name']!, _shopNameMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('receipt_date')) {
      context.handle(
        _receiptDateMeta,
        receiptDate.isAcceptableOrUnknown(
          data['receipt_date']!,
          _receiptDateMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('receipt_json')) {
      context.handle(
        _receiptJsonMeta,
        receiptJson.isAcceptableOrUnknown(
          data['receipt_json']!,
          _receiptJsonMeta,
        ),
      );
    }
    if (data.containsKey('sharers_json')) {
      context.handle(
        _sharersJsonMeta,
        sharersJson.isAcceptableOrUnknown(
          data['sharers_json']!,
          _sharersJsonMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedBill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedBill(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_name'],
      ),
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      receiptDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_date'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      receiptJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_json'],
      ),
      sharersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sharers_json'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedBillsTable createAlias(String alias) {
    return $CachedBillsTable(attachedDatabase, alias);
  }
}

class CachedBill extends DataClass implements Insertable<CachedBill> {
  final String id;
  final String? shopName;
  final double totalAmount;
  final String? receiptDate;
  final String status;
  final String? receiptJson;
  final String? sharersJson;
  final DateTime cachedAt;
  const CachedBill({
    required this.id,
    this.shopName,
    required this.totalAmount,
    this.receiptDate,
    required this.status,
    this.receiptJson,
    this.sharersJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || shopName != null) {
      map['shop_name'] = Variable<String>(shopName);
    }
    map['total_amount'] = Variable<double>(totalAmount);
    if (!nullToAbsent || receiptDate != null) {
      map['receipt_date'] = Variable<String>(receiptDate);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || receiptJson != null) {
      map['receipt_json'] = Variable<String>(receiptJson);
    }
    if (!nullToAbsent || sharersJson != null) {
      map['sharers_json'] = Variable<String>(sharersJson);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedBillsCompanion toCompanion(bool nullToAbsent) {
    return CachedBillsCompanion(
      id: Value(id),
      shopName: shopName == null && nullToAbsent
          ? const Value.absent()
          : Value(shopName),
      totalAmount: Value(totalAmount),
      receiptDate: receiptDate == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptDate),
      status: Value(status),
      receiptJson: receiptJson == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptJson),
      sharersJson: sharersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(sharersJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedBill.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedBill(
      id: serializer.fromJson<String>(json['id']),
      shopName: serializer.fromJson<String?>(json['shopName']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      receiptDate: serializer.fromJson<String?>(json['receiptDate']),
      status: serializer.fromJson<String>(json['status']),
      receiptJson: serializer.fromJson<String?>(json['receiptJson']),
      sharersJson: serializer.fromJson<String?>(json['sharersJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopName': serializer.toJson<String?>(shopName),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'receiptDate': serializer.toJson<String?>(receiptDate),
      'status': serializer.toJson<String>(status),
      'receiptJson': serializer.toJson<String?>(receiptJson),
      'sharersJson': serializer.toJson<String?>(sharersJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedBill copyWith({
    String? id,
    Value<String?> shopName = const Value.absent(),
    double? totalAmount,
    Value<String?> receiptDate = const Value.absent(),
    String? status,
    Value<String?> receiptJson = const Value.absent(),
    Value<String?> sharersJson = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedBill(
    id: id ?? this.id,
    shopName: shopName.present ? shopName.value : this.shopName,
    totalAmount: totalAmount ?? this.totalAmount,
    receiptDate: receiptDate.present ? receiptDate.value : this.receiptDate,
    status: status ?? this.status,
    receiptJson: receiptJson.present ? receiptJson.value : this.receiptJson,
    sharersJson: sharersJson.present ? sharersJson.value : this.sharersJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedBill copyWithCompanion(CachedBillsCompanion data) {
    return CachedBill(
      id: data.id.present ? data.id.value : this.id,
      shopName: data.shopName.present ? data.shopName.value : this.shopName,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      receiptDate: data.receiptDate.present
          ? data.receiptDate.value
          : this.receiptDate,
      status: data.status.present ? data.status.value : this.status,
      receiptJson: data.receiptJson.present
          ? data.receiptJson.value
          : this.receiptJson,
      sharersJson: data.sharersJson.present
          ? data.sharersJson.value
          : this.sharersJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedBill(')
          ..write('id: $id, ')
          ..write('shopName: $shopName, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('receiptDate: $receiptDate, ')
          ..write('status: $status, ')
          ..write('receiptJson: $receiptJson, ')
          ..write('sharersJson: $sharersJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shopName,
    totalAmount,
    receiptDate,
    status,
    receiptJson,
    sharersJson,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedBill &&
          other.id == this.id &&
          other.shopName == this.shopName &&
          other.totalAmount == this.totalAmount &&
          other.receiptDate == this.receiptDate &&
          other.status == this.status &&
          other.receiptJson == this.receiptJson &&
          other.sharersJson == this.sharersJson &&
          other.cachedAt == this.cachedAt);
}

class CachedBillsCompanion extends UpdateCompanion<CachedBill> {
  final Value<String> id;
  final Value<String?> shopName;
  final Value<double> totalAmount;
  final Value<String?> receiptDate;
  final Value<String> status;
  final Value<String?> receiptJson;
  final Value<String?> sharersJson;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedBillsCompanion({
    this.id = const Value.absent(),
    this.shopName = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.receiptDate = const Value.absent(),
    this.status = const Value.absent(),
    this.receiptJson = const Value.absent(),
    this.sharersJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedBillsCompanion.insert({
    required String id,
    this.shopName = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.receiptDate = const Value.absent(),
    this.status = const Value.absent(),
    this.receiptJson = const Value.absent(),
    this.sharersJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<CachedBill> custom({
    Expression<String>? id,
    Expression<String>? shopName,
    Expression<double>? totalAmount,
    Expression<String>? receiptDate,
    Expression<String>? status,
    Expression<String>? receiptJson,
    Expression<String>? sharersJson,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopName != null) 'shop_name': shopName,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (receiptDate != null) 'receipt_date': receiptDate,
      if (status != null) 'status': status,
      if (receiptJson != null) 'receipt_json': receiptJson,
      if (sharersJson != null) 'sharers_json': sharersJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedBillsCompanion copyWith({
    Value<String>? id,
    Value<String?>? shopName,
    Value<double>? totalAmount,
    Value<String?>? receiptDate,
    Value<String>? status,
    Value<String?>? receiptJson,
    Value<String?>? sharersJson,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedBillsCompanion(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      totalAmount: totalAmount ?? this.totalAmount,
      receiptDate: receiptDate ?? this.receiptDate,
      status: status ?? this.status,
      receiptJson: receiptJson ?? this.receiptJson,
      sharersJson: sharersJson ?? this.sharersJson,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopName.present) {
      map['shop_name'] = Variable<String>(shopName.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (receiptDate.present) {
      map['receipt_date'] = Variable<String>(receiptDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (receiptJson.present) {
      map['receipt_json'] = Variable<String>(receiptJson.value);
    }
    if (sharersJson.present) {
      map['sharers_json'] = Variable<String>(sharersJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedBillsCompanion(')
          ..write('id: $id, ')
          ..write('shopName: $shopName, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('receiptDate: $receiptDate, ')
          ..write('status: $status, ')
          ..write('receiptJson: $receiptJson, ')
          ..write('sharersJson: $sharersJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineDraftsTable extends OfflineDrafts
    with TableInfo<$OfflineDraftsTable, OfflineDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _shopNameMeta = const VerificationMeta(
    'shopName',
  );
  @override
  late final GeneratedColumn<String> shopName = GeneratedColumn<String>(
    'shop_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopName,
    totalAmount,
    itemsJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineDraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shop_name')) {
      context.handle(
        _shopNameMeta,
        shopName.isAcceptableOrUnknown(data['shop_name']!, _shopNameMeta),
      );
    } else if (isInserting) {
      context.missing(_shopNameMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_itemsJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineDraft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      shopName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_name'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OfflineDraftsTable createAlias(String alias) {
    return $OfflineDraftsTable(attachedDatabase, alias);
  }
}

class OfflineDraft extends DataClass implements Insertable<OfflineDraft> {
  final int id;
  final String shopName;
  final double totalAmount;
  final String itemsJson;
  final DateTime createdAt;
  const OfflineDraft({
    required this.id,
    required this.shopName,
    required this.totalAmount,
    required this.itemsJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['shop_name'] = Variable<String>(shopName);
    map['total_amount'] = Variable<double>(totalAmount);
    map['items_json'] = Variable<String>(itemsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OfflineDraftsCompanion toCompanion(bool nullToAbsent) {
    return OfflineDraftsCompanion(
      id: Value(id),
      shopName: Value(shopName),
      totalAmount: Value(totalAmount),
      itemsJson: Value(itemsJson),
      createdAt: Value(createdAt),
    );
  }

  factory OfflineDraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineDraft(
      id: serializer.fromJson<int>(json['id']),
      shopName: serializer.fromJson<String>(json['shopName']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shopName': serializer.toJson<String>(shopName),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OfflineDraft copyWith({
    int? id,
    String? shopName,
    double? totalAmount,
    String? itemsJson,
    DateTime? createdAt,
  }) => OfflineDraft(
    id: id ?? this.id,
    shopName: shopName ?? this.shopName,
    totalAmount: totalAmount ?? this.totalAmount,
    itemsJson: itemsJson ?? this.itemsJson,
    createdAt: createdAt ?? this.createdAt,
  );
  OfflineDraft copyWithCompanion(OfflineDraftsCompanion data) {
    return OfflineDraft(
      id: data.id.present ? data.id.value : this.id,
      shopName: data.shopName.present ? data.shopName.value : this.shopName,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineDraft(')
          ..write('id: $id, ')
          ..write('shopName: $shopName, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, shopName, totalAmount, itemsJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineDraft &&
          other.id == this.id &&
          other.shopName == this.shopName &&
          other.totalAmount == this.totalAmount &&
          other.itemsJson == this.itemsJson &&
          other.createdAt == this.createdAt);
}

class OfflineDraftsCompanion extends UpdateCompanion<OfflineDraft> {
  final Value<int> id;
  final Value<String> shopName;
  final Value<double> totalAmount;
  final Value<String> itemsJson;
  final Value<DateTime> createdAt;
  const OfflineDraftsCompanion({
    this.id = const Value.absent(),
    this.shopName = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OfflineDraftsCompanion.insert({
    this.id = const Value.absent(),
    required String shopName,
    required double totalAmount,
    required String itemsJson,
    this.createdAt = const Value.absent(),
  }) : shopName = Value(shopName),
       totalAmount = Value(totalAmount),
       itemsJson = Value(itemsJson);
  static Insertable<OfflineDraft> custom({
    Expression<int>? id,
    Expression<String>? shopName,
    Expression<double>? totalAmount,
    Expression<String>? itemsJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopName != null) 'shop_name': shopName,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (itemsJson != null) 'items_json': itemsJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OfflineDraftsCompanion copyWith({
    Value<int>? id,
    Value<String>? shopName,
    Value<double>? totalAmount,
    Value<String>? itemsJson,
    Value<DateTime>? createdAt,
  }) {
    return OfflineDraftsCompanion(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      totalAmount: totalAmount ?? this.totalAmount,
      itemsJson: itemsJson ?? this.itemsJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shopName.present) {
      map['shop_name'] = Variable<String>(shopName.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineDraftsCompanion(')
          ..write('id: $id, ')
          ..write('shopName: $shopName, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BillsTable extends Bills with TableInfo<$BillsTable, Bill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatMeta = const VerificationMeta('vat');
  @override
  late final GeneratedColumn<double> vat = GeneratedColumn<double>(
    'vat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _serviceChargeMeta = const VerificationMeta(
    'serviceCharge',
  );
  @override
  late final GeneratedColumn<double> serviceCharge = GeneratedColumn<double>(
    'service_charge',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _hostIdMeta = const VerificationMeta('hostId');
  @override
  late final GeneratedColumn<String> hostId = GeneratedColumn<String>(
    'host_id',
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
  static const VerificationMeta _syncedWithServerMeta = const VerificationMeta(
    'syncedWithServer',
  );
  @override
  late final GeneratedColumn<bool> syncedWithServer = GeneratedColumn<bool>(
    'synced_with_server',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced_with_server" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    totalAmount,
    vat,
    serviceCharge,
    hostId,
    createdAt,
    syncedWithServer,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bills';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bill> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('vat')) {
      context.handle(
        _vatMeta,
        vat.isAcceptableOrUnknown(data['vat']!, _vatMeta),
      );
    }
    if (data.containsKey('service_charge')) {
      context.handle(
        _serviceChargeMeta,
        serviceCharge.isAcceptableOrUnknown(
          data['service_charge']!,
          _serviceChargeMeta,
        ),
      );
    }
    if (data.containsKey('host_id')) {
      context.handle(
        _hostIdMeta,
        hostId.isAcceptableOrUnknown(data['host_id']!, _hostIdMeta),
      );
    } else if (isInserting) {
      context.missing(_hostIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_with_server')) {
      context.handle(
        _syncedWithServerMeta,
        syncedWithServer.isAcceptableOrUnknown(
          data['synced_with_server']!,
          _syncedWithServerMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bill(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      vat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vat'],
      )!,
      serviceCharge: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}service_charge'],
      )!,
      hostId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedWithServer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced_with_server'],
      )!,
    );
  }

  @override
  $BillsTable createAlias(String alias) {
    return $BillsTable(attachedDatabase, alias);
  }
}

class Bill extends DataClass implements Insertable<Bill> {
  final String id;
  final String title;
  final double totalAmount;
  final double vat;
  final double serviceCharge;
  final String hostId;
  final DateTime createdAt;
  final bool syncedWithServer;
  const Bill({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.vat,
    required this.serviceCharge,
    required this.hostId,
    required this.createdAt,
    required this.syncedWithServer,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['total_amount'] = Variable<double>(totalAmount);
    map['vat'] = Variable<double>(vat);
    map['service_charge'] = Variable<double>(serviceCharge);
    map['host_id'] = Variable<String>(hostId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced_with_server'] = Variable<bool>(syncedWithServer);
    return map;
  }

  BillsCompanion toCompanion(bool nullToAbsent) {
    return BillsCompanion(
      id: Value(id),
      title: Value(title),
      totalAmount: Value(totalAmount),
      vat: Value(vat),
      serviceCharge: Value(serviceCharge),
      hostId: Value(hostId),
      createdAt: Value(createdAt),
      syncedWithServer: Value(syncedWithServer),
    );
  }

  factory Bill.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bill(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      vat: serializer.fromJson<double>(json['vat']),
      serviceCharge: serializer.fromJson<double>(json['serviceCharge']),
      hostId: serializer.fromJson<String>(json['hostId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedWithServer: serializer.fromJson<bool>(json['syncedWithServer']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'vat': serializer.toJson<double>(vat),
      'serviceCharge': serializer.toJson<double>(serviceCharge),
      'hostId': serializer.toJson<String>(hostId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedWithServer': serializer.toJson<bool>(syncedWithServer),
    };
  }

  Bill copyWith({
    String? id,
    String? title,
    double? totalAmount,
    double? vat,
    double? serviceCharge,
    String? hostId,
    DateTime? createdAt,
    bool? syncedWithServer,
  }) => Bill(
    id: id ?? this.id,
    title: title ?? this.title,
    totalAmount: totalAmount ?? this.totalAmount,
    vat: vat ?? this.vat,
    serviceCharge: serviceCharge ?? this.serviceCharge,
    hostId: hostId ?? this.hostId,
    createdAt: createdAt ?? this.createdAt,
    syncedWithServer: syncedWithServer ?? this.syncedWithServer,
  );
  Bill copyWithCompanion(BillsCompanion data) {
    return Bill(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      vat: data.vat.present ? data.vat.value : this.vat,
      serviceCharge: data.serviceCharge.present
          ? data.serviceCharge.value
          : this.serviceCharge,
      hostId: data.hostId.present ? data.hostId.value : this.hostId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedWithServer: data.syncedWithServer.present
          ? data.syncedWithServer.value
          : this.syncedWithServer,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bill(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('vat: $vat, ')
          ..write('serviceCharge: $serviceCharge, ')
          ..write('hostId: $hostId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedWithServer: $syncedWithServer')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    totalAmount,
    vat,
    serviceCharge,
    hostId,
    createdAt,
    syncedWithServer,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bill &&
          other.id == this.id &&
          other.title == this.title &&
          other.totalAmount == this.totalAmount &&
          other.vat == this.vat &&
          other.serviceCharge == this.serviceCharge &&
          other.hostId == this.hostId &&
          other.createdAt == this.createdAt &&
          other.syncedWithServer == this.syncedWithServer);
}

class BillsCompanion extends UpdateCompanion<Bill> {
  final Value<String> id;
  final Value<String> title;
  final Value<double> totalAmount;
  final Value<double> vat;
  final Value<double> serviceCharge;
  final Value<String> hostId;
  final Value<DateTime> createdAt;
  final Value<bool> syncedWithServer;
  final Value<int> rowid;
  const BillsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.vat = const Value.absent(),
    this.serviceCharge = const Value.absent(),
    this.hostId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedWithServer = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillsCompanion.insert({
    required String id,
    required String title,
    required double totalAmount,
    this.vat = const Value.absent(),
    this.serviceCharge = const Value.absent(),
    required String hostId,
    required DateTime createdAt,
    this.syncedWithServer = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       totalAmount = Value(totalAmount),
       hostId = Value(hostId),
       createdAt = Value(createdAt);
  static Insertable<Bill> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<double>? totalAmount,
    Expression<double>? vat,
    Expression<double>? serviceCharge,
    Expression<String>? hostId,
    Expression<DateTime>? createdAt,
    Expression<bool>? syncedWithServer,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (vat != null) 'vat': vat,
      if (serviceCharge != null) 'service_charge': serviceCharge,
      if (hostId != null) 'host_id': hostId,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedWithServer != null) 'synced_with_server': syncedWithServer,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<double>? totalAmount,
    Value<double>? vat,
    Value<double>? serviceCharge,
    Value<String>? hostId,
    Value<DateTime>? createdAt,
    Value<bool>? syncedWithServer,
    Value<int>? rowid,
  }) {
    return BillsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      vat: vat ?? this.vat,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      hostId: hostId ?? this.hostId,
      createdAt: createdAt ?? this.createdAt,
      syncedWithServer: syncedWithServer ?? this.syncedWithServer,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (vat.present) {
      map['vat'] = Variable<double>(vat.value);
    }
    if (serviceCharge.present) {
      map['service_charge'] = Variable<double>(serviceCharge.value);
    }
    if (hostId.present) {
      map['host_id'] = Variable<String>(hostId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedWithServer.present) {
      map['synced_with_server'] = Variable<bool>(syncedWithServer.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('vat: $vat, ')
          ..write('serviceCharge: $serviceCharge, ')
          ..write('hostId: $hostId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedWithServer: $syncedWithServer, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillItemsTable extends BillItems
    with TableInfo<$BillItemsTable, BillItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bills (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, billId, name, price, quantity];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bill_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<BillItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    } else if (isInserting) {
      context.missing(_billIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BillItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
    );
  }

  @override
  $BillItemsTable createAlias(String alias) {
    return $BillItemsTable(attachedDatabase, alias);
  }
}

class BillItem extends DataClass implements Insertable<BillItem> {
  final String id;
  final String billId;
  final String name;
  final double price;
  final int quantity;
  const BillItem({
    required this.id,
    required this.billId,
    required this.name,
    required this.price,
    required this.quantity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bill_id'] = Variable<String>(billId);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<double>(price);
    map['quantity'] = Variable<int>(quantity);
    return map;
  }

  BillItemsCompanion toCompanion(bool nullToAbsent) {
    return BillItemsCompanion(
      id: Value(id),
      billId: Value(billId),
      name: Value(name),
      price: Value(price),
      quantity: Value(quantity),
    );
  }

  factory BillItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillItem(
      id: serializer.fromJson<String>(json['id']),
      billId: serializer.fromJson<String>(json['billId']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<double>(json['price']),
      quantity: serializer.fromJson<int>(json['quantity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'billId': serializer.toJson<String>(billId),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<double>(price),
      'quantity': serializer.toJson<int>(quantity),
    };
  }

  BillItem copyWith({
    String? id,
    String? billId,
    String? name,
    double? price,
    int? quantity,
  }) => BillItem(
    id: id ?? this.id,
    billId: billId ?? this.billId,
    name: name ?? this.name,
    price: price ?? this.price,
    quantity: quantity ?? this.quantity,
  );
  BillItem copyWithCompanion(BillItemsCompanion data) {
    return BillItem(
      id: data.id.present ? data.id.value : this.id,
      billId: data.billId.present ? data.billId.value : this.billId,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillItem(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('quantity: $quantity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, billId, name, price, quantity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillItem &&
          other.id == this.id &&
          other.billId == this.billId &&
          other.name == this.name &&
          other.price == this.price &&
          other.quantity == this.quantity);
}

class BillItemsCompanion extends UpdateCompanion<BillItem> {
  final Value<String> id;
  final Value<String> billId;
  final Value<String> name;
  final Value<double> price;
  final Value<int> quantity;
  final Value<int> rowid;
  const BillItemsCompanion({
    this.id = const Value.absent(),
    this.billId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.quantity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillItemsCompanion.insert({
    required String id,
    required String billId,
    required String name,
    required double price,
    required int quantity,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       billId = Value(billId),
       name = Value(name),
       price = Value(price),
       quantity = Value(quantity);
  static Insertable<BillItem> custom({
    Expression<String>? id,
    Expression<String>? billId,
    Expression<String>? name,
    Expression<double>? price,
    Expression<int>? quantity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (quantity != null) 'quantity': quantity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? billId,
    Value<String>? name,
    Value<double>? price,
    Value<int>? quantity,
    Value<int>? rowid,
  }) {
    return BillItemsCompanion(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillItemsCompanion(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('quantity: $quantity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemClaimsTable extends ItemClaims
    with TableInfo<$ItemClaimsTable, ItemClaim> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemClaimsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
      'REFERENCES bill_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _claimedQuantityMeta = const VerificationMeta(
    'claimedQuantity',
  );
  @override
  late final GeneratedColumn<int> claimedQuantity = GeneratedColumn<int>(
    'claimed_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSharedMeta = const VerificationMeta(
    'isShared',
  );
  @override
  late final GeneratedColumn<bool> isShared = GeneratedColumn<bool>(
    'is_shared',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_shared" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    userId,
    claimedQuantity,
    isShared,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_claims';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemClaim> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('claimed_quantity')) {
      context.handle(
        _claimedQuantityMeta,
        claimedQuantity.isAcceptableOrUnknown(
          data['claimed_quantity']!,
          _claimedQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_claimedQuantityMeta);
    }
    if (data.containsKey('is_shared')) {
      context.handle(
        _isSharedMeta,
        isShared.isAcceptableOrUnknown(data['is_shared']!, _isSharedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemClaim map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemClaim(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      claimedQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}claimed_quantity'],
      )!,
      isShared: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_shared'],
      )!,
    );
  }

  @override
  $ItemClaimsTable createAlias(String alias) {
    return $ItemClaimsTable(attachedDatabase, alias);
  }
}

class ItemClaim extends DataClass implements Insertable<ItemClaim> {
  final String id;
  final String itemId;
  final String userId;
  final int claimedQuantity;
  final bool isShared;
  const ItemClaim({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.claimedQuantity,
    required this.isShared,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['user_id'] = Variable<String>(userId);
    map['claimed_quantity'] = Variable<int>(claimedQuantity);
    map['is_shared'] = Variable<bool>(isShared);
    return map;
  }

  ItemClaimsCompanion toCompanion(bool nullToAbsent) {
    return ItemClaimsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      userId: Value(userId),
      claimedQuantity: Value(claimedQuantity),
      isShared: Value(isShared),
    );
  }

  factory ItemClaim.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemClaim(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      userId: serializer.fromJson<String>(json['userId']),
      claimedQuantity: serializer.fromJson<int>(json['claimedQuantity']),
      isShared: serializer.fromJson<bool>(json['isShared']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'userId': serializer.toJson<String>(userId),
      'claimedQuantity': serializer.toJson<int>(claimedQuantity),
      'isShared': serializer.toJson<bool>(isShared),
    };
  }

  ItemClaim copyWith({
    String? id,
    String? itemId,
    String? userId,
    int? claimedQuantity,
    bool? isShared,
  }) => ItemClaim(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    userId: userId ?? this.userId,
    claimedQuantity: claimedQuantity ?? this.claimedQuantity,
    isShared: isShared ?? this.isShared,
  );
  ItemClaim copyWithCompanion(ItemClaimsCompanion data) {
    return ItemClaim(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      userId: data.userId.present ? data.userId.value : this.userId,
      claimedQuantity: data.claimedQuantity.present
          ? data.claimedQuantity.value
          : this.claimedQuantity,
      isShared: data.isShared.present ? data.isShared.value : this.isShared,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemClaim(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('userId: $userId, ')
          ..write('claimedQuantity: $claimedQuantity, ')
          ..write('isShared: $isShared')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, itemId, userId, claimedQuantity, isShared);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemClaim &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.userId == this.userId &&
          other.claimedQuantity == this.claimedQuantity &&
          other.isShared == this.isShared);
}

class ItemClaimsCompanion extends UpdateCompanion<ItemClaim> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> userId;
  final Value<int> claimedQuantity;
  final Value<bool> isShared;
  final Value<int> rowid;
  const ItemClaimsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.userId = const Value.absent(),
    this.claimedQuantity = const Value.absent(),
    this.isShared = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemClaimsCompanion.insert({
    required String id,
    required String itemId,
    required String userId,
    required int claimedQuantity,
    this.isShared = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       userId = Value(userId),
       claimedQuantity = Value(claimedQuantity);
  static Insertable<ItemClaim> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? userId,
    Expression<int>? claimedQuantity,
    Expression<bool>? isShared,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (userId != null) 'user_id': userId,
      if (claimedQuantity != null) 'claimed_quantity': claimedQuantity,
      if (isShared != null) 'is_shared': isShared,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemClaimsCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String>? userId,
    Value<int>? claimedQuantity,
    Value<bool>? isShared,
    Value<int>? rowid,
  }) {
    return ItemClaimsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      claimedQuantity: claimedQuantity ?? this.claimedQuantity,
      isShared: isShared ?? this.isShared,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (claimedQuantity.present) {
      map['claimed_quantity'] = Variable<int>(claimedQuantity.value);
    }
    if (isShared.present) {
      map['is_shared'] = Variable<bool>(isShared.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemClaimsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('userId: $userId, ')
          ..write('claimedQuantity: $claimedQuantity, ')
          ..write('isShared: $isShared, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedBillsTable cachedBills = $CachedBillsTable(this);
  late final $OfflineDraftsTable offlineDrafts = $OfflineDraftsTable(this);
  late final $BillsTable bills = $BillsTable(this);
  late final $BillItemsTable billItems = $BillItemsTable(this);
  late final $ItemClaimsTable itemClaims = $ItemClaimsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedBills,
    offlineDrafts,
    bills,
    billItems,
    itemClaims,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'bills',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('bill_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'bill_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('item_claims', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CachedBillsTableCreateCompanionBuilder =
    CachedBillsCompanion Function({
      required String id,
      Value<String?> shopName,
      Value<double> totalAmount,
      Value<String?> receiptDate,
      Value<String> status,
      Value<String?> receiptJson,
      Value<String?> sharersJson,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$CachedBillsTableUpdateCompanionBuilder =
    CachedBillsCompanion Function({
      Value<String> id,
      Value<String?> shopName,
      Value<double> totalAmount,
      Value<String?> receiptDate,
      Value<String> status,
      Value<String?> receiptJson,
      Value<String?> sharersJson,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedBillsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedBillsTable> {
  $$CachedBillsTableFilterComposer({
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

  ColumnFilters<String> get shopName => $composableBuilder(
    column: $table.shopName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptDate => $composableBuilder(
    column: $table.receiptDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptJson => $composableBuilder(
    column: $table.receiptJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharersJson => $composableBuilder(
    column: $table.sharersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedBillsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedBillsTable> {
  $$CachedBillsTableOrderingComposer({
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

  ColumnOrderings<String> get shopName => $composableBuilder(
    column: $table.shopName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptDate => $composableBuilder(
    column: $table.receiptDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptJson => $composableBuilder(
    column: $table.receiptJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharersJson => $composableBuilder(
    column: $table.sharersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedBillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedBillsTable> {
  $$CachedBillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopName =>
      $composableBuilder(column: $table.shopName, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptDate => $composableBuilder(
    column: $table.receiptDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get receiptJson => $composableBuilder(
    column: $table.receiptJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sharersJson => $composableBuilder(
    column: $table.sharersJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedBillsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedBillsTable,
          CachedBill,
          $$CachedBillsTableFilterComposer,
          $$CachedBillsTableOrderingComposer,
          $$CachedBillsTableAnnotationComposer,
          $$CachedBillsTableCreateCompanionBuilder,
          $$CachedBillsTableUpdateCompanionBuilder,
          (
            CachedBill,
            BaseReferences<_$AppDatabase, $CachedBillsTable, CachedBill>,
          ),
          CachedBill,
          PrefetchHooks Function()
        > {
  $$CachedBillsTableTableManager(_$AppDatabase db, $CachedBillsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedBillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedBillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedBillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> shopName = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String?> receiptDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> receiptJson = const Value.absent(),
                Value<String?> sharersJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedBillsCompanion(
                id: id,
                shopName: shopName,
                totalAmount: totalAmount,
                receiptDate: receiptDate,
                status: status,
                receiptJson: receiptJson,
                sharersJson: sharersJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> shopName = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String?> receiptDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> receiptJson = const Value.absent(),
                Value<String?> sharersJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedBillsCompanion.insert(
                id: id,
                shopName: shopName,
                totalAmount: totalAmount,
                receiptDate: receiptDate,
                status: status,
                receiptJson: receiptJson,
                sharersJson: sharersJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedBillsTable, CachedBill>(table),
                  BaseReferences<_$AppDatabase, $CachedBillsTable, CachedBill>(
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

typedef $$CachedBillsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedBillsTable,
      CachedBill,
      $$CachedBillsTableFilterComposer,
      $$CachedBillsTableOrderingComposer,
      $$CachedBillsTableAnnotationComposer,
      $$CachedBillsTableCreateCompanionBuilder,
      $$CachedBillsTableUpdateCompanionBuilder,
      (
        CachedBill,
        BaseReferences<_$AppDatabase, $CachedBillsTable, CachedBill>,
      ),
      CachedBill,
      PrefetchHooks Function()
    >;
typedef $$OfflineDraftsTableCreateCompanionBuilder =
    OfflineDraftsCompanion Function({
      Value<int> id,
      required String shopName,
      required double totalAmount,
      required String itemsJson,
      Value<DateTime> createdAt,
    });
typedef $$OfflineDraftsTableUpdateCompanionBuilder =
    OfflineDraftsCompanion Function({
      Value<int> id,
      Value<String> shopName,
      Value<double> totalAmount,
      Value<String> itemsJson,
      Value<DateTime> createdAt,
    });

class $$OfflineDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineDraftsTable> {
  $$OfflineDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopName => $composableBuilder(
    column: $table.shopName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineDraftsTable> {
  $$OfflineDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopName => $composableBuilder(
    column: $table.shopName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineDraftsTable> {
  $$OfflineDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopName =>
      $composableBuilder(column: $table.shopName, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OfflineDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineDraftsTable,
          OfflineDraft,
          $$OfflineDraftsTableFilterComposer,
          $$OfflineDraftsTableOrderingComposer,
          $$OfflineDraftsTableAnnotationComposer,
          $$OfflineDraftsTableCreateCompanionBuilder,
          $$OfflineDraftsTableUpdateCompanionBuilder,
          (
            OfflineDraft,
            BaseReferences<_$AppDatabase, $OfflineDraftsTable, OfflineDraft>,
          ),
          OfflineDraft,
          PrefetchHooks Function()
        > {
  $$OfflineDraftsTableTableManager(_$AppDatabase db, $OfflineDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> shopName = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OfflineDraftsCompanion(
                id: id,
                shopName: shopName,
                totalAmount: totalAmount,
                itemsJson: itemsJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String shopName,
                required double totalAmount,
                required String itemsJson,
                Value<DateTime> createdAt = const Value.absent(),
              }) => OfflineDraftsCompanion.insert(
                id: id,
                shopName: shopName,
                totalAmount: totalAmount,
                itemsJson: itemsJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OfflineDraftsTable, OfflineDraft>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $OfflineDraftsTable,
                    OfflineDraft
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineDraftsTable,
      OfflineDraft,
      $$OfflineDraftsTableFilterComposer,
      $$OfflineDraftsTableOrderingComposer,
      $$OfflineDraftsTableAnnotationComposer,
      $$OfflineDraftsTableCreateCompanionBuilder,
      $$OfflineDraftsTableUpdateCompanionBuilder,
      (
        OfflineDraft,
        BaseReferences<_$AppDatabase, $OfflineDraftsTable, OfflineDraft>,
      ),
      OfflineDraft,
      PrefetchHooks Function()
    >;
typedef $$BillsTableCreateCompanionBuilder =
    BillsCompanion Function({
      required String id,
      required String title,
      required double totalAmount,
      Value<double> vat,
      Value<double> serviceCharge,
      required String hostId,
      required DateTime createdAt,
      Value<bool> syncedWithServer,
      Value<int> rowid,
    });
typedef $$BillsTableUpdateCompanionBuilder =
    BillsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<double> totalAmount,
      Value<double> vat,
      Value<double> serviceCharge,
      Value<String> hostId,
      Value<DateTime> createdAt,
      Value<bool> syncedWithServer,
      Value<int> rowid,
    });

final class $$BillsTableReferences
    extends BaseReferences<_$AppDatabase, $BillsTable, Bill> {
  $$BillsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BillItemsTable, List<BillItem>>
  _billItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.billItems,
    aliasName: 'bills__id__bill_items__bill_id',
  );

  $$BillItemsTableProcessedTableManager get billItemsRefs {
    final manager = $$BillItemsTableTableManager(
      $_db,
      $_db.billItems,
    ).filter((f) => f.billId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_billItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BillsTableFilterComposer extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vat => $composableBuilder(
    column: $table.vat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get serviceCharge => $composableBuilder(
    column: $table.serviceCharge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hostId => $composableBuilder(
    column: $table.hostId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncedWithServer => $composableBuilder(
    column: $table.syncedWithServer,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> billItemsRefs(
    Expression<bool> Function($$BillItemsTableFilterComposer f) f,
  ) {
    final $$BillItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billItems,
      getReferencedColumn: (t) => t.billId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillItemsTableFilterComposer(
            $db: $db,
            $table: $db.billItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BillsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vat => $composableBuilder(
    column: $table.vat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get serviceCharge => $composableBuilder(
    column: $table.serviceCharge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hostId => $composableBuilder(
    column: $table.hostId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncedWithServer => $composableBuilder(
    column: $table.syncedWithServer,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vat =>
      $composableBuilder(column: $table.vat, builder: (column) => column);

  GeneratedColumn<double> get serviceCharge => $composableBuilder(
    column: $table.serviceCharge,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hostId =>
      $composableBuilder(column: $table.hostId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get syncedWithServer => $composableBuilder(
    column: $table.syncedWithServer,
    builder: (column) => column,
  );

  Expression<T> billItemsRefs<T extends Object>(
    Expression<T> Function($$BillItemsTableAnnotationComposer a) f,
  ) {
    final $$BillItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billItems,
      getReferencedColumn: (t) => t.billId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.billItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BillsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BillsTable,
          Bill,
          $$BillsTableFilterComposer,
          $$BillsTableOrderingComposer,
          $$BillsTableAnnotationComposer,
          $$BillsTableCreateCompanionBuilder,
          $$BillsTableUpdateCompanionBuilder,
          (Bill, $$BillsTableReferences),
          Bill,
          PrefetchHooks Function({bool billItemsRefs})
        > {
  $$BillsTableTableManager(_$AppDatabase db, $BillsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<double> vat = const Value.absent(),
                Value<double> serviceCharge = const Value.absent(),
                Value<String> hostId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> syncedWithServer = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillsCompanion(
                id: id,
                title: title,
                totalAmount: totalAmount,
                vat: vat,
                serviceCharge: serviceCharge,
                hostId: hostId,
                createdAt: createdAt,
                syncedWithServer: syncedWithServer,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required double totalAmount,
                Value<double> vat = const Value.absent(),
                Value<double> serviceCharge = const Value.absent(),
                required String hostId,
                required DateTime createdAt,
                Value<bool> syncedWithServer = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillsCompanion.insert(
                id: id,
                title: title,
                totalAmount: totalAmount,
                vat: vat,
                serviceCharge: serviceCharge,
                hostId: hostId,
                createdAt: createdAt,
                syncedWithServer: syncedWithServer,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BillsTable, Bill>(table),
                  $$BillsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({billItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (billItemsRefs) db.billItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (billItemsRefs)
                    await $_getPrefetchedDataByColumns<
                      Bill,
                      $BillsTable,
                      BillItem,
                      $BillItemsTable
                    >(
                      currentTable: table,
                      referencedTable: $$BillsTableReferences
                          ._billItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BillsTableReferences(db, table, p0).billItemsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'bill_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BillsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BillsTable,
      Bill,
      $$BillsTableFilterComposer,
      $$BillsTableOrderingComposer,
      $$BillsTableAnnotationComposer,
      $$BillsTableCreateCompanionBuilder,
      $$BillsTableUpdateCompanionBuilder,
      (Bill, $$BillsTableReferences),
      Bill,
      PrefetchHooks Function({bool billItemsRefs})
    >;
typedef $$BillItemsTableCreateCompanionBuilder =
    BillItemsCompanion Function({
      required String id,
      required String billId,
      required String name,
      required double price,
      required int quantity,
      Value<int> rowid,
    });
typedef $$BillItemsTableUpdateCompanionBuilder =
    BillItemsCompanion Function({
      Value<String> id,
      Value<String> billId,
      Value<String> name,
      Value<double> price,
      Value<int> quantity,
      Value<int> rowid,
    });

final class $$BillItemsTableReferences
    extends BaseReferences<_$AppDatabase, $BillItemsTable, BillItem> {
  $$BillItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BillsTable _billIdTable(_$AppDatabase db) =>
      db.bills.createAlias('bill_items__bill_id__bills__id');

  $$BillsTableProcessedTableManager get billId {
    final $_column = $_itemColumn<String>('bill_id')!;

    final manager = $$BillsTableTableManager(
      $_db,
      $_db.bills,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_billIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ItemClaimsTable, List<ItemClaim>>
  _itemClaimsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemClaims,
    aliasName: 'bill_items__id__item_claims__item_id',
  );

  $$ItemClaimsTableProcessedTableManager get itemClaimsRefs {
    final manager = $$ItemClaimsTableTableManager(
      $_db,
      $_db.itemClaims,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemClaimsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BillItemsTableFilterComposer
    extends Composer<_$AppDatabase, $BillItemsTable> {
  $$BillItemsTableFilterComposer({
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

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  $$BillsTableFilterComposer get billId {
    final $$BillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableFilterComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> itemClaimsRefs(
    Expression<bool> Function($$ItemClaimsTableFilterComposer f) f,
  ) {
    final $$ItemClaimsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemClaims,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemClaimsTableFilterComposer(
            $db: $db,
            $table: $db.itemClaims,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BillItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillItemsTable> {
  $$BillItemsTableOrderingComposer({
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

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  $$BillsTableOrderingComposer get billId {
    final $$BillsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableOrderingComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillItemsTable> {
  $$BillItemsTableAnnotationComposer({
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

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  $$BillsTableAnnotationComposer get billId {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableAnnotationComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> itemClaimsRefs<T extends Object>(
    Expression<T> Function($$ItemClaimsTableAnnotationComposer a) f,
  ) {
    final $$ItemClaimsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemClaims,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemClaimsTableAnnotationComposer(
            $db: $db,
            $table: $db.itemClaims,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BillItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BillItemsTable,
          BillItem,
          $$BillItemsTableFilterComposer,
          $$BillItemsTableOrderingComposer,
          $$BillItemsTableAnnotationComposer,
          $$BillItemsTableCreateCompanionBuilder,
          $$BillItemsTableUpdateCompanionBuilder,
          (BillItem, $$BillItemsTableReferences),
          BillItem,
          PrefetchHooks Function({bool billId, bool itemClaimsRefs})
        > {
  $$BillItemsTableTableManager(_$AppDatabase db, $BillItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> billId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillItemsCompanion(
                id: id,
                billId: billId,
                name: name,
                price: price,
                quantity: quantity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String billId,
                required String name,
                required double price,
                required int quantity,
                Value<int> rowid = const Value.absent(),
              }) => BillItemsCompanion.insert(
                id: id,
                billId: billId,
                name: name,
                price: price,
                quantity: quantity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BillItemsTable, BillItem>(table),
                  $$BillItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({billId = false, itemClaimsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (itemClaimsRefs) db.itemClaims],
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
                    if (billId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.billId,
                                referencedTable: $$BillItemsTableReferences
                                    ._billIdTable(db),
                                referencedColumn: $$BillItemsTableReferences
                                    ._billIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemClaimsRefs)
                    await $_getPrefetchedDataByColumns<
                      BillItem,
                      $BillItemsTable,
                      ItemClaim,
                      $ItemClaimsTable
                    >(
                      currentTable: table,
                      referencedTable: $$BillItemsTableReferences
                          ._itemClaimsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BillItemsTableReferences(
                            db,
                            table,
                            p0,
                          ).itemClaimsRefs,
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

typedef $$BillItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BillItemsTable,
      BillItem,
      $$BillItemsTableFilterComposer,
      $$BillItemsTableOrderingComposer,
      $$BillItemsTableAnnotationComposer,
      $$BillItemsTableCreateCompanionBuilder,
      $$BillItemsTableUpdateCompanionBuilder,
      (BillItem, $$BillItemsTableReferences),
      BillItem,
      PrefetchHooks Function({bool billId, bool itemClaimsRefs})
    >;
typedef $$ItemClaimsTableCreateCompanionBuilder =
    ItemClaimsCompanion Function({
      required String id,
      required String itemId,
      required String userId,
      required int claimedQuantity,
      Value<bool> isShared,
      Value<int> rowid,
    });
typedef $$ItemClaimsTableUpdateCompanionBuilder =
    ItemClaimsCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String> userId,
      Value<int> claimedQuantity,
      Value<bool> isShared,
      Value<int> rowid,
    });

final class $$ItemClaimsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemClaimsTable, ItemClaim> {
  $$ItemClaimsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BillItemsTable _itemIdTable(_$AppDatabase db) =>
      db.billItems.createAlias('item_claims__item_id__bill_items__id');

  $$BillItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$BillItemsTableTableManager(
      $_db,
      $_db.billItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemClaimsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemClaimsTable> {
  $$ItemClaimsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get claimedQuantity => $composableBuilder(
    column: $table.claimedQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isShared => $composableBuilder(
    column: $table.isShared,
    builder: (column) => ColumnFilters(column),
  );

  $$BillItemsTableFilterComposer get itemId {
    final $$BillItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.billItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillItemsTableFilterComposer(
            $db: $db,
            $table: $db.billItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemClaimsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemClaimsTable> {
  $$ItemClaimsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get claimedQuantity => $composableBuilder(
    column: $table.claimedQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isShared => $composableBuilder(
    column: $table.isShared,
    builder: (column) => ColumnOrderings(column),
  );

  $$BillItemsTableOrderingComposer get itemId {
    final $$BillItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.billItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillItemsTableOrderingComposer(
            $db: $db,
            $table: $db.billItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemClaimsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemClaimsTable> {
  $$ItemClaimsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get claimedQuantity => $composableBuilder(
    column: $table.claimedQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isShared =>
      $composableBuilder(column: $table.isShared, builder: (column) => column);

  $$BillItemsTableAnnotationComposer get itemId {
    final $$BillItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.billItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.billItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemClaimsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemClaimsTable,
          ItemClaim,
          $$ItemClaimsTableFilterComposer,
          $$ItemClaimsTableOrderingComposer,
          $$ItemClaimsTableAnnotationComposer,
          $$ItemClaimsTableCreateCompanionBuilder,
          $$ItemClaimsTableUpdateCompanionBuilder,
          (ItemClaim, $$ItemClaimsTableReferences),
          ItemClaim,
          PrefetchHooks Function({bool itemId})
        > {
  $$ItemClaimsTableTableManager(_$AppDatabase db, $ItemClaimsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemClaimsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemClaimsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemClaimsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> claimedQuantity = const Value.absent(),
                Value<bool> isShared = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemClaimsCompanion(
                id: id,
                itemId: itemId,
                userId: userId,
                claimedQuantity: claimedQuantity,
                isShared: isShared,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required String userId,
                required int claimedQuantity,
                Value<bool> isShared = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemClaimsCompanion.insert(
                id: id,
                itemId: itemId,
                userId: userId,
                claimedQuantity: claimedQuantity,
                isShared: isShared,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemClaimsTable, ItemClaim>(table),
                  $$ItemClaimsTableReferences(db, table, e),
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
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$ItemClaimsTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$ItemClaimsTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$ItemClaimsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemClaimsTable,
      ItemClaim,
      $$ItemClaimsTableFilterComposer,
      $$ItemClaimsTableOrderingComposer,
      $$ItemClaimsTableAnnotationComposer,
      $$ItemClaimsTableCreateCompanionBuilder,
      $$ItemClaimsTableUpdateCompanionBuilder,
      (ItemClaim, $$ItemClaimsTableReferences),
      ItemClaim,
      PrefetchHooks Function({bool itemId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedBillsTableTableManager get cachedBills =>
      $$CachedBillsTableTableManager(_db, _db.cachedBills);
  $$OfflineDraftsTableTableManager get offlineDrafts =>
      $$OfflineDraftsTableTableManager(_db, _db.offlineDrafts);
  $$BillsTableTableManager get bills =>
      $$BillsTableTableManager(_db, _db.bills);
  $$BillItemsTableTableManager get billItems =>
      $$BillItemsTableTableManager(_db, _db.billItems);
  $$ItemClaimsTableTableManager get itemClaims =>
      $$ItemClaimsTableTableManager(_db, _db.itemClaims);
}
