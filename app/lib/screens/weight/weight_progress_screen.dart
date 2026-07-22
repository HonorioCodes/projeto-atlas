import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_model.dart';
import '../../models/weight_record.dart';
import '../../services/user_storage_service.dart';
import '../../services/weight_history_service.dart';

class WeightProgressScreen extends StatefulWidget {
  const WeightProgressScreen({super.key});

  @override
  State<WeightProgressScreen> createState() {
    return _WeightProgressScreenState();
  }
}

class _WeightProgressScreenState extends State<WeightProgressScreen> {
  final UserStorageService _userStorageService = UserStorageService();

  final WeightHistoryService _weightHistoryService = WeightHistoryService();

  UserModel? _user;
  List<WeightRecord> _records = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  double get _initialWeight {
    if (_records.isNotEmpty) {
      return _records.last.weightKg;
    }

    return _user?.currentWeight ?? 0;
  }

  double get _currentWeight {
    if (_records.isNotEmpty) {
      return _records.first.weightKg;
    }

    return _user?.currentWeight ?? 0;
  }

  double get _weightChange {
    return _initialWeight - _currentWeight;
  }

  double get _currentBmi {
    final height = _user?.height ?? 0;

    if (height <= 0 || _currentWeight <= 0) {
      return 0;
    }

    final heightInMeters = height / 100;

    return _currentWeight / (heightInMeters * heightInMeters);
  }

  String get _bmiClassification {
    final value = _currentBmi;

    if (value <= 0) {
      return 'Sem dados';
    }

    if (value < 18.5) {
      return 'Abaixo do peso';
    }

    if (value < 25) {
      return 'Peso normal';
    }

    if (value < 30) {
      return 'Sobrepeso';
    }

    if (value < 35) {
      return 'Obesidade grau I';
    }

    if (value < 40) {
      return 'Obesidade grau II';
    }

    return 'Obesidade grau III';
  }

  double? get _goalProgress {
    final targetWeight = _user?.targetWeight;

    if (targetWeight == null || _initialWeight <= 0) {
      return null;
    }

    final totalChange = _initialWeight - targetWeight;

    if (totalChange.abs() < 0.01) {
      return 1;
    }

    final achievedChange = _initialWeight - _currentWeight;

    return (achievedChange / totalChange).clamp(0.0, 1.0).toDouble();
  }

  double? get _remainingToTarget {
    final targetWeight = _user?.targetWeight;

    if (targetWeight == null) {
      return null;
    }

    if (_initialWeight >= targetWeight) {
      final remaining = _currentWeight - targetWeight;

      return remaining > 0 ? remaining : 0;
    }

    final remaining = targetWeight - _currentWeight;

    return remaining > 0 ? remaining : 0;
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

      if (user == null) {
        throw StateError('Usuário não encontrado.');
      }

      await _weightHistoryService.ensureInitialRecord(user.currentWeight);

      final records = await _weightHistoryService.loadRecords();

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;
        _records = records;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Não foi possível carregar '
            'a evolução do peso.';
      });
    }
  }

  Future<void> _registerWeight() async {
    if (_isSaving) {
      return;
    }

    final weight = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return _WeightEntryDialog(currentWeight: _currentWeight);
      },
    );

    if (!mounted || weight == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final recordedAt = DateTime.now();

      final record = WeightRecord(
        id: recordedAt.microsecondsSinceEpoch.toString(),
        weightKg: weight,
        recordedAt: recordedAt,
      );

      await _weightHistoryService.saveRecord(record);

      final currentUser = _user;

      if (currentUser == null) {
        throw StateError('Usuário não encontrado.');
      }

      final updatedUser = currentUser.copyWith(currentWeight: weight);

      await _userStorageService.saveUser(updatedUser);

      final records = await _weightHistoryService.loadRecords();

      if (!mounted) {
        return;
      }

      setState(() {
        _user = updatedUser;
        _records = records;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso registrado com sucesso.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível registrar o peso.')),
      );
    }
  }

  String _formatWeight(double weight) {
    return '${weight.toStringAsFixed(1).replaceAll('.', ',')} kg';
  }

  String _formatBmi(double bmi) {
    if (bmi <= 0) {
      return '--';
    }

    return bmi.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year às $hour:$minute';
  }

  String get _changeLabel {
    if (_weightChange > 0.05) {
      return 'Peso eliminado';
    }

    if (_weightChange < -0.05) {
      return 'Peso aumentado';
    }

    return 'Variação';
  }

  String get _changeValue {
    if (_weightChange.abs() <= 0.05) {
      return '0,0 kg';
    }

    return _formatWeight(_weightChange.abs());
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _WeightSummaryCard(
          icon: Icons.monitor_weight_outlined,
          label: 'Peso atual',
          value: _formatWeight(_currentWeight),
        ),
        _WeightSummaryCard(
          icon: Icons.flag_outlined,
          label: 'Peso inicial',
          value: _formatWeight(_initialWeight),
        ),
        _WeightSummaryCard(
          icon: _weightChange >= 0 ? Icons.trending_down : Icons.trending_up,
          label: _changeLabel,
          value: _changeValue,
        ),
        _WeightSummaryCard(
          icon: Icons.health_and_safety_outlined,
          label: 'IMC atual',
          value: _formatBmi(_currentBmi),
          description: _bmiClassification,
        ),
      ],
    );
  }

  Widget _buildTargetCard() {
    final targetWeight = _user?.targetWeight;

    if (targetWeight == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.flag_outlined, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Nenhuma meta de peso foi '
                  'definida no cadastro.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final progress = _goalProgress ?? 0;

    final remaining = _remainingToTarget ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Meta de peso',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  _formatWeight(targetWeight),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 10),
            Text(
              remaining <= 0.05
                  ? 'Meta atingida.'
                  : 'Faltam '
                        '${_formatWeight(remaining)} '
                        'para alcançar a meta.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico de pesagens',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < _records.length; index++)
          _WeightRecordCard(
            record: _records[index],
            dateText: _formatDate(_records[index].recordedAt),
            weightText: _formatWeight(_records[index].weightKg),
            isInitial: index == _records.length - 1,
            isCurrent: index == 0,
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
              const Icon(Icons.error_outline, size: 60),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
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
            'Evolução do peso',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Registre suas pesagens e acompanhe '
            'sua evolução até a meta.',
          ),
          const SizedBox(height: 22),
          _buildSummaryGrid(),
          const SizedBox(height: 20),
          _buildTargetCard(),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSaving ? null : _registerWeight,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_chart),
            label: Text(_isSaving ? 'Salvando...' : 'Registrar novo peso'),
          ),
          const SizedBox(height: 28),
          _buildHistory(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peso corporal'),
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

class _WeightSummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? description;

  const _WeightSummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeightRecordCard extends StatelessWidget {
  final WeightRecord record;
  final String dateText;
  final String weightText;
  final bool isInitial;
  final bool isCurrent;

  const _WeightRecordCard({
    required this.record,
    required this.dateText,
    required this.weightText,
    required this.isInitial,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(isCurrent ? Icons.monitor_weight : Icons.history),
        ),
        title: Text(weightText, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(dateText),
        trailing: isCurrent
            ? const Chip(label: Text('Atual'))
            : isInitial
            ? const Chip(label: Text('Inicial'))
            : null,
      ),
    );
  }
}

class _WeightEntryDialog extends StatefulWidget {
  final double currentWeight;

  const _WeightEntryDialog({required this.currentWeight});

  @override
  State<_WeightEntryDialog> createState() {
    return _WeightEntryDialogState();
  }
}

class _WeightEntryDialogState extends State<_WeightEntryDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.currentWeight > 0
          ? widget.currentWeight.toStringAsFixed(1).replaceAll('.', ',')
          : '',
    );

    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  double? _parseWeight(String value) {
    final normalized = value.trim().replaceAll(',', '.');

    return double.tryParse(normalized);
  }

  String? _validateWeight(String? value) {
    final weight = _parseWeight(value ?? '');

    if (weight == null) {
      return 'Digite um peso válido.';
    }

    if (weight < 30 || weight > 350) {
      return 'Digite um peso entre 30 e 350 kg.';
    }

    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final weight = _parseWeight(_controller.text);

    if (weight == null) {
      return;
    }

    Navigator.of(context).pop(weight);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar peso'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Peso atual',
            suffixText: 'kg',
            hintText: 'Ex.: 125,5',
          ),
          validator: _validateWeight,
          onFieldSubmitted: (_) {
            _submit();
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}
