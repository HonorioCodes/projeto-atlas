import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/weight_record.dart';

abstract interface class WeightHistoryStorage {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}

class _SharedPreferencesWeightHistoryStorage implements WeightHistoryStorage {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<String?> getString(String key) {
    return _preferences.getString(key);
  }

  @override
  Future<void> setString(String key, String value) {
    return _preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) {
    return _preferences.remove(key);
  }
}

class WeightHistoryService {
  static const String _historyKey = 'weight_history';

  static const int _maximumRecords = 500;

  static const double _weightTolerance = 0.005;
  static const double _comparisonEpsilon = 0.000000001;

  final WeightHistoryStorage _storage;
  final DateTime Function() _now;

  WeightHistoryService({
    WeightHistoryStorage? storage,
    DateTime Function()? now,
  }) : _storage = storage ?? _SharedPreferencesWeightHistoryStorage(),
       _now = now ?? DateTime.now;

  Future<List<WeightRecord>> loadRecords() async {
    try {
      return await loadRecordsStrict();
    } on FormatException {
      return [];
    }
  }

  Future<List<WeightRecord>> loadRecordsStrict() async {
    final savedHistory = await _storage.getString(_historyKey);

    if (savedHistory == null) {
      return [];
    }

    final dynamic decoded;

    try {
      decoded = jsonDecode(savedHistory);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Não foi possível ler o histórico: $error');
    }

    if (decoded is! List<dynamic>) {
      throw const FormatException('O histórico de peso deve ser uma lista.');
    }

    final records = <WeightRecord>[];
    final recordIds = <String>{};

    for (var index = 0; index < decoded.length; index++) {
      final rawRecord = decoded[index];

      if (rawRecord is! Map<String, dynamic>) {
        throw FormatException(
          'O registro de peso na posição $index é inválido.',
        );
      }

      final id = rawRecord['id'];
      final rawWeight = rawRecord['weightKg'];
      final rawRecordedAt = rawRecord['recordedAt'];

      if (id is! String || id.trim().isEmpty) {
        throw FormatException('O id do registro na posição $index é inválido.');
      }

      if (!recordIds.add(id)) {
        throw FormatException('O id de registro "$id" está duplicado.');
      }

      if (rawWeight is! num) {
        throw FormatException(
          'O peso do registro na posição $index é inválido.',
        );
      }

      final weight = rawWeight.toDouble();

      if (!_isValidWeight(weight)) {
        throw FormatException(
          'O peso do registro na posição $index é inválido.',
        );
      }

      if (rawRecordedAt is! String) {
        throw FormatException(
          'A data do registro na posição $index é inválida.',
        );
      }

      final recordedAt = DateTime.tryParse(rawRecordedAt);

      if (recordedAt == null) {
        throw FormatException(
          'A data do registro na posição $index é inválida.',
        );
      }

      records.add(
        WeightRecord(id: id, weightKg: weight, recordedAt: recordedAt),
      );
    }

    _sortNewestFirst(records);

    return records;
  }

  Future<void> ensureInitialRecord(double initialWeight) async {
    final records = await loadRecordsStrict();

    if (records.isNotEmpty || initialWeight <= 0) {
      return;
    }

    if (!_isValidWeight(initialWeight)) {
      throw ArgumentError.value(
        initialWeight,
        'initialWeight',
        'O peso deve ser maior que zero e finito.',
      );
    }

    final recordedAt = _now();

    final initialRecord = WeightRecord(
      id:
          'initial-'
          '${recordedAt.microsecondsSinceEpoch}',
      weightKg: initialWeight,
      recordedAt: recordedAt,
    );

    await replaceRecords([initialRecord]);
  }

  Future<void> saveRecord(WeightRecord record) async {
    final records = await loadRecordsStrict();

    records.insert(0, record);

    await replaceRecords(records);
  }

  Future<void> updateProfileWeights({
    required double initialWeight,
    required double currentWeight,
    required bool addCurrentWeightRecord,
  }) async {
    if (!_isValidWeight(initialWeight) || !_isValidWeight(currentWeight)) {
      throw ArgumentError('Os pesos devem ser maiores que zero e finitos.');
    }

    final records = await loadRecordsStrict();
    final now = _now();

    if (records.isEmpty) {
      final initialRecord = WeightRecord(
        id:
            'initial-'
            '${now.microsecondsSinceEpoch}',
        weightKg: initialWeight,
        recordedAt: now,
      );

      final weightsAreEqual = _weightsAreEqual(initialWeight, currentWeight);

      if (weightsAreEqual) {
        await replaceRecords([
          WeightRecord(
            id: initialRecord.id,
            weightKg: initialWeight,
            recordedAt: initialRecord.recordedAt,
          ),
        ]);
        return;
      }

      final preferredCurrentDate = addCurrentWeightRecord
          ? now
          : initialRecord.recordedAt.add(const Duration(microseconds: 1));

      // Sem histórico anterior, não há uma data antiga para preservar. A
      // correção inicializa a representação atual junto ao registro inicial.
      final currentRecord = _createCurrentRecord(
        records: [initialRecord],
        weight: currentWeight,
        preferredDate: preferredCurrentDate,
      );

      await replaceRecords([currentRecord, initialRecord]);

      return;
    }

    final initialRecordIndex = _findInitialRecordIndex(records);
    final previousInitialRecord = records[initialRecordIndex];

    final updatedInitialRecord = WeightRecord(
      id: previousInitialRecord.id,
      weightKg: initialWeight,
      recordedAt: previousInitialRecord.recordedAt,
    );

    if (records.length == 1) {
      if (_weightsAreEqual(initialWeight, currentWeight)) {
        await replaceRecords([
          WeightRecord(
            id: previousInitialRecord.id,
            weightKg: initialWeight,
            recordedAt: previousInitialRecord.recordedAt,
          ),
        ]);
        return;
      }

      records[initialRecordIndex] = updatedInitialRecord;

      final preferredCurrentDate = addCurrentWeightRecord
          ? now
          : previousInitialRecord.recordedAt.add(
              const Duration(microseconds: 1),
            );

      // Pesos inicial e atual diferentes exigem dois registros. Ao corrigir,
      // a representação atual herda o instante histórico, ligeiramente
      // posterior ao inicial, em vez de criar uma pesagem datada de hoje.
      final currentRecord = _createCurrentRecord(
        records: records,
        weight: currentWeight,
        preferredDate: preferredCurrentDate,
      );

      records.add(currentRecord);

      await replaceRecords(records);
      return;
    }

    final currentRecordIndex = _findCurrentRecordIndex(
      records,
      initialRecordIndex,
    );
    final previousCurrentRecord = records[currentRecordIndex];

    records[initialRecordIndex] = updatedInitialRecord;

    if (!_weightsAreEqual(previousCurrentRecord.weightKg, currentWeight)) {
      if (addCurrentWeightRecord) {
        final currentRecord = _createCurrentRecord(
          records: records,
          weight: currentWeight,
          preferredDate: now,
        );

        records.insert(0, currentRecord);
      } else {
        records[currentRecordIndex] = WeightRecord(
          id: previousCurrentRecord.id,
          weightKg: currentWeight,
          recordedAt: previousCurrentRecord.recordedAt,
        );
      }
    }

    await replaceRecords(records);
  }

  Future<void> replaceRecords(List<WeightRecord> records) async {
    final normalizedRecords = _normalizeAndLimit(records);

    await _saveAll(normalizedRecords);
  }

  List<WeightRecord> _normalizeAndLimit(List<WeightRecord> records) {
    final normalizedRecords = List<WeightRecord>.from(records);

    _validateRecords(normalizedRecords);
    _sortNewestFirst(normalizedRecords);

    if (normalizedRecords.length <= _maximumRecords) {
      return normalizedRecords;
    }

    final initialRecordIndex = _findInitialRecordIndex(normalizedRecords);
    final initialRecord = normalizedRecords[initialRecordIndex];

    final recentRecords = <WeightRecord>[
      for (var index = 0; index < normalizedRecords.length; index++)
        if (index != initialRecordIndex) normalizedRecords[index],
    ].take(_maximumRecords - 1);

    final limitedRecords = <WeightRecord>[...recentRecords, initialRecord];

    _sortNewestFirst(limitedRecords);

    return limitedRecords;
  }

  void _validateRecords(List<WeightRecord> records) {
    final recordIds = <String>{};

    for (final record in records) {
      if (record.id.trim().isEmpty) {
        throw ArgumentError('Todos os registros devem ter um id válido.');
      }

      if (!recordIds.add(record.id)) {
        throw ArgumentError('O id de registro "${record.id}" está duplicado.');
      }

      if (!_isValidWeight(record.weightKg)) {
        throw ArgumentError(
          'Todos os registros devem ter peso maior que zero e finito.',
        );
      }
    }
  }

  int _findInitialRecordIndex(List<WeightRecord> records) {
    if (records.isEmpty) {
      throw StateError('Não há registros de peso.');
    }

    int? initialRecordIndex;

    for (var index = 0; index < records.length; index++) {
      if (!records[index].id.startsWith('initial-')) {
        continue;
      }

      if (initialRecordIndex == null ||
          records[index].recordedAt.isBefore(
            records[initialRecordIndex].recordedAt,
          )) {
        initialRecordIndex = index;
      }
    }

    if (initialRecordIndex != null) {
      return initialRecordIndex;
    }

    var oldestRecordIndex = 0;

    for (var index = 1; index < records.length; index++) {
      if (records[index].recordedAt.isBefore(
        records[oldestRecordIndex].recordedAt,
      )) {
        oldestRecordIndex = index;
      }
    }

    return oldestRecordIndex;
  }

  int _findCurrentRecordIndex(
    List<WeightRecord> records,
    int initialRecordIndex,
  ) {
    for (var index = 0; index < records.length; index++) {
      if (index != initialRecordIndex) {
        return index;
      }
    }

    throw StateError('Não há registro de peso atual.');
  }

  WeightRecord _createCurrentRecord({
    required List<WeightRecord> records,
    required double weight,
    required DateTime preferredDate,
  }) {
    var recordedAt = preferredDate;

    while (records.any((record) {
      return record.id == recordedAt.microsecondsSinceEpoch.toString() ||
          record.recordedAt == recordedAt;
    })) {
      recordedAt = recordedAt.add(const Duration(microseconds: 1));
    }

    return WeightRecord(
      id: recordedAt.microsecondsSinceEpoch.toString(),
      weightKg: weight,
      recordedAt: recordedAt,
    );
  }

  static bool _isValidWeight(double weight) {
    return weight.isFinite && weight > 0;
  }

  static bool _weightsAreEqual(double first, double second) {
    final difference = (first - second).abs();

    return difference + _comparisonEpsilon < _weightTolerance;
  }

  static void _sortNewestFirst(List<WeightRecord> records) {
    records.sort((first, second) {
      final dateComparison = second.recordedAt.compareTo(first.recordedAt);

      if (dateComparison != 0) {
        return dateComparison;
      }

      return second.id.compareTo(first.id);
    });
  }

  Future<void> _saveAll(List<WeightRecord> records) async {
    final encodedRecords = records.map((record) => record.toJson()).toList();

    await _storage.setString(_historyKey, jsonEncode(encodedRecords));
  }

  Future<void> deleteAllRecords() async {
    await _storage.remove(_historyKey);
  }
}
