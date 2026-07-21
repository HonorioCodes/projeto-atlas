import '../../services/user_storage_service.dart';
import 'package:flutter/material.dart';
import '../../models/user_registration.dart';
import '../plans/plans_screen.dart';

class PhysicalDataScreen extends StatefulWidget {
  final UserRegistration registration;

  const PhysicalDataScreen({
    super.key,
    required this.registration,
  });

  @override
  State<PhysicalDataScreen> createState() => _PhysicalDataScreenState();
}

class _PhysicalDataScreenState extends State<PhysicalDataScreen> {
  final _formKey = GlobalKey<FormState>();

  final _heightController = TextEditingController();
  final _currentWeightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  String? _selectedGoal;

  @override
  void dispose() {
    _heightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe $fieldName';
    }

    final number = double.tryParse(
      value.replaceAll(',', '.'),
    );

    if (number == null || number <= 0) {
      return 'Digite um valor válido';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados físicos'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Altura em cm',
                    hintText: 'Exemplo: 179',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    return _validateNumber(value, 'sua altura');
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentWeightController,
                  decoration: const InputDecoration(
                    labelText: 'Peso atual em kg',
                    hintText: 'Exemplo: 126',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    return _validateNumber(value, 'seu peso atual');
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetWeightController,
                  decoration: const InputDecoration(
                    labelText: 'Peso objetivo em kg',
                    hintText: 'Opcional',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }

                    return _validateNumber(value, 'seu peso objetivo');
                  },
                ),
                const SizedBox(height: 16),
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
                    setState(() {
                      _selectedGoal = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione um objetivo';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
  onPressed: () async {
    final isFormValid =
        _formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      return;
    }

    widget.registration.height = double.parse(
      _heightController.text.replaceAll(',', '.'),
    );

    widget.registration.currentWeight = double.parse(
      _currentWeightController.text.replaceAll(',', '.'),
    );

    final targetWeightText =
        _targetWeightController.text.trim();

    widget.registration.targetWeight =
        targetWeightText.isEmpty
            ? null
            : double.parse(
                targetWeightText.replaceAll(',', '.'),
              );

    widget.registration.mainGoal = _selectedGoal;

    final user = widget.registration.toUserModel();
    final storageService = UserStorageService();

    await storageService.saveUser(user);

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const PlansScreen(),
      ),
      (route) => false,
    );
  },
  child: const Text('Finalizar cadastro'),
),
              ],
            ),
          ),
        ),
      ),
    );
  }
}