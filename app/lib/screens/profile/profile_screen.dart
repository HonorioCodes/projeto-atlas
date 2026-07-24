import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../models/weight_record.dart';
import '../../services/user_storage_service.dart';
import '../../services/weight_history_service.dart';

class ProfileScreen extends StatefulWidget {
  final String selectedPlanTitle;

  const ProfileScreen({super.key, required this.selectedPlanTitle});

  @override
  State<ProfileScreen> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserStorageService _userStorageService = UserStorageService();

  final WeightHistoryService _weightHistoryService = WeightHistoryService();

  UserModel? _user;
  List<WeightRecord> _weightRecords = [];

  bool _isLoading = true;
  String? _errorMessage;

  double get _initialWeight {
    if (_weightRecords.isNotEmpty) {
      return _weightRecords.last.weightKg;
    }

    return _user?.currentWeight ?? 0;
  }

  double get _currentWeight {
    if (_weightRecords.isNotEmpty) {
      return _weightRecords.first.weightKg;
    }

    return _user?.currentWeight ?? 0;
  }

  double get _currentBmi {
    final user = _user;

    if (user == null) {
      return 0;
    }

    return user.calculateBmiForWeight(_currentWeight);
  }

  String get _profileInitial {
    final name = _user?.name.trim() ?? '';

    if (name.isEmpty) {
      return '?';
    }

    return name.substring(0, 1).toUpperCase();
  }

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
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

      final weightRecords = await _weightHistoryService.loadRecords();

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;
        _weightRecords = weightRecords;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar seu perfil.';
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatWeight(double? weight) {
    if (weight == null || weight <= 0) {
      return 'Não informado';
    }

    return '${weight.toStringAsFixed(1).replaceAll('.', ',')} kg';
  }

  String _formatHeight(UserModel user) {
    if (!user.hasValidHeight) {
      return 'Não cadastrada';
    }

    final heightCm = user.heightInMeters * 100;

    return '${heightCm.toStringAsFixed(0)} cm';
  }

  String _formatBmi(double bmi) {
    if (bmi <= 0) {
      return 'Não disponível';
    }

    return bmi.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _formatSex(String sex) {
    switch (sex) {
      case 'masculino':
        return 'Masculino';

      case 'feminino':
        return 'Feminino';

      case 'prefiro_nao_informar':
        return 'Prefiro não informar';

      default:
        return 'Não informado';
    }
  }

  String _formatGoal(String goal) {
    switch (goal) {
      case 'emagrecer':
        return 'Emagrecer';

      case 'condicionamento':
        return 'Melhorar condicionamento';

      case 'correr':
        return 'Começar a correr';

      case 'saude':
        return 'Manter a saúde';

      default:
        return 'Não informado';
    }
  }

  String _bmiClassification(UserModel user) {
    if (!user.hasValidHeight || _currentBmi <= 0) {
      return 'IMC indisponível';
    }

    return user.classifyBmi(_currentBmi);
  }

  Widget _buildProfileHeader(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              child: Text(
                _profileInitial,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isEmpty ? 'Usuário' : user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.age} anos',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatGoal(user.mainGoal),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(UserModel user) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _ProfileSummaryCard(
          icon: Icons.monitor_weight_outlined,
          label: 'Peso atual',
          value: _formatWeight(_currentWeight),
        ),
        _ProfileSummaryCard(
          icon: Icons.flag_outlined,
          label: 'Meta de peso',
          value: _formatWeight(user.targetWeight),
        ),
        _ProfileSummaryCard(
          icon: Icons.health_and_safety_outlined,
          label: 'IMC atual',
          value: _formatBmi(_currentBmi),
          description: _bmiClassification(user),
        ),
        _ProfileSummaryCard(
          icon: Icons.directions_walk_outlined,
          label: 'Plano atual',
          value: widget.selectedPlanTitle,
        ),
      ],
    );
  }

  Widget _buildPersonalDataSection(UserModel user) {
    return _ProfileSection(
      icon: Icons.person_outline,
      title: 'Dados pessoais',
      children: [
        _ProfileInformationRow(
          label: 'Nome',
          value: user.name.isEmpty ? 'Não informado' : user.name,
        ),
        _ProfileInformationRow(
          label: 'Data de nascimento',
          value: _formatDate(user.birthDate),
        ),
        _ProfileInformationRow(label: 'Idade', value: '${user.age} anos'),
        _ProfileInformationRow(
          label: 'Sexo',
          value: _formatSex(user.sex),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildPhysicalDataSection(UserModel user) {
    return _ProfileSection(
      icon: Icons.accessibility_new_outlined,
      title: 'Dados físicos',
      children: [
        _ProfileInformationRow(label: 'Altura', value: _formatHeight(user)),
        _ProfileInformationRow(
          label: 'Peso inicial',
          value: _formatWeight(_initialWeight),
        ),
        _ProfileInformationRow(
          label: 'Peso atual',
          value: _formatWeight(_currentWeight),
        ),
        _ProfileInformationRow(
          label: 'Meta de peso',
          value: _formatWeight(user.targetWeight),
        ),
        _ProfileInformationRow(label: 'IMC', value: _formatBmi(_currentBmi)),
        _ProfileInformationRow(
          label: 'Classificação',
          value: _bmiClassification(user),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildGoalsSection(UserModel user) {
    return _ProfileSection(
      icon: Icons.track_changes_outlined,
      title: 'Objetivos e plano',
      children: [
        _ProfileInformationRow(
          label: 'Objetivo principal',
          value: _formatGoal(user.mainGoal),
        ),
        _ProfileInformationRow(
          label: 'Plano selecionado',
          value: widget.selectedPlanTitle,
          showDivider: false,
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
              FilledButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final user = _user;

    if (user == null) {
      return const Center(child: Text('Perfil não encontrado.'));
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Meu perfil', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text(
            'Confira seus dados pessoais, '
            'medidas e objetivos.',
          ),
          const SizedBox(height: 20),
          _buildProfileHeader(user),
          const SizedBox(height: 16),
          _buildSummaryGrid(user),
          const SizedBox(height: 20),
          _buildPersonalDataSection(user),
          const SizedBox(height: 16),
          _buildPhysicalDataSection(user),
          const SizedBox(height: 16),
          _buildGoalsSection(user),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'A edição do peso inicial, '
                      'meta e demais informações '
                      'será disponibilizada na '
                      'próxima etapa.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadProfile,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar perfil',
          ),
        ],
      ),
      body: SafeArea(child: _buildContent()),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? description;

  const _ProfileSummaryCard({
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
            Icon(icon, size: 29, color: Theme.of(context).colorScheme.primary),
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

class _ProfileSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _ProfileSection({
    required this.icon,
    required this.title,
    required this.children,
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
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileInformationRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _ProfileInformationRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
