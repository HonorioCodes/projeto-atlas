import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_model.dart';
import '../../models/weight_record.dart';
import '../../services/user_storage_service.dart';
import '../../services/weight_history_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  final double initialWeight;
  final double currentWeight;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.initialWeight,
    required this.currentWeight,
  });

  @override
  State<EditProfileScreen> createState() {
    return _EditProfileScreenState();
  }
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final UserStorageService _userStorageService = UserStorageService();

  final WeightHistoryService _weightHistoryService = WeightHistoryService();

  late final TextEditingController _nameController;

  late final TextEditingController _heightController;

  late final TextEditingController _initialWeightController;

  late final TextEditingController _currentWeightController;

  late final TextEditingController _targetWeightController;

  late DateTime _birthDate;
  late String _selectedSex;
  late String _selectedGoal;

  bool _addCurrentWeightToHistory = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.user.name);

    _heightController = TextEditingController(
      text: widget.user.hasValidHeight
          ? _formatNumberForInput(widget.user.heightInMeters * 100)
          : '',
    );

    _initialWeightController = TextEditingController(
      text: _formatNumberForInput(widget.initialWeight),
    );

    _currentWeightController = TextEditingController(
      text: _formatNumberForInput(widget.currentWeight),
    );

    _targetWeightController = TextEditingController(
      text: widget.user.targetWeight == null
          ? ''
          : _formatNumberForInput(widget.user.targetWeight!),
    );

    _birthDate = widget.user.birthDate;

    _selectedSex = _validSex(widget.user.sex);

    _selectedGoal = _validGoal(widget.user.mainGoal);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _initialWeightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();

    super.dispose();
  }

  String _formatNumberForInput(double value) {
    return value.toString().replaceAll('.', ',');
  }

  String _validSex(String value) {
    const validValues = {'masculino', 'feminino', 'prefiro_nao_informar'};

    if (validValues.contains(value)) {
      return value;
    }

    return 'prefiro_nao_informar';
  }

  String _validGoal(String value) {
    const validValues = {'emagrecer', 'condicionamento', 'correr', 'saude'};

    if (validValues.contains(value)) {
      return value;
    }

    return 'saude';
  }

  double? _parseNumber(String value) {
    final normalized = value.trim().replaceAll(',', '.');

    return double.tryParse(normalized);
  }

  double? _parseHeightCm(String value) {
    var height = _parseNumber(value);

    if (height == null) {
      return null;
    }

    if (height <= 3) {
      height *= 100;
    }

    return height;
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Informe seu nome.';
    }

    if (name.length < 2) {
      return 'Digite pelo menos 2 caracteres.';
    }

    if (name.length > 60) {
      return 'Digite no máximo 60 caracteres.';
    }

    return null;
  }

  String? _validateHeight(String? value) {
    final height = _parseHeightCm(value ?? '');

    if (height == null) {
      return 'Digite uma altura válida.';
    }

    if (height < 100 || height > 250) {
      return 'Digite uma altura entre 100 e 250 cm.';
    }

    return null;
  }

  String? _validateWeight(
    String? value, {
    required String fieldName,
    bool optional = false,
  }) {
    final text = value?.trim() ?? '';

    if (optional && text.isEmpty) {
      return null;
    }

    final weight = _parseNumber(text);

    if (weight == null) {
      return 'Digite $fieldName válido.';
    }

    if (weight < 30 || weight > 350) {
      return 'Digite um valor entre 30 e 350 kg.';
    }

    return null;
  }

  Future<void> _selectBirthDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _birthDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    setState(() {
      _birthDate = selectedDate;
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  bool get _currentWeightWasChanged {
    final newWeight = _parseNumber(_currentWeightController.text);

    if (newWeight == null) {
      return false;
    }

    const comparisonEpsilon = 0.000000001;
    const weightTolerance = 0.005;

    final difference = (newWeight - widget.currentWeight).abs();

    return difference + comparisonEpsilon >= weightTolerance;
  }

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }

    final formIsValid = _formKey.currentState?.validate() ?? false;

    if (!formIsValid) {
      return;
    }

    final heightCm = _parseHeightCm(_heightController.text);

    final initialWeight = _parseNumber(_initialWeightController.text);

    final currentWeight = _parseNumber(_currentWeightController.text);

    final targetText = _targetWeightController.text.trim();

    final targetWeight = targetText.isEmpty ? null : _parseNumber(targetText);

    final name = _nameController.text.trim();
    final birthDate = _birthDate;
    final selectedSex = _selectedSex;
    final selectedGoal = _selectedGoal;
    final addCurrentWeightToHistory = _addCurrentWeightToHistory;

    if (heightCm == null || initialWeight == null || currentWeight == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    UserModel? previousUser;
    List<WeightRecord>? previousWeightRecords;
    var writeStarted = false;

    try {
      final storedUser = await _userStorageService.loadUser();

      if (storedUser == null) {
        throw StateError('Usuário não encontrado.');
      }

      previousUser = UserModel(
        name: storedUser.name,
        birthDate: storedUser.birthDate,
        sex: storedUser.sex,
        height: storedUser.height,
        currentWeight: storedUser.currentWeight,
        targetWeight: storedUser.targetWeight,
        mainGoal: storedUser.mainGoal,
      );

      previousWeightRecords = List<WeightRecord>.from(
        await _weightHistoryService.loadRecordsStrict(),
      );

      final updatedUser = UserModel(
        name: name,
        birthDate: birthDate,
        sex: selectedSex,
        height: heightCm,
        currentWeight: currentWeight,
        targetWeight: targetWeight,
        mainGoal: selectedGoal,
      );

      writeStarted = true;

      await _userStorageService.saveUser(updatedUser);

      await _weightHistoryService.updateProfileWeights(
        initialWeight: initialWeight,
        currentWeight: currentWeight,
        addCurrentWeightRecord: addCurrentWeightToHistory,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (_) {
      if (writeStarted &&
          previousUser != null &&
          previousWeightRecords != null) {
        try {
          await _userStorageService.saveUser(previousUser);
        } catch (_) {}

        try {
          await _weightHistoryService.replaceRecords(previousWeightRecords);
        } catch (_) {}
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar as alterações.')),
      );
    }
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffixText,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      onChanged: (_) {
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: !_isSaving,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _isSaving
                ? null
                : () {
                    Navigator.of(context).maybePop();
                  },
            icon: const BackButtonIcon(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          title: const Text('Editar perfil'),
        ),
        body: SafeArea(
          child: AbsorbPointer(
            absorbing: _isSaving,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Dados pessoais',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _selectBirthDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          const Text('Data de nascimento'),
                          const Spacer(),
                          Text(_formatDate(_birthDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSex,
                    decoration: const InputDecoration(
                      labelText: 'Sexo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'masculino',
                        child: Text('Masculino'),
                      ),
                      DropdownMenuItem(
                        value: 'feminino',
                        child: Text('Feminino'),
                      ),
                      DropdownMenuItem(
                        value: 'prefiro_nao_informar',
                        child: Text('Prefiro não informar'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _selectedSex = value;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Dados físicos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  _buildNumberField(
                    controller: _heightController,
                    label: 'Altura',
                    hint: 'Ex.: 179 ou 1,79',
                    suffixText: 'cm',
                    validator: _validateHeight,
                  ),
                  const SizedBox(height: 14),
                  _buildNumberField(
                    controller: _initialWeightController,
                    label: 'Peso inicial',
                    hint: 'Ex.: 135',
                    suffixText: 'kg',
                    validator: (value) {
                      return _validateWeight(
                        value,
                        fieldName: 'um peso inicial',
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildNumberField(
                    controller: _currentWeightController,
                    label: 'Peso atual',
                    hint: 'Ex.: 126',
                    suffixText: 'kg',
                    validator: (value) {
                      return _validateWeight(value, fieldName: 'um peso atual');
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildNumberField(
                    controller: _targetWeightController,
                    label: 'Meta de peso',
                    hint: 'Deixe vazio para remover',
                    suffixText: 'kg',
                    validator: (value) {
                      return _validateWeight(
                        value,
                        fieldName: 'uma meta de peso',
                        optional: true,
                      );
                    },
                  ),
                  if (_currentWeightWasChanged) ...[
                    const SizedBox(height: 14),
                    Card(
                      child: SwitchListTile(
                        value: _addCurrentWeightToHistory,
                        onChanged: (value) {
                          setState(() {
                            _addCurrentWeightToHistory = value;
                          });
                        },
                        title: const Text('Registrar como nova pesagem'),
                        subtitle: Text(
                          _addCurrentWeightToHistory
                              ? 'A alteração será adicionada '
                                    'ao histórico com a data atual.'
                              : 'O registro de peso mais '
                                    'recente será corrigido.',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'Objetivo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGoal,
                    decoration: const InputDecoration(
                      labelText: 'Objetivo principal',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'emagrecer',
                        child: Text('Emagrecer'),
                      ),
                      DropdownMenuItem(
                        value: 'condicionamento',
                        child: Text('Melhorar condicionamento'),
                      ),
                      DropdownMenuItem(
                        value: 'correr',
                        child: Text('Começar a correr'),
                      ),
                      DropdownMenuItem(
                        value: 'saude',
                        child: Text('Manter a saúde'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _selectedGoal = value;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                              'Alterar o peso inicial '
                              'corrige o primeiro registro '
                              'do histórico. Seus treinos, '
                              'progresso e demais pesagens '
                              'serão preservados.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        _isSaving ? 'Salvando...' : 'Salvar alterações',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
