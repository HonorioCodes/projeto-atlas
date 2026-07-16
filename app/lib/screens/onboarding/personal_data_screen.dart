import '../../models/user_registration.dart';
import 'package:flutter/material.dart';
import 'physical_data_screen.dart';

class PersonalDataScreen extends StatefulWidget {
  final UserRegistration registration;

  const PersonalDataScreen({
    super.key,
    required this.registration,
  });

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  DateTime? _birthDate;
  String? _selectedSex;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _birthDate = selectedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados pessoais'),
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
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe seu nome';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _selectBirthDate,
                  child: Text(
                    _birthDate == null
                        ? 'Selecionar data de nascimento'
                        : '${_birthDate!.day.toString().padLeft(2, '0')}/'
                            '${_birthDate!.month.toString().padLeft(2, '0')}/'
                            '${_birthDate!.year}',
                  ),
                ),
                const SizedBox(height: 16),
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
                    setState(() {
                      _selectedSex = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione uma opção';
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

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione sua data de nascimento',
          ),
        ),
      );
      return;
    }

    widget.registration.name =
        _nameController.text.trim();

    widget.registration.birthDate =
        _birthDate;

    widget.registration.sex =
        _selectedSex;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhysicalDataScreen(
          registration: widget.registration,
        ),
      ),
    );
  },
  child: const Text('Continuar'),
),
              ],
            ),
          ),
        ),
      ),
    );
  }
}