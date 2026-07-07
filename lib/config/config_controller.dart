import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/preferencia.dart';
import '../services/preferencia_service.dart';

/// Controla as preferencias de aparencia/acessibilidade do app desktop.
/// O MaterialApp escuta este controlador e se reconstroi quando muda.
///
/// E um singleton (unica instancia [instance]) porque as preferencias e o
/// usuario logado sao estado global: qualquer tela le/atualiza por aqui e a
/// mudanca se reflete no app inteiro. Tambem guarda o [usuarioId] da sessao.
class ConfigController extends ChangeNotifier {
  ConfigController._();
  static final ConfigController instance = ConfigController._();

  final PreferenciaService _service = PreferenciaService();

  /// Chave da flag "Modo Feira" no armazenamento local (SharedPreferences).
  static const String _kModoFeira = 'modo_feira';

  Preferencia _prefs = Preferencia();
  int? _usuarioId;
  String? _usuarioEmail;

  // A flag "Modo Feira" e um estado LOCAL do dispositivo (nao do usuario): ela
  // controla se a tela de login exibe as credenciais de demonstracao, e por isso
  // precisa existir ANTES de qualquer login. Fica em SharedPreferences (e nao no
  // backend por usuario, como as demais preferencias). Padrao ligado (true).
  bool _modoFeira = true;

  Preferencia get prefs => _prefs;
  int? get usuarioId => _usuarioId;
  String? get usuarioEmail => _usuarioEmail;

  /// Atualiza o e-mail da sessao em memoria (ex.: apos "Alterar e-mail").
  void setUsuarioEmail(String? email) {
    _usuarioEmail = email;
    notifyListeners();
  }

  bool get modoFeira => _modoFeira;

  /// Persiste e aplica a flag "Modo Feira" localmente.
  Future<void> setModoFeira(bool valor) async {
    _modoFeira = valor;
    notifyListeners();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_kModoFeira, valor);
    } catch (_) {}
  }

  /// Carrega preferencias LOCAIS (device) do disco. Chamar no boot do app,
  /// antes do login, pois a tela de login depende de [modoFeira].
  Future<void> carregarLocal() async {
    try {
      final sp = await SharedPreferences.getInstance();
      _modoFeira = sp.getBool(_kModoFeira) ?? true;
      notifyListeners();
    } catch (_) {}
  }

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

  /// Aplica as preferências no app (tema/fonte/etc.) e persiste no backend,
  /// silenciando erros de rede (uso legado, aplicação imediata).
  Future<void> atualizar(Preferencia novo) async {
    _prefs = novo;
    notifyListeners();
    if (_usuarioId != null) {
      try {
        await _service.salvar(_usuarioId!, novo);
      } catch (_) {}
    }
  }

  /// Versão do [atualizar] para o "Salvar configurações" em lote: aplica o
  /// tema imediatamente e PROPAGA o erro do PUT (a tela decide o feedback e
  /// mantém o estado "pendente" para o usuário tentar de novo).
  Future<void> salvar(Preferencia novo) async {
    _prefs = novo;
    notifyListeners();
    if (_usuarioId != null) {
      await _service.salvar(_usuarioId!, novo);
    }
  }

  void limpar() {
    _prefs = Preferencia();
    _usuarioId = null;
    _usuarioEmail = null;
    notifyListeners();
  }
}
