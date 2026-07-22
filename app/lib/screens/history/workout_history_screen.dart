import 'package:flutter/material.dart';

import '../../models/workout_session_record.dart';
import '../../services/workout_history_service.dart';

enum _StatisticsPeriod { sevenDays, thirtyDays, all }

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() {
    return _WorkoutHistoryScreenState();
  }
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  final WorkoutHistoryService _historyService = WorkoutHistoryService();

  List<WorkoutSessionRecord> _records = [];

  _StatisticsPeriod _selectedPeriod = _StatisticsPeriod.thirtyDays;

  bool _isLoading = true;
  String? _errorMessage;

  DateTime get _startOfToday {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day);
  }

  int? get _selectedPeriodDays {
    switch (_selectedPeriod) {
      case _StatisticsPeriod.sevenDays:
        return 7;

      case _StatisticsPeriod.thirtyDays:
        return 30;

      case _StatisticsPeriod.all:
        return null;
    }
  }

  DateTime? get _selectedPeriodStart {
    final days = _selectedPeriodDays;

    if (days == null) {
      return null;
    }

    return _startOfToday.subtract(Duration(days: days - 1));
  }

  DateTime? get _previousPeriodStart {
    final currentStart = _selectedPeriodStart;
    final days = _selectedPeriodDays;

    if (currentStart == null || days == null) {
      return null;
    }

    return currentStart.subtract(Duration(days: days));
  }

  List<WorkoutSessionRecord> get _filteredRecords {
    final startDate = _selectedPeriodStart;

    if (startDate == null) {
      return _records;
    }

    return _records.where((record) {
      return !record.completedAt.isBefore(startDate);
    }).toList();
  }

  List<WorkoutSessionRecord> get _previousPeriodRecords {
    final startDate = _previousPeriodStart;
    final endDate = _selectedPeriodStart;

    if (startDate == null || endDate == null) {
      return [];
    }

    return _records.where((record) {
      final isAtOrAfterStart = !record.completedAt.isBefore(startDate);

      final isBeforeEnd = record.completedAt.isBefore(endDate);

      return isAtOrAfterStart && isBeforeEnd;
    }).toList();
  }

  int get _totalWorkoutCount {
    return _filteredRecords.length;
  }

  int get _totalElapsedSeconds {
    return _sumElapsedSeconds(_filteredRecords);
  }

  double get _totalDistanceMeters {
    return _sumDistanceMeters(_filteredRecords);
  }

  int get _previousWorkoutCount {
    return _previousPeriodRecords.length;
  }

  int get _previousElapsedSeconds {
    return _sumElapsedSeconds(_previousPeriodRecords);
  }

  double get _previousDistanceMeters {
    return _sumDistanceMeters(_previousPeriodRecords);
  }

  int get _workoutsThisWeek {
    final now = DateTime.now();

    final startOfToday = DateTime(now.year, now.month, now.day);

    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));

    return _records.where((record) {
      return !record.completedAt.isBefore(startOfWeek);
    }).length;
  }

  double? get _averageSpeedKmPerHour {
    if (_totalElapsedSeconds <= 0 || _totalDistanceMeters <= 0) {
      return null;
    }

    final distanceKilometers = _totalDistanceMeters / 1000;

    final elapsedHours = _totalElapsedSeconds / 3600;

    return distanceKilometers / elapsedHours;
  }

  int? get _averagePaceSecondsPerKm {
    if (_totalElapsedSeconds <= 0 || _totalDistanceMeters <= 0) {
      return null;
    }

    final distanceKilometers = _totalDistanceMeters / 1000;

    return (_totalElapsedSeconds / distanceKilometers).round();
  }

  WorkoutSessionRecord? get _longestDistanceRecord {
    final recordsWithDistance = _filteredRecords.where((record) {
      return record.distanceMeters > 0;
    }).toList();

    if (recordsWithDistance.isEmpty) {
      return null;
    }

    recordsWithDistance.sort((first, second) {
      return second.distanceMeters.compareTo(first.distanceMeters);
    });

    return recordsWithDistance.first;
  }

  WorkoutSessionRecord? get _longestDurationRecord {
    final recordsWithDuration = _filteredRecords.where((record) {
      return record.elapsedSeconds > 0;
    }).toList();

    if (recordsWithDuration.isEmpty) {
      return null;
    }

    recordsWithDuration.sort((first, second) {
      return second.elapsedSeconds.compareTo(first.elapsedSeconds);
    });

    return recordsWithDuration.first;
  }

  int _sumElapsedSeconds(List<WorkoutSessionRecord> records) {
    return records.fold<int>(0, (total, record) {
      return total + record.elapsedSeconds;
    });
  }

  double _sumDistanceMeters(List<WorkoutSessionRecord> records) {
    return records.fold<double>(0, (total, record) {
      return total + record.distanceMeters;
    });
  }

  @override
  void initState() {
    super.initState();

    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _historyService.loadRecords();

      if (!mounted) {
        return;
      }

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar suas estatísticas.';
      });
    }
  }

  Future<void> _deleteHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Apagar histórico?'),
          content: const Text(
            'Todos os registros de treinos concluídos '
            'serão apagados. O progresso dos planos '
            'não será alterado.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Apagar tudo'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _historyService.deleteAllRecords();

      if (!mounted) {
        return;
      }

      setState(() {
        _records = [];
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Histórico apagado.')));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível apagar o histórico.')),
      );
    }
  }

  String _formatDuration(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;

    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final seconds = safeSeconds % 60;

    final minutesText = minutes.toString().padLeft(2, '0');

    final secondsText = seconds.toString().padLeft(2, '0');

    if (hours == 0) {
      return '$minutesText:$secondsText';
    }

    final hoursText = hours.toString().padLeft(2, '0');

    return '$hoursText:$minutesText:$secondsText';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  String _formatPace(int? secondsPerKilometer) {
    if (secondsPerKilometer == null) {
      return '--';
    }

    final minutes = secondsPerKilometer ~/ 60;

    final seconds = secondsPerKilometer % 60;

    return '$minutes:'
        '${seconds.toString().padLeft(2, '0')} min/km';
  }

  String _formatSpeed(double? kilometersPerHour) {
    if (kilometersPerHour == null) {
      return '--';
    }

    return '${kilometersPerHour.toStringAsFixed(2)} km/h';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year às $hour:$minute';
  }

  String _formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month';
  }

  double _calculateWorkoutProgress(WorkoutSessionRecord record) {
    if (record.plannedSeconds <= 0) {
      return 0;
    }

    final progress = record.elapsedSeconds / record.plannedSeconds;

    return progress.clamp(0.0, 1.0).toDouble();
  }

  String _periodLabel(_StatisticsPeriod period) {
    switch (period) {
      case _StatisticsPeriod.sevenDays:
        return '7 dias';

      case _StatisticsPeriod.thirtyDays:
        return '30 dias';

      case _StatisticsPeriod.all:
        return 'Todo período';
    }
  }

  String get _previousPeriodLabel {
    switch (_selectedPeriod) {
      case _StatisticsPeriod.sevenDays:
        return '7 dias anteriores';

      case _StatisticsPeriod.thirtyDays:
        return '30 dias anteriores';

      case _StatisticsPeriod.all:
        return '';
    }
  }

  String _formatComparison(num currentValue, num previousValue) {
    if (previousValue == 0) {
      if (currentValue == 0) {
        return '0%';
      }

      return 'Novo';
    }

    final percentage = ((currentValue - previousValue) / previousValue) * 100;

    if (percentage.abs() < 0.5) {
      return '0%';
    }

    final sign = percentage > 0 ? '+' : '';

    return '$sign${percentage.toStringAsFixed(0)}%';
  }

  int _comparisonDirection(num currentValue, num previousValue) {
    if (currentValue > previousValue) {
      return 1;
    }

    if (currentValue < previousValue) {
      return -1;
    }

    return 0;
  }

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Período', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final period in _StatisticsPeriod.values)
              ChoiceChip(
                label: Text(_periodLabel(period)),
                selected: _selectedPeriod == period,
                onSelected: (selected) {
                  if (!selected) {
                    return;
                  }

                  setState(() {
                    _selectedPeriod = period;
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _StatisticCard(
          icon: Icons.check_circle_outline,
          label: 'Treinos',
          value: _totalWorkoutCount.toString(),
        ),
        _StatisticCard(
          icon: Icons.timer_outlined,
          label: 'Tempo total',
          value: _formatDuration(_totalElapsedSeconds),
        ),
        _StatisticCard(
          icon: Icons.route_outlined,
          label: 'Distância',
          value: _formatDistance(_totalDistanceMeters),
        ),
        _StatisticCard(
          icon: Icons.speed_outlined,
          label: 'Ritmo médio',
          value: _formatPace(_averagePaceSecondsPerKm),
        ),
        _StatisticCard(
          icon: Icons.trending_up,
          label: 'Velocidade média',
          value: _formatSpeed(_averageSpeedKmPerHour),
        ),
        _StatisticCard(
          icon: Icons.calendar_today_outlined,
          label: 'Nesta semana',
          value: '$_workoutsThisWeek treinos',
        ),
      ],
    );
  }

  Widget _buildComparisonCard() {
    if (_selectedPeriod == _StatisticsPeriod.all) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.compare_arrows, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Selecione 7 ou 30 dias para '
                  'comparar com o período anterior.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Comparação',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Em relação aos '
              '$_previousPeriodLabel.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            _ComparisonRow(
              label: 'Treinos',
              currentValue: _totalWorkoutCount.toString(),
              previousValue: _previousWorkoutCount.toString(),
              changeText: _formatComparison(
                _totalWorkoutCount,
                _previousWorkoutCount,
              ),
              direction: _comparisonDirection(
                _totalWorkoutCount,
                _previousWorkoutCount,
              ),
            ),
            const Divider(height: 28),
            _ComparisonRow(
              label: 'Tempo total',
              currentValue: _formatDuration(_totalElapsedSeconds),
              previousValue: _formatDuration(_previousElapsedSeconds),
              changeText: _formatComparison(
                _totalElapsedSeconds,
                _previousElapsedSeconds,
              ),
              direction: _comparisonDirection(
                _totalElapsedSeconds,
                _previousElapsedSeconds,
              ),
            ),
            const Divider(height: 28),
            _ComparisonRow(
              label: 'Distância',
              currentValue: _formatDistance(_totalDistanceMeters),
              previousValue: _formatDistance(_previousDistanceMeters),
              changeText: _formatComparison(
                _totalDistanceMeters,
                _previousDistanceMeters,
              ),
              direction: _comparisonDirection(
                _totalDistanceMeters,
                _previousDistanceMeters,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordHighlight({
    required IconData icon,
    required String title,
    required WorkoutSessionRecord? record,
    required String Function(WorkoutSessionRecord record) valueBuilder,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: record == null
          ? Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(child: Text('$title: ainda sem dados')),
              ],
            )
          : Row(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        valueBuilder(record),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${record.workoutTitle} • '
                        '${_formatShortDate(record.completedAt)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRecordsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined),
                const SizedBox(width: 10),
                Text(
                  'Recordes do período',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecordHighlight(
              icon: Icons.route_outlined,
              title: 'Maior distância',
              record: _longestDistanceRecord,
              valueBuilder: (record) {
                return _formatDistance(record.distanceMeters);
              },
            ),
            const SizedBox(height: 12),
            _buildRecordHighlight(
              icon: Icons.timer_outlined,
              title: 'Maior duração',
              record: _longestDurationRecord,
              valueBuilder: (record) {
                return _formatDuration(record.elapsedSeconds);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutSessionRecord record) {
    final progress = _calculateWorkoutProgress(record);

    final percentage = (progress * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_walk, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record.workoutTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_formatDate(record.completedAt)),
            const SizedBox(height: 8),
            _RecordMetric(
              label: 'Tempo',
              value: _formatDuration(record.elapsedSeconds),
            ),
            const SizedBox(height: 6),
            _RecordMetric(
              label: 'Distância',
              value: _formatDistance(record.distanceMeters),
            ),
            const SizedBox(height: 6),
            _RecordMetric(
              label: 'Ritmo médio',
              value: _formatPace(record.averagePaceSecondsPerKm),
            ),
            const SizedBox(height: 6),
            _RecordMetric(
              label: 'Velocidade média',
              value: _formatSpeed(record.averageSpeedKmPerHour),
            ),
            const SizedBox(height: 6),
            Text(
              record.completedManually
                  ? 'Conclusão manual'
                  : 'Conclusão automática',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$percentage%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPeriod() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.event_busy_outlined, size: 64),
          const SizedBox(height: 18),
          Text(
            'Nenhum treino neste período',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecione outro período ou conclua '
            'um novo treino.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final filteredRecords = _filteredRecords;

    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Sua evolução',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Acompanhe seus resultados e sua '
            'frequência de treinos.',
          ),
          const SizedBox(height: 22),
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          _buildStatisticsGrid(),
          const SizedBox(height: 20),
          _buildComparisonCard(),
          const SizedBox(height: 20),
          _buildRecordsCard(),
          const SizedBox(height: 28),
          Text(
            'Atividades do período',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (filteredRecords.isEmpty)
            _buildEmptyPeriod()
          else
            for (final record in filteredRecords) _buildWorkoutCard(record),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadRecords,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_records.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRecords,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 100),
            const Icon(Icons.insights_outlined, size: 72),
            const SizedBox(height: 20),
            Text(
              'Nenhuma estatística disponível',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'Conclua e salve um treino para '
              'começar a acompanhar sua evolução.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return _buildDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolução e estatísticas'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadRecords,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
          if (_records.isNotEmpty)
            IconButton(
              onPressed: _deleteHistory,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Apagar histórico',
            ),
        ],
      ),
      body: SafeArea(child: _buildContent()),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatisticCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String currentValue;
  final String previousValue;
  final String changeText;
  final int direction;

  const _ComparisonRow({
    required this.label,
    required this.currentValue,
    required this.previousValue,
    required this.changeText,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final IconData trendIcon;
    final Color trendColor;

    if (direction > 0) {
      trendIcon = Icons.arrow_upward;
      trendColor = colorScheme.primary;
    } else if (direction < 0) {
      trendIcon = Icons.arrow_downward;
      trendColor = colorScheme.error;
    } else {
      trendIcon = Icons.horizontal_rule;
      trendColor = colorScheme.onSurfaceVariant;
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text('Atual: $currentValue'),
              Text(
                'Anterior: $previousValue',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(trendIcon, size: 20, color: trendColor),
            const SizedBox(width: 4),
            Text(
              changeText,
              style: TextStyle(color: trendColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecordMetric extends StatelessWidget {
  final String label;
  final String value;

  const _RecordMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}
