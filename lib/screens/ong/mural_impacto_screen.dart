import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/estatistica_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/feedback/empty_state.dart';

/// Mural de Impacto: numeros coletivos da plataforma (transparencia).
/// Reaproveita GET /publico/estatisticas.
class MuralImpactoScreen extends StatefulWidget {
  const MuralImpactoScreen({super.key});

  @override
  State<MuralImpactoScreen> createState() => _MuralImpactoScreenState();
}

class _MuralImpactoScreenState extends State<MuralImpactoScreen> {
  final EstatisticaService _service = EstatisticaService();
  EstatisticasPublicas _stats = EstatisticasPublicas.zero;
  bool _carregando = true;
  bool _erro = false;

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
      final s = await _service.carregar();
      if (!mounted) return;
      setState(() {
        _stats = s;
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

  int get _pessoasAlcancadas =>
      _stats.totalMatches + _stats.totalDoacoesFinanceiras;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mural de Impacto'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro
              ? _vazio()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _hero(),
                        const SizedBox(height: 18),
                        _destaquePessoas(),
                        const SizedBox(height: 18),
                        _grade(),
                        const SizedBox(height: 18),
                        _rodape(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _vazio() {
    return EmptyState(
      icone: Icons.cloud_off_outlined,
      mensagem: 'Não foi possível carregar o impacto',
      detalhe: 'Verifique sua conexão e tente novamente.',
      acaoRotulo: 'Tentar de novo',
      onAcao: _carregar,
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child:
                SvgPicture.asset('assets/images/impacto_hero.svg', height: 150),
          ),
          const SizedBox(height: 12),
          const Text(
            'Juntos transformamos vidas',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'O resultado coletivo de cada doacao na plataforma',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _destaquePessoas() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Column(
          children: [
            const Icon(Icons.diversity_1, color: AppColors.primary, size: 34),
            const SizedBox(height: 6),
            _contador(_pessoasAlcancadas,
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            Text('pessoas alcancadas (estimativa)',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _grade() {
    final itens = <_ItemStat>[
      _ItemStat(Icons.apartment_outlined, _stats.totalOngs, 'ONGs parceiras'),
      _ItemStat(Icons.favorite_outline, _stats.totalDoadores, 'Doadores'),
      _ItemStat(
          Icons.volunteer_activism, _stats.totalNecessidades, 'Necessidades'),
      _ItemStat(Icons.handshake_outlined, _stats.totalMatches, 'Conexoes'),
      _ItemStat(
          Icons.receipt_long_outlined, _stats.totalPrestacoes, 'Prestacoes'),
      _ItemStat(
          Icons.attach_money, _stats.totalDoacoesFinanceiras, 'Doacoes PIX'),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.6,
      children: [for (final i in itens) _cardStat(i)],
    );
  }

  Widget _cardStat(_ItemStat i) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(i.icon, color: AppColors.primary, size: 20),
            ),
            const Spacer(),
            _contador(i.valor,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            Text(i.label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _rodape() {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.08),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.savings_outlined,
                color: AppColors.primary, size: 30),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total doado via PIX',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
                Text('R\$ ${_stats.valorTotalDoado.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _contador(int valor, {required TextStyle style}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valor.toDouble()),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOut,
      builder: (_, v, __) => Text('${v.round()}', style: style),
    );
  }
}

class _ItemStat {
  final IconData icon;
  final int valor;
  final String label;
  const _ItemStat(this.icon, this.valor, this.label);
}
