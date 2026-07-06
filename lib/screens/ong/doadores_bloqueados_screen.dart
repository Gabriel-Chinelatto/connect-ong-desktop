import 'package:flutter/material.dart';

import '../../models/bloqueio.dart';
import '../../services/api_service.dart';
import '../../services/bloqueio_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/feedback/app_snackbar.dart';
import '../../widgets/feedback/empty_state.dart';

/// Lista de doadores bloqueados pela ONG (estilo WhatsApp).
///
/// Cada item mostra nome + data do bloqueio e um botão "Desbloquear"
/// (DELETE /bloqueios/{doadorId}). Backend antigo sem os endpoints degrada
/// para a lista vazia (o service trata o 404 do GET).
class DoadoresBloqueadosScreen extends StatefulWidget {
  const DoadoresBloqueadosScreen({super.key});

  @override
  State<DoadoresBloqueadosScreen> createState() =>
      _DoadoresBloqueadosScreenState();
}

class _DoadoresBloqueadosScreenState extends State<DoadoresBloqueadosScreen> {
  final BloqueioService _service = BloqueioService();

  List<Bloqueio> _bloqueios = [];
  bool _carregando = true;
  bool _erro = false;

  /// Doadores com desbloqueio em andamento (guard anti-duplo-clique por item).
  final Set<int> _desbloqueando = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      final lista = await _service.listar();
      if (!mounted) return;
      setState(() {
        _bloqueios = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = true;
      });
    }
  }

  Future<void> _desbloquear(Bloqueio b) async {
    if (_desbloqueando.contains(b.doadorId)) return;
    setState(() => _desbloqueando.add(b.doadorId));
    try {
      await _service.desbloquear(b.doadorId);
      if (!mounted) return;
      setState(() {
        _bloqueios.removeWhere((x) => x.doadorId == b.doadorId);
      });
      AppSnackbar.sucesso(context, '${b.doadorNome} foi desbloqueado.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    } finally {
      if (mounted) setState(() => _desbloqueando.remove(b.doadorId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doadores bloqueados')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro
              ? EmptyState(
                  icone: Icons.cloud_off_outlined,
                  mensagem:
                      'Não foi possível carregar os doadores bloqueados',
                  detalhe: 'Verifique sua conexão e tente novamente.',
                  acaoRotulo: 'Tentar de novo',
                  onAcao: _carregar,
                )
              : _bloqueios.isEmpty
                  ? const EmptyState(
                      icone: Icons.block,
                      mensagem: 'Nenhum doador bloqueado',
                      detalhe:
                          'Doadores bloqueados deixam de ver sua ONG e não '
                          'podem enviar mensagens.',
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _bloqueios.length,
                          itemBuilder: (context, i) => _item(_bloqueios[i]),
                        ),
                      ),
                    ),
    );
  }

  Widget _item(Bloqueio b) {
    final cs = Theme.of(context).colorScheme;
    final inicial =
        b.doadorNome.isNotEmpty ? b.doadorNome[0].toUpperCase() : '?';
    final data = _formatarDataCurta(b.criadoEm);
    final ocupado = _desbloqueando.contains(b.doadorId);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.error.withValues(alpha: 0.12),
          child: Text(inicial,
              style: const TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w700)),
        ),
        title: Text(b.doadorNome,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          data.isNotEmpty ? 'Bloqueado em $data' : 'Bloqueado',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        trailing: OutlinedButton.icon(
          onPressed: ocupado ? null : () => _desbloquear(b),
          icon: ocupado
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock_open, size: 18),
          label: const Text('Desbloquear'),
        ),
      ),
    );
  }

  /// Formata uma data ISO como dd/MM/aaaa (ou vazio se nula/inválida).
  String _formatarDataCurta(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year}';
  }
}
