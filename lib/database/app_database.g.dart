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
  static const VerificationMeta _localImagePathMeta = const VerificationMeta(
    'localImagePath',
  );
  @override
  late final GeneratedColumn<String> localImagePath = GeneratedColumn<String>(
    'receipt_image_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localImageBytesMeta = const VerificationMeta(
    'localImageBytes',
  );
  @override
  late final GeneratedColumn<Uint8List> localImageBytes =
      GeneratedColumn<Uint8List>(
        'local_image_bytes',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _receiptImageUrlMeta = const VerificationMeta(
    'receiptImageUrl',
  );
  @override
  late final GeneratedColumn<String> receiptImageUrl = GeneratedColumn<String>(
    'receipt_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedForUserIdMeta = const VerificationMeta(
    'cachedForUserId',
  );
  @override
  late final GeneratedColumn<String> cachedForUserId = GeneratedColumn<String>(
    'cached_for_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    localImagePath,
    localImageBytes,
    receiptImageUrl,
    ownerId,
    cachedForUserId,
    syncedWithServer,
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
    if (data.containsKey('receipt_image_local_path')) {
      context.handle(
        _localImagePathMeta,
        localImagePath.isAcceptableOrUnknown(
          data['receipt_image_local_path']!,
          _localImagePathMeta,
        ),
      );
    }
    if (data.containsKey('local_image_bytes')) {
      context.handle(
        _localImageBytesMeta,
        localImageBytes.isAcceptableOrUnknown(
          data['local_image_bytes']!,
          _localImageBytesMeta,
        ),
      );
    }
    if (data.containsKey('receipt_image_url')) {
      context.handle(
        _receiptImageUrlMeta,
        receiptImageUrl.isAcceptableOrUnknown(
          data['receipt_image_url']!,
          _receiptImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('cached_for_user_id')) {
      context.handle(
        _cachedForUserIdMeta,
        cachedForUserId.isAcceptableOrUnknown(
          data['cached_for_user_id']!,
          _cachedForUserIdMeta,
        ),
      );
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
      localImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_image_local_path'],
      ),
      localImageBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}local_image_bytes'],
      ),
      receiptImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_image_url'],
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      cachedForUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_for_user_id'],
      ),
      syncedWithServer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced_with_server'],
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
  final String? localImagePath;
  final Uint8List? localImageBytes;
  final String? receiptImageUrl;
  final String? ownerId;
  final String? cachedForUserId;
  final bool syncedWithServer;
  final DateTime cachedAt;
  const CachedBill({
    required this.id,
    this.shopName,
    required this.totalAmount,
    this.receiptDate,
    required this.status,
    this.receiptJson,
    this.sharersJson,
    this.localImagePath,
    this.localImageBytes,
    this.receiptImageUrl,
    this.ownerId,
    this.cachedForUserId,
    required this.syncedWithServer,
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
    if (!nullToAbsent || localImagePath != null) {
      map['receipt_image_local_path'] = Variable<String>(localImagePath);
    }
    if (!nullToAbsent || localImageBytes != null) {
      map['local_image_bytes'] = Variable<Uint8List>(localImageBytes);
    }
    if (!nullToAbsent || receiptImageUrl != null) {
      map['receipt_image_url'] = Variable<String>(receiptImageUrl);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    if (!nullToAbsent || cachedForUserId != null) {
      map['cached_for_user_id'] = Variable<String>(cachedForUserId);
    }
    map['synced_with_server'] = Variable<bool>(syncedWithServer);
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
      localImagePath: localImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localImagePath),
      localImageBytes: localImageBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(localImageBytes),
      receiptImageUrl: receiptImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptImageUrl),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      cachedForUserId: cachedForUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(cachedForUserId),
      syncedWithServer: Value(syncedWithServer),
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
      localImagePath: serializer.fromJson<String?>(json['localImagePath']),
      localImageBytes: serializer.fromJson<Uint8List?>(json['localImageBytes']),
      receiptImageUrl: serializer.fromJson<String?>(json['receiptImageUrl']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      cachedForUserId: serializer.fromJson<String?>(json['cachedForUserId']),
      syncedWithServer: serializer.fromJson<bool>(json['syncedWithServer']),
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
      'localImagePath': serializer.toJson<String?>(localImagePath),
      'localImageBytes': serializer.toJson<Uint8List?>(localImageBytes),
      'receiptImageUrl': serializer.toJson<String?>(receiptImageUrl),
      'ownerId': serializer.toJson<String?>(ownerId),
      'cachedForUserId': serializer.toJson<String?>(cachedForUserId),
      'syncedWithServer': serializer.toJson<bool>(syncedWithServer),
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
    Value<String?> localImagePath = const Value.absent(),
    Value<Uint8List?> localImageBytes = const Value.absent(),
    Value<String?> receiptImageUrl = const Value.absent(),
    Value<String?> ownerId = const Value.absent(),
    Value<String?> cachedForUserId = const Value.absent(),
    bool? syncedWithServer,
    DateTime? cachedAt,
  }) => CachedBill(
    id: id ?? this.id,
    shopName: shopName.present ? shopName.value : this.shopName,
    totalAmount: totalAmount ?? this.totalAmount,
    receiptDate: receiptDate.present ? receiptDate.value : this.receiptDate,
    status: status ?? this.status,
    receiptJson: receiptJson.present ? receiptJson.value : this.receiptJson,
    sharersJson: sharersJson.present ? sharersJson.value : this.sharersJson,
    localImagePath: localImagePath.present
        ? localImagePath.value
        : this.localImagePath,
    localImageBytes: localImageBytes.present
        ? localImageBytes.value
        : this.localImageBytes,
    receiptImageUrl: receiptImageUrl.present
        ? receiptImageUrl.value
        : this.receiptImageUrl,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    cachedForUserId: cachedForUserId.present
        ? cachedForUserId.value
        : this.cachedForUserId,
    syncedWithServer: syncedWithServer ?? this.syncedWithServer,
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
      localImagePath: data.localImagePath.present
          ? data.localImagePath.value
          : this.localImagePath,
      localImageBytes: data.localImageBytes.present
          ? data.localImageBytes.value
          : this.localImageBytes,
      receiptImageUrl: data.receiptImageUrl.present
          ? data.receiptImageUrl.value
          : this.receiptImageUrl,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      cachedForUserId: data.cachedForUserId.present
          ? data.cachedForUserId.value
          : this.cachedForUserId,
      syncedWithServer: data.syncedWithServer.present
          ? data.syncedWithServer.value
          : this.syncedWithServer,
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
          ..write('localImagePath: $localImagePath, ')
          ..write('localImageBytes: $localImageBytes, ')
          ..write('receiptImageUrl: $receiptImageUrl, ')
          ..write('ownerId: $ownerId, ')
          ..write('cachedForUserId: $cachedForUserId, ')
          ..write('syncedWithServer: $syncedWithServer, ')
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
    localImagePath,
    $driftBlobEquality.hash(localImageBytes),
    receiptImageUrl,
    ownerId,
    cachedForUserId,
    syncedWithServer,
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
          other.localImagePath == this.localImagePath &&
          $driftBlobEquality.equals(
            other.localImageBytes,
            this.localImageBytes,
          ) &&
          other.receiptImageUrl == this.receiptImageUrl &&
          other.ownerId == this.ownerId &&
          other.cachedForUserId == this.cachedForUserId &&
          other.syncedWithServer == this.syncedWithServer &&
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
  final Value<String?> localImagePath;
  final Value<Uint8List?> localImageBytes;
  final Value<String?> receiptImageUrl;
  final Value<String?> ownerId;
  final Value<String?> cachedForUserId;
  final Value<bool> syncedWithServer;
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
    this.localImagePath = const Value.absent(),
    this.localImageBytes = const Value.absent(),
    this.receiptImageUrl = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.cachedForUserId = const Value.absent(),
    this.syncedWithServer = const Value.absent(),
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
    this.localImagePath = const Value.absent(),
    this.localImageBytes = const Value.absent(),
    this.receiptImageUrl = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.cachedForUserId = const Value.absent(),
    this.syncedWithServer = const Value.absent(),
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
    Expression<String>? localImagePath,
    Expression<Uint8List>? localImageBytes,
    Expression<String>? receiptImageUrl,
    Expression<String>? ownerId,
    Expression<String>? cachedForUserId,
    Expression<bool>? syncedWithServer,
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
      if (localImagePath != null) 'receipt_image_local_path': localImagePath,
      if (localImageBytes != null) 'local_image_bytes': localImageBytes,
      if (receiptImageUrl != null) 'receipt_image_url': receiptImageUrl,
      if (ownerId != null) 'owner_id': ownerId,
      if (cachedForUserId != null) 'cached_for_user_id': cachedForUserId,
      if (syncedWithServer != null) 'synced_with_server': syncedWithServer,
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
    Value<String?>? localImagePath,
    Value<Uint8List?>? localImageBytes,
    Value<String?>? receiptImageUrl,
    Value<String?>? ownerId,
    Value<String?>? cachedForUserId,
    Value<bool>? syncedWithServer,
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
      localImagePath: localImagePath ?? this.localImagePath,
      localImageBytes: localImageBytes ?? this.localImageBytes,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      ownerId: ownerId ?? this.ownerId,
      cachedForUserId: cachedForUserId ?? this.cachedForUserId,
      syncedWithServer: syncedWithServer ?? this.syncedWithServer,
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
    if (localImagePath.present) {
      map['receipt_image_local_path'] = Variable<String>(localImagePath.value);
    }
    if (localImageBytes.present) {
      map['local_image_bytes'] = Variable<Uint8List>(localImageBytes.value);
    }
    if (receiptImageUrl.present) {
      map['receipt_image_url'] = Variable<String>(receiptImageUrl.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (cachedForUserId.present) {
      map['cached_for_user_id'] = Variable<String>(cachedForUserId.value);
    }
    if (syncedWithServer.present) {
      map['synced_with_server'] = Variable<bool>(syncedWithServer.value);
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
          ..write('localImagePath: $localImagePath, ')
          ..write('localImageBytes: $localImageBytes, ')
          ..write('receiptImageUrl: $receiptImageUrl, ')
          ..write('ownerId: $ownerId, ')
          ..write('cachedForUserId: $cachedForUserId, ')
          ..write('syncedWithServer: $syncedWithServer, ')
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
  late final $OfflineDraftsTable offlineDrafts = $OfflineDraftsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedBills,
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
      Value<String?> localImagePath,
      Value<Uint8List?> localImageBytes,
      Value<String?> receiptImageUrl,
      Value<String?> ownerId,
      Value<String?> cachedForUserId,
      Value<bool> syncedWithServer,
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
      Value<String?> localImagePath,
      Value<Uint8List?> localImageBytes,
      Value<String?> receiptImageUrl,
      Value<String?> ownerId,
      Value<String?> cachedForUserId,
      Value<bool> syncedWithServer,
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

  ColumnFilters<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get localImageBytes => $composableBuilder(
    column: $table.localImageBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptImageUrl => $composableBuilder(
    column: $table.receiptImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncedWithServer => $composableBuilder(
    column: $table.syncedWithServer,
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

  ColumnOrderings<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get localImageBytes => $composableBuilder(
    column: $table.localImageBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptImageUrl => $composableBuilder(
    column: $table.receiptImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncedWithServer => $composableBuilder(
    column: $table.syncedWithServer,
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

  GeneratedColumn<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get localImageBytes => $composableBuilder(
    column: $table.localImageBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptImageUrl => $composableBuilder(
    column: $table.receiptImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncedWithServer => $composableBuilder(
    column: $table.syncedWithServer,
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
                Value<String?> localImagePath = const Value.absent(),
                Value<Uint8List?> localImageBytes = const Value.absent(),
                Value<String?> receiptImageUrl = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> cachedForUserId = const Value.absent(),
                Value<bool> syncedWithServer = const Value.absent(),
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
                localImagePath: localImagePath,
                localImageBytes: localImageBytes,
                receiptImageUrl: receiptImageUrl,
                ownerId: ownerId,
                cachedForUserId: cachedForUserId,
                syncedWithServer: syncedWithServer,
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
                Value<String?> localImagePath = const Value.absent(),
                Value<Uint8List?> localImageBytes = const Value.absent(),
                Value<String?> receiptImageUrl = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> cachedForUserId = const Value.absent(),
                Value<bool> syncedWithServer = const Value.absent(),
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
                localImagePath: localImagePath,
                localImageBytes: localImageBytes,
                receiptImageUrl: receiptImageUrl,
                ownerId: ownerId,
                cachedForUserId: cachedForUserId,
                syncedWithServer: syncedWithServer,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedBillsTableTableManager get cachedBills =>
      $$CachedBillsTableTableManager(_db, _db.cachedBills);
  $$OfflineDraftsTableTableManager get offlineDrafts =>
      $$OfflineDraftsTableTableManager(_db, _db.offlineDrafts);
}
