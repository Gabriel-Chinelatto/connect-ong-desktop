import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/feedback/app_snackbar.dart';

/// "Privacidade e meus dados" da ONG — direitos do titular pela LGPD (item
/// F-04 do Plano de Ação; o avaliador da FECITEC apontou "não tem ... LGPD").
///
/// Dados REAIS de `GET /usuarios/{id}/meus-dados`: o que a plataforma guarda,
/// o aceite dos Termos (com versão e data) e a exportação em JSON. No Windows o
/// JSON é salvo num arquivo escolhido pela ONG; no navegador, copiado.
class MeusDadosScreen extends StatefulWidget {
  final int usuarioId;

  const MeusDadosScreen({super.key, required this.usuarioId});

  @override
  State<MeusDadosScreen> createState() => _MeusDadosScreenState();
}

class _MeusDadosScreenState extends State<MeusDadosScreen> {
  Map<String, dynamic>? _dados;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final r = await ApiService.rede
          .get(
            Uri.parse(
                '${ApiService.baseUrl}/usuarios/${widget.usuarioId}/meus-dados'),
            headers: ApiService.authHeaders(),
          )
          .timeout(ApiService.timeout);
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final d = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      if (mounted) setState(() => _dados = d);
    } catch (e) {
      if (mounted) setState(() => _erro = ApiService.mensagemAmigavel(e));
    }
  }

  String get _json => const JsonEncoder.withIndent('  ').convert(_dados);

  Future<void> _exportar() async {
    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: _json));
      if (mounted) {
        AppSnackbar.sucesso(context, 'Dados copiados em formato JSON.');
      }
      return;
    }
    final destino = await getSaveLocation(
      suggestedName: 'connect-ong-meus-dados.json',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (destino == null) return;
    final arquivo = XFile.fromData(
      Uint8List.fromList(utf8.encode(_json)),
      mimeType: 'application/json',
      name: 'connect-ong-meus-dados.json',
    );
    await arquivo.saveTo(destino.path);
    if (mounted) {
      AppSnackbar.sucesso(context, 'Arquivo salvo em ${destino.path}');
    }
  }

  int _qtd(String chave) => (_dados?[chave] as List?)?.length ?? 0;

  String _data(dynamic iso) {
    final s = iso?.toString() ?? '';
    if (s.length < 10) return '—';
    return '${s.substring(8, 10)}/${s.substring(5, 7)}/${s.substring(0, 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e meus dados')),
      body: _erro != null
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_erro!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: _carregar, child: const Text('Tentar de novo')),
              ]),
            )
          : _dados == null
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _cartao(Icons.verified_user_outlined,
                            'Direitos do titular (LGPD, art. 18)', const [
                          _Item('Acessar e levar os dados',
                              'Veja abaixo e salve tudo em JSON.'),
                          _Item('Corrigir',
                              'Pelo menu Perfil › Editar perfil da ONG.'),
                          _Item('Excluir',
                              'Configurações › Zona de perigo: a conta é desativada e os dados pessoais anonimizados.'),
                          _Item('Revogar permissões',
                              'Exibir telefone e e-mail se ligam e desligam em Privacidade.'),
                        ]),
                        _cartao(Icons.inventory_2_outlined, 'O que guardamos', [
                          _linha('Conta de acesso',
                              '${_dados!['conta']?['email'] ?? ''}'),
                          _linha('ONG', '${_dados!['ong']?['nome'] ?? '—'}'),
                          _linha('CNPJ',
                              '${_dados!['ong']?['cnpj'] ?? 'não informado'}'),
                          _linha('Notificações', '${_qtd('notificacoes')}'),
                          _linha('Registros de acesso',
                              '${_qtd('registroDeAcessos')}'),
                        ]),
                        _cartao(Icons.lock_outline, 'Como protegemos', const [
                          _Item('Criptografia',
                              'Mensagens do chat e telefones de pessoas ficam cifrados no banco (AES-256-GCM).'),
                          _Item('Senha',
                              'Guardada só como resumo irreversível (BCrypt).'),
                          _Item('IA',
                              'E-mail, telefone, CPF e CNPJ são removidos antes de um texto ir para a IA.'),
                        ]),
                        _cartao(Icons.fact_check_outlined, 'Consentimento', [
                          for (final c in (_dados!['consentimentos'] as List? ??
                              const []))
                            _linha('Termos e Política de Privacidade',
                                'aceitos em ${_data(c['aceitoEm'])} (versão ${c['versao']})'),
                          if ((_dados!['consentimentos'] as List? ?? const [])
                              .isEmpty)
                            _linha('Termos e Política de Privacidade',
                                'conta criada antes do registro de aceite'),
                        ]),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _exportar,
                          icon: const Icon(kIsWeb
                              ? Icons.copy_all_outlined
                              : Icons.download_outlined),
                          label: const Text(kIsWeb
                              ? 'Copiar meus dados (JSON)'
                              : 'Salvar meus dados (JSON)'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _cartao(IconData icone, String titulo, List<Widget> filhos) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icone, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(titulo,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          ...filhos,
        ]),
      ),
    );
  }

  Widget _linha(String rotulo, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 240,
              child: Text(rotulo,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(valor)),
        ]),
      );
}

class _Item extends StatelessWidget {
  final String titulo;
  final String texto;

  const _Item(this.titulo, this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: '$titulo: ',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: texto),
            ])),
          ),
        ]),
      );
}
