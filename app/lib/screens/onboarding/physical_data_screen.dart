import '../plans/plans_screen.dart';
import 'package:flutter/material.dart';

class PhysicalDataScreen extends StatefulWidget {
  const PhysicalDataScreen({super.key});

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
  onPressed: () {
    final isFormValid =
        _formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlansScreen(),
      ),
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