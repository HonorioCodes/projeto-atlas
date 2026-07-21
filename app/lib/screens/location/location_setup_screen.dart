import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/location_service.dart';

class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  State<LocationSetupScreen> createState() {
    return _LocationSetupScreenState();
  }
}

class _LocationSetupScreenState extends State<LocationSetupScreen>
    with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();

  LocationAccessResult? _accessResult;
  Position? _position;

  bool _isBusy = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _refreshAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAccess();
    }
  }

  Future<void> _refreshAccess({bool requestPermission = false}) async {
    if (_isBusy && _accessResult != null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final result = await _locationService.checkAccess(
        requestPermission: requestPermission,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _accessResult = result;
        _isBusy = false;

        if (!result.isGranted) {
          _position = null;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBusy = false;
        _errorMessage = 'Não foi possível verificar o GPS.';
      });
    }
  }

  Future<void> _readCurrentPosition() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _position = position;
        _isBusy = false;
      });
    } on TimeoutException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBusy = false;
        _errorMessage =
            'O GPS demorou para encontrar sua posição. '
            'Vá para uma área aberta e tente novamente.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBusy = false;
        _errorMessage = 'Não foi possível obter sua localização.';
      });
    }
  }

  Future<void> _handlePrimaryAction() async {
    final status = _accessResult?.status;

    if (status == null) {
      await _refreshAccess();
      return;
    }

    switch (status) {
      case LocationAccessStatus.serviceDisabled:
        await _locationService.openLocationSettings();
        return;

      case LocationAccessStatus.permissionDenied:
        await _refreshAccess(requestPermission: true);
        return;

      case LocationAccessStatus.permissionDeniedForever:
        await _locationService.openAppSettings();
        return;

      case LocationAccessStatus.granted:
        await _readCurrentPosition();
        return;
    }
  }

  String get _statusTitle {
    final status = _accessResult?.status;

    switch (status) {
      case LocationAccessStatus.serviceDisabled:
        return 'GPS desativado';

      case LocationAccessStatus.permissionDenied:
        return 'Permissão necessária';

      case LocationAccessStatus.permissionDeniedForever:
        return 'Permissão bloqueada';

      case LocationAccessStatus.granted:
        return 'GPS disponível';

      case null:
        return 'Verificando GPS';
    }
  }

  String get _statusDescription {
    final status = _accessResult?.status;

    switch (status) {
      case LocationAccessStatus.serviceDisabled:
        return 'Ative a localização do celular para '
            'registrar distância e ritmo.';

      case LocationAccessStatus.permissionDenied:
        return 'Permita o acesso à localização precisa '
            'durante o uso do aplicativo.';

      case LocationAccessStatus.permissionDeniedForever:
        return 'A permissão foi bloqueada. Abra as '
            'configurações do aplicativo para liberá-la.';

      case LocationAccessStatus.granted:
        return 'A permissão está correta. Faça uma leitura '
            'para testar o sinal do GPS.';

      case null:
        return 'Aguarde enquanto verificamos o aparelho.';
    }
  }

  String get _buttonLabel {
    final status = _accessResult?.status;

    switch (status) {
      case LocationAccessStatus.serviceDisabled:
        return 'Ativar GPS';

      case LocationAccessStatus.permissionDenied:
        return 'Permitir localização';

      case LocationAccessStatus.permissionDeniedForever:
        return 'Abrir configurações';

      case LocationAccessStatus.granted:
        return 'Testar localização';

      case null:
        return 'Verificar novamente';
    }
  }

  IconData get _statusIcon {
    final status = _accessResult?.status;

    switch (status) {
      case LocationAccessStatus.serviceDisabled:
        return Icons.location_disabled;

      case LocationAccessStatus.permissionDenied:
      case LocationAccessStatus.permissionDeniedForever:
        return Icons.gps_off;

      case LocationAccessStatus.granted:
        return Icons.gps_fixed;

      case null:
        return Icons.location_searching;
    }
  }

  Widget _buildPositionCard() {
    final position = _position;

    if (position == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leitura concluída',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _PositionRow(
              label: 'Precisão',
              value: '${position.accuracy.toStringAsFixed(1)} m',
            ),
            const Divider(height: 24),
            _PositionRow(
              label: 'Latitude',
              value: position.latitude.toStringAsFixed(6),
            ),
            const Divider(height: 24),
            _PositionRow(
              label: 'Longitude',
              value: position.longitude.toStringAsFixed(6),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração do GPS')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(
              _statusIcon,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              _statusTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(_statusDescription, textAlign: TextAlign.center),
            const SizedBox(height: 28),
            if (_errorMessage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            _buildPositionCard(),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isBusy ? null : _handlePrimaryAction,
              icon: _isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_isBusy ? 'Verificando...' : _buttonLabel),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta tela faz somente um teste. A localização '
              'ainda não será armazenada no histórico.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionRow extends StatelessWidget {
  final String label;
  final String value;

  const _PositionRow({required this.label, required this.value});

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
