import 'package:flutter/material.dart';

import '../../services/ia_service.dart';
import '../../theme/app_colors.dart';

/// Abre o diálogo "Sobre com IA": a partir do [rascunhoAtual] da ONG, a IA
/// sugere um texto de "Sobre"; a ONG confirma ("Sim, usar") ou pede ajustes em
/// linguagem natural ("mais curto", "mencione que atendemos crianças"), e a IA
/// reformula — quantas vezes quiser. Retorna o texto FINAL escolhido (para
/// preencher o campo de descrição) ou null se a ONG fechar sem confirmar.
///
/// A IA é ancorada nos dados REAIS da ONG no backend (nome, cidade, categorias
/// que costuma pedir...), então não inventa informação.
Future<String?> mostrarSobreComIa(
  BuildContext context, {
  required int ongId,
  required String rascunhoAtual,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _SobreComIaDialog(ongId: ongId, rascunhoAtual: rascunhoAtual),
  );
}

class _SobreComIaDialog extends StatefulWidget {
  final int ongId;
  final String rascunhoAtual;

  const _SobreComIaDialog({required this.ongId, required this.rascunhoAtual});

  @override
  State<_SobreComIaDialog> createState() => _SobreComIaDialogState();
}

class _SobreComIaDialogState extends State<_SobreComIaDialog> {
  final IaService _ia = IaService();
  final _ajusteCtrl = TextEditingController();

  bool _carregando = true;
  String _sugestao = '';
  bool _modoRegras = false;
  String? _erro;
  bool _pedindoAjuste = false;

  @override
  void initState() {
    super.initState();
    _gerar(ajuste: null);
  }

  @override
  void dispose() {
    _ajusteCtrl.dispose();
    super.dispose();
  }

  // Chama a IA. Base = a sugestão atual (se já houver) ou o rascunho da ONG.
  Future<void> _gerar({required String? ajuste}) async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final base = _sugestao.isNotEmpty ? _sugestao : widget.rascunhoAtual;
    try {
      final r = await _ia.escreverSobre(
        ongId: widget.ongId,
        rascunho: base,
        ajuste: ajuste,
      );
      if (!mounted) return;
      setState(() {
        _sugestao = r.descricao.trim();
        _modoRegras = r.modoRegras;
        _pedindoAjuste = false;
        _ajusteCtrl.clear();
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          const Expanded(child: Text('Sobre com IA')),
          if (!_carregando && _sugestao.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (_modoRegras ? cs.surfaceContainerHighest : AppColors.primary)
                    .withValues(alpha: _modoRegras ? 1 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _modoRegras ? 'Modo básico' : 'IA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _modoRegras ? cs.onSurfaceVariant : AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      content: SizedBox(width: 460, child: _corpo(cs)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _corpo(ColorScheme cs) {
    if (_carregando) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Gerando sugestão…'),
            ],
          ),
        ),
      );
    }
    if (_erro != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_erro!, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _gerar(ajuste: null),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sugestão da IA (baseada no que você escreveu e nos dados da sua ONG):',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Text(
            _sugestao.isEmpty ? '(sem texto)' : _sugestao,
            style: TextStyle(fontSize: 14, height: 1.5, color: cs.onSurface),
          ),
        ),
        const SizedBox(height: 16),

        if (!_pedindoAjuste) ...[
          Text(
            'Ficou bom?',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _sugestao.isEmpty
                    ? null
                    : () => Navigator.pop(context, _sugestao),
                icon: const Icon(Icons.check),
                label: const Text('Sim, usar este texto'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() => _pedindoAjuste = true),
                icon: const Icon(Icons.tune),
                label: const Text('Não, quero ajustar'),
              ),
            ],
          ),
        ] else ...[
          Text(
            'O que você quer mudar?',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ajusteCtrl,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ex.: deixe mais curto e mencione que atendemos idosos',
            ),
            onSubmitted: (_) => _reformular(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _reformular,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Reformular'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _pedindoAjuste = false),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _reformular() {
    final ajuste = _ajusteCtrl.text.trim();
    if (ajuste.isEmpty) return;
    _gerar(ajuste: ajuste);
  }
}
