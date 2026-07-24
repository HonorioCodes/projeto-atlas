import 'package:flutter/material.dart';

import '../../models/training_settings.dart';
import '../../services/training_settings_service.dart';
import '../location/location_setup_screen.dart';

class TrainingSettingsScreen extends StatefulWidget {
  final TrainingSettingsService? settingsService;

  const TrainingSettingsScreen({super.key, this.settingsService});

  @override
  State<TrainingSettingsScreen> createState() {
    return _TrainingSettingsScreenState();
  }
}

class _TrainingSettingsScreenState extends State<TrainingSettingsScreen> {
  late final TrainingSettingsService _settingsService;

  TrainingSettings _settings = TrainingSettings.defaults;
  TrainingSettings _savedSettings = TrainingSettings.defaults;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _hasUnsavedChanges {
    return _settings != _savedSettings;
  }

  @override
  void initState() {
    super.initState();

    _settingsService = widget.settingsService ?? TrainingSettingsService();

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings = await _settingsService.loadSettings();

      if (!mounted) {
        return;
      }

      setState(() {
        _settings = settings;
        _savedSettings = settings;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar as configurações.';
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving || !_hasUnsavedChanges) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _settingsService.saveSettings(_settings);

      if (!mounted) {
        return;
      }

      setState(() {
        _savedSettings = _settings;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar as configurações.'),
        ),
      );
    }
  }

  Future<void> _restoreDefaults() async {
    if (_isSaving) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restaurar configurações?'),
          content: const Text(
            'Sons, vibração, GPS, tela ligada e unidade de distância '
            'voltarão aos valores padrão.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _settingsService.resetSettings();

      if (!mounted) {
        return;
      }

      setState(() {
        _settings = TrainingSettings.defaults;
        _savedSettings = TrainingSettings.defaults;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações padrão restauradas.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível restaurar as configurações.'),
        ),
      );
    }
  }

  Future<void> _openLocationSetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const LocationSetupScreen();
        },
      ),
    );
  }

  Future<void> _requestExit() async {
    if (_isSaving || !_hasUnsavedChanges) {
      return;
    }

    final discardChanges = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Descartar alterações?'),
          content: const Text(
            'As configurações modificadas ainda não foram salvas.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Continuar editando'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Descartar'),
            ),
          ],
        );
      },
    );

    if (discardChanges == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
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
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return AbsorbPointer(
      absorbing: _isSaving,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Avisos do treino',
            icon: Icons.notifications_active_outlined,
            children: [
              SwitchListTile(
                value: _settings.soundEnabled,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(soundEnabled: value);
                  });
                },
                title: const Text('Sons de aviso'),
                subtitle: const Text(
                  'Reproduzir avisos sonoros nas mudanças de etapa.',
                ),
              ),
              SwitchListTile(
                value: _settings.vibrationEnabled,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(vibrationEnabled: value);
                  });
                },
                title: const Text('Vibração'),
                subtitle: const Text('Vibrar nas mudanças de etapa do treino.'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSection(
            title: 'GPS e distância',
            icon: Icons.gps_fixed,
            children: [
              SwitchListTile(
                value: _settings.requireGpsToStart,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(requireGpsToStart: value);
                  });
                },
                title: const Text('Exigir GPS para iniciar'),
                subtitle: Text(
                  _settings.requireGpsToStart
                      ? 'O treino só começa quando a localização '
                            'estiver disponível.'
                      : 'O treino pode começar sem registrar '
                            'distância e ritmo.',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openLocationSetup,
                    icon: const Icon(Icons.location_searching),
                    label: const Text('Testar e configurar GPS'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSection(
            title: 'Exibição da distância',
            icon: Icons.straighten,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SegmentedButton<DistanceDisplayUnit>(
                  segments: const [
                    ButtonSegment(
                      value: DistanceDisplayUnit.automatic,
                      label: Text('Automática'),
                    ),
                    ButtonSegment(
                      value: DistanceDisplayUnit.kilometers,
                      label: Text('Quilômetros'),
                    ),
                    ButtonSegment(
                      value: DistanceDisplayUnit.meters,
                      label: Text('Metros'),
                    ),
                  ],
                  selected: {_settings.distanceDisplayUnit},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _settings = _settings.copyWith(
                        distanceDisplayUnit: selection.single,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSection(
            title: 'Tela durante o treino',
            icon: Icons.light_mode_outlined,
            children: [
              SwitchListTile(
                value: _settings.keepScreenAwake,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(keepScreenAwake: value);
                  });
                },
                title: const Text('Manter tela ligada'),
                subtitle: const Text(
                  'Impedir que a tela apague automaticamente '
                  'enquanto o treino estiver em andamento.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSaving || !_hasUnsavedChanges ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Text(_isSaving ? 'Salvando...' : 'Salvar configurações'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _restoreDefaults,
            icon: const Icon(Icons.restore),
            label: const Text('Restaurar padrões'),
          ),
          const SizedBox(height: 24),
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
              const Icon(Icons.error_outline, size: 60),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadSettings,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildSettings();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: !_isSaving && !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        await _requestExit();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Configurações do treino')),
        body: SafeArea(child: _buildContent()),
      ),
    );
  }
}
