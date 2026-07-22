import 'package:flutter/material.dart';

import '../../models/workout_session_record.dart';
import '../../services/workout_history_service.dart';

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

  bool _isLoading = true;
  String? _errorMessage;

  int get _totalElapsedSeconds {
    return _records.fold<int>(0, (total, record) {
      return total + record.elapsedSeconds;
    });
  }

  double get _totalDistanceMeters {
    return _records.fold<double>(0, (total, record) {
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
        _errorMessage = 'Não foi possível carregar o histórico.';
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

  double _calculateProgress(WorkoutSessionRecord record) {
    if (record.plannedSeconds <= 0) {
      return 0;
    }

    final progress = record.elapsedSeconds / record.plannedSeconds;

    return progress.clamp(0.0, 1.0).toDouble();
  }

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(
                icon: Icons.check_circle_outline,
                label: 'Treinos',
                value: _records.length.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryItem(
                icon: Icons.timer_outlined,
                label: 'Tempo total',
                value: _formatDuration(_totalElapsedSeconds),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryItem(
                icon: Icons.route_outlined,
                label: 'Distância',
                value: _formatDistance(_totalDistanceMeters),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(WorkoutSessionRecord record) {
    final progress = _calculateProgress(record);

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
            const SizedBox(height: 6),
            Text(
              'Tempo realizado: '
              '${_formatDuration(record.elapsedSeconds)}',
            ),
            const SizedBox(height: 6),
            Text(
              'Distância: '
              '${_formatDistance(record.distanceMeters)}',
            ),
            const SizedBox(height: 6),
            Text(
              'Ritmo médio: '
              '${_formatPace(record.averagePaceSecondsPerKm)}',
            ),
            const SizedBox(height: 6),
            Text(
              'Velocidade média: '
              '${_formatSpeed(record.averageSpeedKmPerHour)}',
            ),
            const SizedBox(height: 6),
            Text(
              'Pontos válidos de GPS: '
              '${record.validGpsPointCount}',
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
          children: const [
            SizedBox(height: 100),
            Icon(Icons.history, size: 72),
            SizedBox(height: 20),
            Text(
              'Nenhum treino registrado',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            Text(
              'Os treinos aparecerão aqui depois '
              'que forem concluídos e salvos.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummary(),
          const SizedBox(height: 18),
          Text(
            'Atividades recentes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (final record in _records) _buildRecordCard(record),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de treinos'),
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
      body: _buildContent(),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }
}
