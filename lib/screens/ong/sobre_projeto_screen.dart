import 'package:flutter/material.dart';

import '../../data/versoes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Tela "Sobre o projeto": uma apresentação enxuta do Connect ONG e, como
/// último tópico, o changelog (seção "Versões").
///
/// TODO o texto usa cor EXPLÍCITA do tema (colorScheme.onSurface /
/// onSurfaceVariant / primary) para permanecer legível no claro E no escuro.
///
/// Versões: mostra as 5 mais recentes; "Ver todas as versões" revela o resto;
/// cada versão é um [ExpansionTile] (clicável) e a versão atual (v1.7) abre
/// expandida com selo "Atual".
class SobreProjetoScreen extends StatefulWidget {
  const SobreProjetoScreen({super.key});

  @override
  State<SobreProjetoScreen> createState() => _SobreProjetoScreenState();
}

class _SobreProjetoScreenState extends State<SobreProjetoScreen> {
  /// Quantidade de versões exibidas inicialmente (as mais recentes).
  static const int _visiveisInicial = 5;

  bool _verTodas = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final versoes = _verTodas || kVersoes.length <= _visiveisInicial
        ? kVersoes
        : kVersoes.take(_visiveisInicial).toList();
    final ocultas = kVersoes.length - versoes.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o projeto')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            children: [
              _cabecalho(cs),
              const SizedBox(height: AppSpacing.lg),
              _tituloSecao(cs, Icons.history, 'Versões'),
              const SizedBox(height: AppSpacing.sm),
              ...versoes.map((v) => _cartaoVersao(cs, v)),
              if (ocultas > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _verTodas = true),
                      icon: const Icon(Icons.expand_more),
                      label: Text('Ver todas as versões ($ocultas anteriores)'),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  /// Apresentação do produto: logo/título, missão curta e o que é.
  Widget _cabecalho(ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.volunteer_activism,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect ONG',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        'Conectando quem quer doar a quem precisa',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Nossa missão',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Aproximar doadores e organizações sociais, tornando a doação '
              'simples, transparente e cheia de propósito.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'O que é',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'O Connect ONG é uma plataforma que dá match entre as '
              'necessidades reais das ONGs e o que cada doador tem a oferecer. '
              'As ONGs publicam do que precisam; os doadores encontram causas '
              'próximas, demonstram interesse e conversam pelo chat. Tudo com '
              'prestação de contas, avaliações e um painel de impacto para '
              'mostrar, de ponta a ponta, o bem que foi feito.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tituloSecao(ColorScheme cs, IconData icone, String texto) {
    return Row(
      children: [
        Icon(icone, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          texto,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  /// Um item do changelog: [ExpansionTile] com o rótulo da versão, o título e,
  /// ao abrir, a lista de mudanças. A versão atual traz o selo "Atual" e já
  /// nasce expandida.
  Widget _cartaoVersao(ColorScheme cs, VersaoApp v) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Theme(
        // Remove as divisórias padrão do ExpansionTile dentro do Card.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: v.atual,
          collapsedIconColor: cs.onSurfaceVariant,
          iconColor: AppColors.primary,
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: v.atual
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              'v${v.versao}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: v.atual ? Colors.white : AppColors.primary,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  v.titulo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (v.atual) _seloAtual(),
            ],
          ),
          subtitle: Text(
            'Versão ${v.versao}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          children: v.mudancas.map((m) => _itemMudanca(cs, m)).toList(),
        ),
      ),
    );
  }

  Widget _seloAtual() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Atual',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _itemMudanca(ColorScheme cs, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.check_circle,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
