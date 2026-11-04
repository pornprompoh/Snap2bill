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
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localImagePathMeta = const VerificationMeta(
    'localImagePath',
  );
  @override
  late final GeneratedColumn<String> localImagePath = GeneratedColumn<String>(
    'local_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
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
    payloadJson,
    localImagePath,
    syncStatus,
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
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('local_image_path')) {
      context.handle(
        _localImagePathMeta,
        localImagePath.isAcceptableOrUnknown(
          data['local_image_path']!,
          _localImagePathMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
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
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      ),
      localImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_image_path'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
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
  final String? payloadJson;
  final String? localImagePath;
  final String syncStatus;
  final DateTime cachedAt;
  const CachedBill({
    required this.id,
    this.shopName,
    required this.totalAmount,
    this.receiptDate,
    required this.status,
    this.receiptJson,
    this.sharersJson,
    this.payloadJson,
    this.localImagePath,
    required this.syncStatus,
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
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    if (!nullToAbsent || localImagePath != null) {
      map['local_image_path'] = Variable<String>(localImagePath);
    }
    map['sync_status'] = Variable<String>(syncStatus);
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
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
      localImagePath: localImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localImagePath),
      syncStatus: Value(syncStatus),
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
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
      localImagePath: serializer.fromJson<String?>(json['localImagePath']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
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
      'payloadJson': serializer.toJson<String?>(payloadJson),
      'localImagePath': serializer.toJson<String?>(localImagePath),
      'syncStatus': serializer.toJson<String>(syncStatus),
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
    Value<String?> payloadJson = const Value.absent(),
    Value<String?> localImagePath = const Value.absent(),
    String? syncStatus,
    DateTime? cachedAt,
  }) => CachedBill(
    id: id ?? this.id,
    shopName: shopName.present ? shopName.value : this.shopName,
    totalAmount: totalAmount ?? this.totalAmount,
    receiptDate: receiptDate.present ? receiptDate.value : this.receiptDate,
    status: status ?? this.status,
    receiptJson: receiptJson.present ? receiptJson.value : this.receiptJson,
    sharersJson: sharersJson.present ? sharersJson.value : this.sharersJson,
    payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
    localImagePath: localImagePath.present
        ? localImagePath.value
        : this.localImagePath,
    syncStatus: syncStatus ?? this.syncStatus,
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
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      localImagePath: data.localImagePath.present
          ? data.localImagePath.value
          : this.localImagePath,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
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
          ..write('payloadJson: $payloadJson, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('syncStatus: $syncStatus, ')
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
    payloadJson,
    localImagePath,
    syncStatus,
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
          other.payloadJson == this.payloadJson &&
          other.localImagePath == this.localImagePath &&
          other.syncStatus == this.syncStatus &&
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
  final Value<String?> payloadJson;
  final Value<String?> localImagePath;
  final Value<String> syncStatus;
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
    this.payloadJson = const Value.absent(),
    this.localImagePath = const Value.absent(),
    this.syncStatus = const Value.absent(),
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
    this.payloadJson = const Value.absent(),
    this.localImagePath = const Value.absent(),
    this.syncStatus = const Value.absent(),
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
    Expression<String>? payloadJson,
    Expression<String>? localImagePath,
    Expression<String>? syncStatus,
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
      if (payloadJson != null) 'payload_json': payloadJson,
      if (localImagePath != null) 'local_image_path': localImagePath,
      if (syncStatus != null) 'sync_status': syncStatus,
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
    Value<String?>? payloadJson,
    Value<String?>? localImagePath,
    Value<String>? syncStatus,
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
      payloadJson: payloadJson ?? this.payloadJson,
      localImagePath: localImagePath ?? this.localImagePath,
      syncStatus: syncStatus ?? this.syncStatus,
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
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (localImagePath.present) {
      map['local_image_path'] = Variable<String>(localImagePath.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
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
          ..write('payloadJson: $payloadJson, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedProfilesTable extends CachedProfiles
    with TableInfo<$CachedProfilesTable, CachedProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [id, payloadJson, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
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
  CachedProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedProfilesTable createAlias(String alias) {
    return $CachedProfilesTable(attachedDatabase, alias);
  }
}

class CachedProfile extends DataClass implements Insertable<CachedProfile> {
  final String id;
  final String payloadJson;
  final DateTime cachedAt;
  const CachedProfile({
    required this.id,
    required this.payloadJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload_json'] = Variable<String>(payloadJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedProfilesCompanion toCompanion(bool nullToAbsent) {
    return CachedProfilesCompanion(
      id: Value(id),
      payloadJson: Value(payloadJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProfile(
      id: serializer.fromJson<String>(json['id']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedProfile copyWith({
    String? id,
    String? payloadJson,
    DateTime? cachedAt,
  }) => CachedProfile(
    id: id ?? this.id,
    payloadJson: payloadJson ?? this.payloadJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedProfile copyWithCompanion(CachedProfilesCompanion data) {
    return CachedProfile(
      id: data.id.present ? data.id.value : this.id,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfile(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payloadJson, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProfile &&
          other.id == this.id &&
          other.payloadJson == this.payloadJson &&
          other.cachedAt == this.cachedAt);
}

class CachedProfilesCompanion extends UpdateCompanion<CachedProfile> {
  final Value<String> id;
  final Value<String> payloadJson;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedProfilesCompanion({
    this.id = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedProfilesCompanion.insert({
    required String id,
    required String payloadJson,
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payloadJson = Value(payloadJson);
  static Insertable<CachedProfile> custom({
    Expression<String>? id,
    Expression<String>? payloadJson,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? payloadJson,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedProfilesCompanion(
      id: id ?? this.id,
      payloadJson: payloadJson ?? this.payloadJson,
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
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
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
    return (StringBuffer('CachedProfilesCompanion(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedRoomsTable extends CachedRooms
    with TableInfo<$CachedRoomsTable, CachedRoom> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedRoomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _roomCodeMeta = const VerificationMeta(
    'roomCode',
  );
  @override
  late final GeneratedColumn<String> roomCode = GeneratedColumn<String>(
    'room_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [roomCode, payloadJson, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_rooms';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedRoom> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('room_code')) {
      context.handle(
        _roomCodeMeta,
        roomCode.isAcceptableOrUnknown(data['room_code']!, _roomCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_roomCodeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
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
  Set<GeneratedColumn> get $primaryKey => {roomCode};
  @override
  CachedRoom map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedRoom(
      roomCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_code'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedRoomsTable createAlias(String alias) {
    return $CachedRoomsTable(attachedDatabase, alias);
  }
}

class CachedRoom extends DataClass implements Insertable<CachedRoom> {
  final String roomCode;
  final String payloadJson;
  final DateTime cachedAt;
  const CachedRoom({
    required this.roomCode,
    required this.payloadJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['room_code'] = Variable<String>(roomCode);
    map['payload_json'] = Variable<String>(payloadJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedRoomsCompanion toCompanion(bool nullToAbsent) {
    return CachedRoomsCompanion(
      roomCode: Value(roomCode),
      payloadJson: Value(payloadJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedRoom.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedRoom(
      roomCode: serializer.fromJson<String>(json['roomCode']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'roomCode': serializer.toJson<String>(roomCode),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedRoom copyWith({
    String? roomCode,
    String? payloadJson,
    DateTime? cachedAt,
  }) => CachedRoom(
    roomCode: roomCode ?? this.roomCode,
    payloadJson: payloadJson ?? this.payloadJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedRoom copyWithCompanion(CachedRoomsCompanion data) {
    return CachedRoom(
      roomCode: data.roomCode.present ? data.roomCode.value : this.roomCode,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedRoom(')
          ..write('roomCode: $roomCode, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(roomCode, payloadJson, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedRoom &&
          other.roomCode == this.roomCode &&
          other.payloadJson == this.payloadJson &&
          other.cachedAt == this.cachedAt);
}

class CachedRoomsCompanion extends UpdateCompanion<CachedRoom> {
  final Value<String> roomCode;
  final Value<String> payloadJson;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedRoomsCompanion({
    this.roomCode = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedRoomsCompanion.insert({
    required String roomCode,
    required String payloadJson,
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : roomCode = Value(roomCode),
       payloadJson = Value(payloadJson);
  static Insertable<CachedRoom> custom({
    Expression<String>? roomCode,
    Expression<String>? payloadJson,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (roomCode != null) 'room_code': roomCode,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedRoomsCompanion copyWith({
    Value<String>? roomCode,
    Value<String>? payloadJson,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedRoomsCompanion(
      roomCode: roomCode ?? this.roomCode,
      payloadJson: payloadJson ?? this.payloadJson,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (roomCode.present) {
      map['room_code'] = Variable<String>(roomCode.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
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
    return (StringBuffer('CachedRoomsCompanion(')
          ..write('roomCode: $roomCode, ')
          ..write('payloadJson: $payloadJson, ')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedBillsTable cachedBills = $CachedBillsTable(this);
  late final $CachedProfilesTable cachedProfiles = $CachedProfilesTable(this);
  late final $CachedRoomsTable cachedRooms = $CachedRoomsTable(this);
  late final $OfflineDraftsTable offlineDrafts = $OfflineDraftsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedBills,
    cachedProfiles,
    cachedRooms,
    offlineDrafts,
  ];
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
      Value<String?> payloadJson,
      Value<String?> localImagePath,
      Value<String> syncStatus,
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
      Value<String?> payloadJson,
      Value<String?> localImagePath,
      Value<String> syncStatus,
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

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
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

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
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

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
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
                Value<String?> payloadJson = const Value.absent(),
                Value<String?> localImagePath = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
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
                payloadJson: payloadJson,
                localImagePath: localImagePath,
                syncStatus: syncStatus,
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
                Value<String?> payloadJson = const Value.absent(),
                Value<String?> localImagePath = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
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
                payloadJson: payloadJson,
                localImagePath: localImagePath,
                syncStatus: syncStatus,
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
typedef $$CachedProfilesTableCreateCompanionBuilder =
    CachedProfilesCompanion Function({
      required String id,
      required String payloadJson,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$CachedProfilesTableUpdateCompanionBuilder =
    CachedProfilesCompanion Function({
      Value<String> id,
      Value<String> payloadJson,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableFilterComposer({
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

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedProfilesTable,
          CachedProfile,
          $$CachedProfilesTableFilterComposer,
          $$CachedProfilesTableOrderingComposer,
          $$CachedProfilesTableAnnotationComposer,
          $$CachedProfilesTableCreateCompanionBuilder,
          $$CachedProfilesTableUpdateCompanionBuilder,
          (
            CachedProfile,
            BaseReferences<_$AppDatabase, $CachedProfilesTable, CachedProfile>,
          ),
          CachedProfile,
          PrefetchHooks Function()
        > {
  $$CachedProfilesTableTableManager(
    _$AppDatabase db,
    $CachedProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedProfilesCompanion(
                id: id,
                payloadJson: payloadJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payloadJson,
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedProfilesCompanion.insert(
                id: id,
                payloadJson: payloadJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedProfilesTable, CachedProfile>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedProfilesTable,
                    CachedProfile
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedProfilesTable,
      CachedProfile,
      $$CachedProfilesTableFilterComposer,
      $$CachedProfilesTableOrderingComposer,
      $$CachedProfilesTableAnnotationComposer,
      $$CachedProfilesTableCreateCompanionBuilder,
      $$CachedProfilesTableUpdateCompanionBuilder,
      (
        CachedProfile,
        BaseReferences<_$AppDatabase, $CachedProfilesTable, CachedProfile>,
      ),
      CachedProfile,
      PrefetchHooks Function()
    >;
typedef $$CachedRoomsTableCreateCompanionBuilder =
    CachedRoomsCompanion Function({
      required String roomCode,
      required String payloadJson,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$CachedRoomsTableUpdateCompanionBuilder =
    CachedRoomsCompanion Function({
      Value<String> roomCode,
      Value<String> payloadJson,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedRoomsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedRoomsTable> {
  $$CachedRoomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get roomCode => $composableBuilder(
    column: $table.roomCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedRoomsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedRoomsTable> {
  $$CachedRoomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get roomCode => $composableBuilder(
    column: $table.roomCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedRoomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedRoomsTable> {
  $$CachedRoomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get roomCode =>
      $composableBuilder(column: $table.roomCode, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedRoomsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedRoomsTable,
          CachedRoom,
          $$CachedRoomsTableFilterComposer,
          $$CachedRoomsTableOrderingComposer,
          $$CachedRoomsTableAnnotationComposer,
          $$CachedRoomsTableCreateCompanionBuilder,
          $$CachedRoomsTableUpdateCompanionBuilder,
          (
            CachedRoom,
            BaseReferences<_$AppDatabase, $CachedRoomsTable, CachedRoom>,
          ),
          CachedRoom,
          PrefetchHooks Function()
        > {
  $$CachedRoomsTableTableManager(_$AppDatabase db, $CachedRoomsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedRoomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedRoomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedRoomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> roomCode = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedRoomsCompanion(
                roomCode: roomCode,
                payloadJson: payloadJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String roomCode,
                required String payloadJson,
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedRoomsCompanion.insert(
                roomCode: roomCode,
                payloadJson: payloadJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedRoomsTable, CachedRoom>(table),
                  BaseReferences<_$AppDatabase, $CachedRoomsTable, CachedRoom>(
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

typedef $$CachedRoomsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedRoomsTable,
      CachedRoom,
      $$CachedRoomsTableFilterComposer,
      $$CachedRoomsTableOrderingComposer,
      $$CachedRoomsTableAnnotationComposer,
      $$CachedRoomsTableCreateCompanionBuilder,
      $$CachedRoomsTableUpdateCompanionBuilder,
      (
        CachedRoom,
        BaseReferences<_$AppDatabase, $CachedRoomsTable, CachedRoom>,
      ),
      CachedRoom,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedBillsTableTableManager get cachedBills =>
      $$CachedBillsTableTableManager(_db, _db.cachedBills);
  $$CachedProfilesTableTableManager get cachedProfiles =>
      $$CachedProfilesTableTableManager(_db, _db.cachedProfiles);
  $$CachedRoomsTableTableManager get cachedRooms =>
      $$CachedRoomsTableTableManager(_db, _db.cachedRooms);
  $$OfflineDraftsTableTableManager get offlineDrafts =>
      $$OfflineDraftsTableTableManager(_db, _db.offlineDrafts);
}
