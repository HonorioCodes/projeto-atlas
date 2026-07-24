import 'dart:convert';

import 'package:app/models/weight_record.dart';
import 'package:app/services/weight_history_service.dart';
import 'package:flutter_test/flutter_test.dart';

const String _historyKey = 'weight_history';

final DateTime _initialDate = DateTime.utc(2020, 1, 1, 8);
final DateTime _firstIntermediateDate = DateTime.utc(2020, 2, 1, 8);
final DateTime _secondIntermediateDate = DateTime.utc(2020, 3, 1, 8);
final DateTime _currentDate = DateTime.utc(2020, 4, 1, 8);
final DateTime _fixedNow = DateTime.utc(2026, 7, 24, 12);

WeightRecord _record(String id, double weight, DateTime recordedAt) {
  return WeightRecord(id: id, weightKg: weight, recordedAt: recordedAt);
}

Map<String, dynamic> _recordMap(WeightRecord record) {
  return record.toJson();
}

bool _isOrderedNewestFirst(List<WeightRecord> records) {
  for (var index = 1; index < records.length; index++) {
    if (records[index].recordedAt.isAfter(records[index - 1].recordedAt)) {
      return false;
    }
  }

  return true;
}

class _MemoryWeightHistoryStorage implements WeightHistoryStorage {
  final Map<String, String> values = <String, String>{};

  int writeCount = 0;

  @override
  Future<String?> getString(String key) async {
    return values[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    writeCount++;
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

void main() {
  late _MemoryWeightHistoryStorage storage;
  late WeightHistoryService service;

  void installService() {
    storage = _MemoryWeightHistoryStorage();
    service = WeightHistoryService(storage: storage, now: () => _fixedNow);
  }

  setUp(installService);

  test('edita o registro initial preservando id e data', () async {
    final olderNonInitial = _record(
      'legacy-older',
      120,
      _initialDate.subtract(const Duration(days: 30)),
    );
    final initial = _record('initial-original', 110, _initialDate);
    final current = _record('current', 90, _currentDate);

    await service.replaceRecords([initial, current, olderNonInitial]);

    await service.updateProfileWeights(
      initialWeight: 105,
      currentWeight: 90,
      addCurrentWeightRecord: false,
    );

    final records = await service.loadRecordsStrict();
    final updatedInitial = records.singleWhere(
      (record) => record.id == initial.id,
    );

    expect(updatedInitial.weightKg, 105);
    expect(updatedInitial.recordedAt, initial.recordedAt);
    expect(
      records.singleWhere((record) => record.id == olderNonInitial.id).toJson(),
      olderNonInitial.toJson(),
    );
  });

  test('usa o registro mais antigo como inicial em histórico legado', () async {
    final legacyInitial = _record('legacy-initial', 115, _initialDate);
    final intermediate = _record(
      'legacy-intermediate',
      100,
      _firstIntermediateDate,
    );
    final current = _record('legacy-current', 90, _currentDate);

    await service.replaceRecords([intermediate, current, legacyInitial]);

    await service.updateProfileWeights(
      initialWeight: 112,
      currentWeight: 90,
      addCurrentWeightRecord: false,
    );

    final records = await service.loadRecordsStrict();
    final updatedInitial = records.singleWhere(
      (record) => record.id == legacyInitial.id,
    );

    expect(updatedInitial.weightKg, 112);
    expect(updatedInitial.recordedAt, legacyInitial.recordedAt);
  });

  test('peso atual dentro da tolerância não cria duplicata', () async {
    final initial = _record('initial-original', 100, _initialDate);
    final current = _record('current', 80, _currentDate);

    await service.replaceRecords([initial, current]);

    await service.updateProfileWeights(
      initialWeight: 100,
      currentWeight: 80.004,
      addCurrentWeightRecord: true,
    );

    final records = await service.loadRecordsStrict();

    expect(records, hasLength(2));
    expect(
      records.map((record) => record.id),
      containsAll(<String>[initial.id, current.id]),
    );
    expect(
      records.singleWhere((record) => record.id == current.id).weightKg,
      80,
    );
  });

  test('diferença exata de 0,005 kg é tratada como alteração', () async {
    final initial = _record('initial-original', 100, _initialDate);
    final current = _record('current', 80, _currentDate);

    await service.replaceRecords([initial, current]);

    await service.updateProfileWeights(
      initialWeight: 100,
      currentWeight: 80.005,
      addCurrentWeightRecord: true,
    );

    final records = await service.loadRecordsStrict();

    expect(records, hasLength(3));
    expect(records.first.weightKg, 80.005);
    expect(records.first.recordedAt, _fixedNow);
  });

  test('peso atual alterado cria nova pesagem quando solicitado', () async {
    final initial = _record('initial-original', 100, _initialDate);
    final current = _record('current', 80, _currentDate);

    await service.replaceRecords([initial, current]);

    await service.updateProfileWeights(
      initialWeight: 100,
      currentWeight: 78,
      addCurrentWeightRecord: true,
    );

    final records = await service.loadRecordsStrict();

    expect(records, hasLength(3));
    expect(records.first.weightKg, 78);
    expect(records.first.recordedAt, _fixedNow);
    expect(records.first.id, _fixedNow.microsecondsSinceEpoch.toString());
    expect(records.any((record) => record.id == current.id), isTrue);
    expect(
      _recordMap(records.singleWhere((record) => record.id == initial.id)),
      _recordMap(initial),
    );
  });

  test('peso atual alterado corrige registro quando solicitado', () async {
    final initial = _record('initial-original', 100, _initialDate);
    final current = _record('current', 80, _currentDate);

    await service.replaceRecords([initial, current]);

    await service.updateProfileWeights(
      initialWeight: 100,
      currentWeight: 79,
      addCurrentWeightRecord: false,
    );

    final records = await service.loadRecordsStrict();
    final correctedCurrent = records.singleWhere(
      (record) => record.id == current.id,
    );

    expect(records, hasLength(2));
    expect(correctedCurrent.weightKg, 79);
    expect(correctedCurrent.recordedAt, current.recordedAt);
    expect(records.any((record) => record.recordedAt == _fixedNow), isFalse);
    expect(
      _recordMap(records.singleWhere((record) => record.id == initial.id)),
      _recordMap(initial),
    );
  });

  test('um registro com pesos iguais continua sendo único', () async {
    final initial = _record('initial-original', 100, _initialDate);

    await service.replaceRecords([initial]);

    await service.updateProfileWeights(
      initialWeight: 95,
      currentWeight: 95.004,
      addCurrentWeightRecord: true,
    );

    final records = await service.loadRecordsStrict();

    expect(records, hasLength(1));
    expect(records.single.id, initial.id);
    expect(records.single.recordedAt, initial.recordedAt);
    expect(records.single.weightKg, 95);
  });

  test(
    'um registro e pesos diferentes respeitam correção sem data atual',
    () async {
      final initial = _record('initial-original', 100, _initialDate);

      await service.replaceRecords([initial]);

      await service.updateProfileWeights(
        initialWeight: 100,
        currentWeight: 90,
        addCurrentWeightRecord: false,
      );

      final records = await service.loadRecordsStrict();
      final preservedInitial = records.singleWhere(
        (record) => record.id == initial.id,
      );
      final current = records.singleWhere((record) => record.id != initial.id);

      expect(records, hasLength(2));
      expect(preservedInitial.recordedAt, initial.recordedAt);
      expect(current.weightKg, 90);
      expect(
        current.recordedAt,
        initial.recordedAt.add(const Duration(microseconds: 1)),
      );
      expect(current.recordedAt, isNot(_fixedNow));
    },
  );

  test(
    'um registro e pesos diferentes criam pesagem atual quando solicitado',
    () async {
      final initial = _record('initial-original', 100, _initialDate);

      await service.replaceRecords([initial]);

      await service.updateProfileWeights(
        initialWeight: 100,
        currentWeight: 90,
        addCurrentWeightRecord: true,
      );

      final records = await service.loadRecordsStrict();
      final preservedInitial = records.singleWhere(
        (record) => record.id == initial.id,
      );
      final current = records.singleWhere((record) => record.id != initial.id);

      expect(records, hasLength(2));
      expect(preservedInitial.toJson(), initial.toJson());
      expect(current.weightKg, 90);
      expect(current.recordedAt, _fixedNow);
    },
  );

  test('histórico vazio cria registros inicial e atual', () async {
    await service.updateProfileWeights(
      initialWeight: 100,
      currentWeight: 90,
      addCurrentWeightRecord: true,
    );

    final records = await service.loadRecordsStrict();
    final initial = records.singleWhere(
      (record) => record.id.startsWith('initial-'),
    );
    final current = records.singleWhere(
      (record) => !record.id.startsWith('initial-'),
    );

    expect(records, hasLength(2));
    expect(initial.weightKg, 100);
    expect(initial.recordedAt, _fixedNow);
    expect(current.weightKg, 90);
    expect(current.recordedAt.isAfter(initial.recordedAt), isTrue);
    expect(_isOrderedNewestFirst(records), isTrue);
  });

  test('histórico vazio permite inicializar uma correção', () async {
    await service.updateProfileWeights(
      initialWeight: 100,
      currentWeight: 90,
      addCurrentWeightRecord: false,
    );

    final records = await service.loadRecordsStrict();
    final initial = records.singleWhere(
      (record) => record.id.startsWith('initial-'),
    );
    final current = records.singleWhere(
      (record) => !record.id.startsWith('initial-'),
    );

    expect(records, hasLength(2));
    expect(initial.recordedAt, _fixedNow);
    expect(
      current.recordedAt,
      initial.recordedAt.add(const Duration(microseconds: 1)),
    );
  });

  test('histórico vazio e pesos iguais criam apenas o inicial', () async {
    await service.updateProfileWeights(
      initialWeight: 100,
      currentWeight: 100.004,
      addCurrentWeightRecord: false,
    );

    final records = await service.loadRecordsStrict();

    expect(records, hasLength(1));
    expect(records.single.id, startsWith('initial-'));
    expect(records.single.weightKg, 100);
  });

  test('preserva todas as pesagens intermediárias', () async {
    final initial = _record('initial-original', 110, _initialDate);
    final firstIntermediate = _record(
      'intermediate-1',
      105,
      _firstIntermediateDate,
    );
    final secondIntermediate = _record(
      'intermediate-2',
      100,
      _secondIntermediateDate,
    );
    final current = _record('current', 95, _currentDate);

    await service.replaceRecords([
      secondIntermediate,
      initial,
      current,
      firstIntermediate,
    ]);

    await service.updateProfileWeights(
      initialWeight: 108,
      currentWeight: 93,
      addCurrentWeightRecord: false,
    );

    final records = await service.loadRecordsStrict();

    expect(records, hasLength(4));
    expect(
      _recordMap(
        records.singleWhere((record) => record.id == firstIntermediate.id),
      ),
      _recordMap(firstIntermediate),
    );
    expect(
      _recordMap(
        records.singleWhere((record) => record.id == secondIntermediate.id),
      ),
      _recordMap(secondIntermediate),
    );
  });

  test('saveRecord mantém o inicial ao atingir 500 registros', () async {
    final initial = _record('initial-original', 120, _initialDate);
    final records = <WeightRecord>[
      initial,
      for (var index = 1; index <= 499; index++)
        _record(
          'weight-$index',
          120 - (index / 10),
          _initialDate.add(Duration(days: index)),
        ),
    ];

    await service.replaceRecords(records);

    final newest = _record('newest', 69, _fixedNow);
    await service.saveRecord(newest);

    final savedRecords = await service.loadRecordsStrict();
    final expectedIds = <String>{
      initial.id,
      newest.id,
      for (var index = 2; index <= 499; index++) 'weight-$index',
    };

    expect(savedRecords, hasLength(500));
    expect(savedRecords.map((record) => record.id).toSet(), expectedIds);
    expect(_isOrderedNewestFirst(savedRecords), isTrue);
  });

  test('updateProfileWeights mantém o inicial no limite de 500', () async {
    final initial = _record('initial-original', 120, _initialDate);
    final records = <WeightRecord>[
      initial,
      for (var index = 1; index <= 499; index++)
        _record(
          'weight-$index',
          120 - (index / 10),
          _initialDate.add(Duration(days: index)),
        ),
    ];

    await service.replaceRecords(records);

    await service.updateProfileWeights(
      initialWeight: 118,
      currentWeight: 65,
      addCurrentWeightRecord: true,
    );

    final savedRecords = await service.loadRecordsStrict();
    final savedInitial = savedRecords.singleWhere(
      (record) => record.id == initial.id,
    );
    final expectedIds = <String>{
      initial.id,
      _fixedNow.microsecondsSinceEpoch.toString(),
      for (var index = 2; index <= 499; index++) 'weight-$index',
    };

    expect(savedRecords, hasLength(500));
    expect(savedInitial.weightKg, 118);
    expect(savedInitial.recordedAt, initial.recordedAt);
    expect(savedRecords.first.weightKg, 65);
    expect(savedRecords.map((record) => record.id).toSet(), expectedIds);
    expect(_isOrderedNewestFirst(savedRecords), isTrue);
  });

  test('JSON corrompido impede atualização e permanece intacto', () async {
    const corruptedHistory = '{json-invalido';
    storage.values[_historyKey] = corruptedHistory;

    await expectLater(
      service.updateProfileWeights(
        initialWeight: 100,
        currentWeight: 90,
        addCurrentWeightRecord: true,
      ),
      throwsA(isA<FormatException>()),
    );

    expect(storage.values[_historyKey], corruptedHistory);
    expect(storage.writeCount, 0);
  });

  test('estrutura de registro inválida não é sobrescrita', () async {
    final invalidHistory = jsonEncode([
      {'id': '', 'weightKg': 90, 'recordedAt': _initialDate.toIso8601String()},
    ]);
    storage.values[_historyKey] = invalidHistory;

    await expectLater(
      service.updateProfileWeights(
        initialWeight: 100,
        currentWeight: 90,
        addCurrentWeightRecord: false,
      ),
      throwsA(isA<FormatException>()),
    );

    expect(storage.values[_historyKey], invalidHistory);
    expect(storage.writeCount, 0);
  });

  test('replaceRecords restaura e ordena um snapshot completo', () async {
    final initial = _record('initial-original', 110, _initialDate);
    final intermediate = _record('intermediate', 100, _firstIntermediateDate);
    final current = _record('current', 90, _currentDate);
    final snapshot = <WeightRecord>[intermediate, initial, current];

    await service.replaceRecords([_record('temporary', 75, _fixedNow)]);
    await service.replaceRecords(snapshot);

    final restoredRecords = await service.loadRecordsStrict();

    expect(
      restoredRecords.map(_recordMap).toList(),
      equals(<Map<String, dynamic>>[
        current.toJson(),
        intermediate.toJson(),
        initial.toJson(),
      ]),
    );
    expect(restoredRecords.any((record) => record.id == 'temporary'), isFalse);
    expect(_isOrderedNewestFirst(restoredRecords), isTrue);
  });

  test('replaceRecords rejeita registros inválidos antes de salvar', () async {
    await expectLater(
      service.replaceRecords([_record('', 90, _initialDate)]),
      throwsArgumentError,
    );

    expect(storage.values.containsKey(_historyKey), isFalse);
    expect(storage.writeCount, 0);
  });

  test('ausência da chave é um histórico vazio válido', () async {
    final records = await service.loadRecordsStrict();

    expect(records, isEmpty);
    expect(storage.writeCount, 0);
  });
}
