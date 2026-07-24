import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/training_settings.dart';
import '../../models/weight_record.dart';
import '../../models/workout_session_record.dart';
import '../../services/training_settings_service.dart';
import '../../services/user_storage_service.dart';
import '../../services/weight_history_service.dart';
import '../../services/workout_history_service.dart';
import '../../utils/distance_formatter.dart';

class ProgressChartsScreen extends StatefulWidget {
  const ProgressChartsScreen({super.key});

  @override
  State<ProgressChartsScreen> createState() {
    return _ProgressChartsScreenState();
  }
}

class _ProgressChartsScreenState extends State<ProgressChartsScreen> {
  final WorkoutHistoryService _workoutHistoryService = WorkoutHistoryService();

  final WeightHistoryService _weightHistoryService = WeightHistoryService();

  final UserStorageService _userStorageService = UserStorageService();
  final TrainingSettingsService _settingsService = TrainingSettingsService();

  List<WorkoutSessionRecord> _workouts = [];
  List<WeightRecord> _weightRecords = [];
  TrainingSettings _settings = TrainingSettings.defaults;

  int _selectedWeeks = 8;

  bool _isLoading = true;
  String? _errorMessage;

  List<WeightRecord> get _orderedWeightRecords {
    final records = List<WeightRecord>.from(_weightRecords);

    records.sort((first, second) {
      return first.recordedAt.compareTo(second.recordedAt);
    });

    const maximumVisibleRecords = 12;

    if (records.length <= maximumVisibleRecords) {
      return records;
    }

    return records.sublist(records.length - maximumVisibleRecords);
  }

  List<_WeeklySummary> get _weeklySummaries {
    final currentWeekStart = _startOfWeek(DateTime.now());

    return List<_WeeklySummary>.generate(_selectedWeeks, (index) {
      final weeksAgo = _selectedWeeks - index - 1;

      final weekStart = currentWeekStart.subtract(Duration(days: weeksAgo * 7));

      final weekEnd = weekStart.add(const Duration(days: 7));

      final records = _workouts.where((record) {
        final date = record.completedAt;

        return !date.isBefore(weekStart) && date.isBefore(weekEnd);
      }).toList();

      final elapsedSeconds = records.fold<int>(0, (total, record) {
        return total + record.elapsedSeconds;
      });

      final distanceMeters = records.fold<double>(0, (total, record) {
        return total + record.distanceMeters;
      });

      return _WeeklySummary(
        weekStart: weekStart,
        workoutCount: records.length,
        elapsedSeconds: elapsedSeconds,
        distanceMeters: distanceMeters,
      );
    });
  }

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _userStorageService.loadUser();

      if (user != null) {
        await _weightHistoryService.ensureInitialRecord(user.currentWeight);
      }

      final workouts = await _workoutHistoryService.loadRecords();

      final weights = await _weightHistoryService.loadRecords();
      final settings = await _loadSettingsSafely();

      if (!mounted) {
        return;
      }

      setState(() {
        _workouts = workouts;
        _weightRecords = weights;
        _settings = settings;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar os gráficos.';
      });
    }
  }

  Future<TrainingSettings> _loadSettingsSafely() async {
    try {
      return await _settingsService.loadSettings();
    } catch (_) {
      return TrainingSettings.defaults;
    }
  }

  DateTime _startOfWeek(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    return normalizedDate.subtract(Duration(days: normalizedDate.weekday - 1));
  }

  String _formatWeight(double weight) {
    return '${weight.toStringAsFixed(1).replaceAll('.', ',')} kg';
  }

  String _formatDistance(double meters) {
    return formatDistanceForDisplay(meters, _settings.distanceDisplayUnit);
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) {
      return '0 min';
    }

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      if (minutes == 0) {
        return '${hours}h';
      }

      return '${hours}h ${minutes}min';
    }

    final roundedMinutes = math.max(1, (totalSeconds / 60).round());

    return '$roundedMinutes min';
  }

  String _formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month';
  }

  double _maximumValue(List<double> values) {
    var maximum = 0.0;

    for (final value in values) {
      if (value > maximum) {
        maximum = value;
      }
    }

    return maximum;
  }

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Período dos gráficos semanais',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final weeks in const [4, 8, 12])
              ChoiceChip(
                label: Text('$weeks semanas'),
                selected: _selectedWeeks == weeks,
                onSelected: (selected) {
                  if (!selected) {
                    return;
                  }

                  setState(() {
                    _selectedWeeks = weeks;
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightChart() {
    final records = _orderedWeightRecords;

    if (records.length < 2) {
      return _ChartCard(
        icon: Icons.monitor_weight_outlined,
        title: 'Evolução do peso',
        subtitle: 'São necessárias pelo menos duas pesagens.',
        child: const _ChartEmptyState(
          icon: Icons.show_chart,
          message: 'Registre uma nova pesagem para visualizar a evolução.',
        ),
      );
    }

    final spots = <FlSpot>[];

    for (var index = 0; index < records.length; index++) {
      spots.add(FlSpot(index.toDouble(), records[index].weightKg));
    }

    final weights = records.map((record) => record.weightKg).toList();

    final minimumWeight = weights.reduce(math.min);

    final maximumWeight = weights.reduce(math.max);

    final weightRange = maximumWeight - minimumWeight;

    final verticalPadding = weightRange <= 0
        ? 1.0
        : math.max(1.0, weightRange * 0.2);

    final firstWeight = records.first.weightKg;

    final lastWeight = records.last.weightKg;

    final difference = lastWeight - firstWeight;

    final String changeText;

    if (difference < -0.05) {
      changeText = 'Redução de ${_formatWeight(difference.abs())}';
    } else if (difference > 0.05) {
      changeText = 'Aumento de ${_formatWeight(difference)}';
    } else {
      changeText = 'Peso estável';
    }

    final colorScheme = Theme.of(context).colorScheme;

    return _ChartCard(
      icon: Icons.monitor_weight_outlined,
      title: 'Evolução do peso',
      subtitle: '${records.length} pesagens mais recentes',
      headerValue: changeText,
      child: Column(
        children: [
          SizedBox(
            height: 230,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (records.length - 1).toDouble(),
                minY: minimumWeight - verticalPadding,
                maxY: maximumWeight + verticalPadding,
                titlesData: const FlTitlesData(show: false),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    barWidth: 3,
                    color: colorScheme.primary,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ChartBoundaryLabel(
                  label: _formatShortDate(records.first.recordedAt),
                  value: _formatWeight(records.first.weightKg),
                  alignment: CrossAxisAlignment.start,
                ),
              ),
              Expanded(
                child: _ChartBoundaryLabel(
                  label: _formatShortDate(records.last.recordedAt),
                  value: _formatWeight(records.last.weightKg),
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart({
    required IconData icon,
    required String title,
    required String subtitle,
    required double Function(_WeeklySummary summary) valueGetter,
    required String Function(double value) valueFormatter,
  }) {
    final summaries = _weeklySummaries;

    final values = summaries.map(valueGetter).toList();

    final maximum = _maximumValue(values);

    final chartMaximum = maximum <= 0 ? 1.0 : maximum * 1.2;

    final total = values.fold<double>(0, (sum, value) => sum + value);

    final latestValue = values.isEmpty ? 0.0 : values.last;

    final colorScheme = Theme.of(context).colorScheme;

    final barWidth = switch (_selectedWeeks) {
      4 => 28.0,
      8 => 18.0,
      _ => 12.0,
    };

    return _ChartCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      headerValue: 'Total: ${valueFormatter(total)}',
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: chartMaximum,
                alignment: BarChartAlignment.spaceAround,
                titlesData: const FlTitlesData(show: false),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barTouchData: const BarTouchData(enabled: false),
                barGroups: [
                  for (var index = 0; index < summaries.length; index++)
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: values[index],
                          width: barWidth,
                          color: colorScheme.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Semana de '
                  '${_formatShortDate(summaries.first.weekStart)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                'Última semana: '
                '${valueFormatter(latestValue)}',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCharts() {
    if (_workouts.isEmpty) {
      return const _ChartEmptyState(
        icon: Icons.directions_walk,
        message: 'Conclua e salve um treino para gerar os gráficos semanais.',
      );
    }

    return Column(
      children: [
        _buildWeeklyBarChart(
          icon: Icons.route_outlined,
          title: 'Distância semanal',
          subtitle: 'Distância acumulada em cada semana',
          valueGetter: (summary) {
            return summary.distanceMeters;
          },
          valueFormatter: _formatDistance,
        ),
        const SizedBox(height: 16),
        _buildWeeklyBarChart(
          icon: Icons.timer_outlined,
          title: 'Duração semanal',
          subtitle: 'Tempo total de atividades por semana',
          valueGetter: (summary) {
            return summary.elapsedSeconds.toDouble();
          },
          valueFormatter: (value) {
            return _formatDuration(value.round());
          },
        ),
        const SizedBox(height: 16),
        _buildWeeklyBarChart(
          icon: Icons.calendar_view_week_outlined,
          title: 'Frequência semanal',
          subtitle: 'Quantidade de treinos concluídos por semana',
          valueGetter: (summary) {
            return summary.workoutCount.toDouble();
          },
          valueFormatter: (value) {
            final count = value.round();

            return count == 1 ? '1 treino' : '$count treinos';
          },
        ),
      ],
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
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Gráficos de evolução',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Visualize tendências de peso, distância, '
            'duração e frequência.',
          ),
          const SizedBox(height: 22),
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          _buildWeightChart(),
          const SizedBox(height: 16),
          _buildWorkoutCharts(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráficos de evolução'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: SafeArea(child: _buildContent()),
    );
  }
}

class _WeeklySummary {
  final DateTime weekStart;
  final int workoutCount;
  final int elapsedSeconds;
  final double distanceMeters;

  const _WeeklySummary({
    required this.weekStart,
    required this.workoutCount,
    required this.elapsedSeconds,
    required this.distanceMeters,
  });
}

class _ChartCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? headerValue;
  final Widget child;

  const _ChartCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.headerValue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            if (headerValue != null) ...[
              const SizedBox(height: 8),
              Text(headerValue!, style: Theme.of(context).textTheme.labelLarge),
            ],
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _ChartEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
      child: Column(
        children: [
          Icon(
            icon,
            size: 56,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ChartBoundaryLabel extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment alignment;

  const _ChartBoundaryLabel({
    required this.label,
    required this.value,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(value, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
