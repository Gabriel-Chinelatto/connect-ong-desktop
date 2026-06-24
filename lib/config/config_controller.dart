import 'package:flutter/material.dart';

import '../models/preferencia.dart';
import '../services/preferencia_service.dart';

/// Controla as preferencias de aparencia/acessibilidade do app desktop.
/// O MaterialApp escuta este controlador e se reconstroi quando muda.
class ConfigController extends ChangeNotifier {
  ConfigController._();
  static final ConfigController instance = ConfigController._();

  final PreferenciaService _service = PreferenciaService();

  Preferencia _prefs = Preferencia();
  int? _usuarioId;

  Preferencia get prefs => _prefs;
  int? get usuarioId => _usuarioId;

  ThemeMode get themeMode {
    switch (_prefs.tema) {
      case 'CLARO':
        return ThemeMode.light;
      case 'ESCURO':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  double get textScale {
    switch (_prefs.tamanhoFonte) {
      case 'PEQUENA':
        return 0.9;
      case 'GRANDE':
        return 1.2;
      default:
        return 1.0;
    }
  }

  bool get fonteDislexia => _prefs.fonteDislexia;
  bool get altoContraste => _prefs.altoContraste;

  Future<void> carregar(int usuarioId) async {
    _usuarioId = usuarioId;
    try {
      _prefs = await _service.obter(usuarioId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> atualizar(Preferencia novo) async {
    _prefs = novo;
    notifyListeners();
    if (_usuarioId != null) {
      try {
        await _service.salvar(_usuarioId!, novo);
      } catch (_) {}
    }
  }

  void limpar() {
    _prefs = Preferencia();
    _usuarioId = null;
    notifyListeners();
  }
}
