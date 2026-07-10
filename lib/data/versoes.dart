/// Changelog do Connect ONG (histórico de versões), exibido na tela
/// "Sobre o projeto" (seção Versões).
///
/// É a MESMA lista mostrada no app do doador (mobile), para manter a narrativa
/// do produto consistente entre as plataformas. A versão marcada como [atual]
/// aparece no topo, com selo "Atual" e já expandida.
class VersaoApp {
  /// Rótulo da versão (ex.: "1.7").
  final String versao;

  /// Título curto do release (ex.: "Assistente com Inteligência Artificial").
  final String titulo;

  /// Lista de mudanças/destaques da versão.
  final List<String> mudancas;

  /// Marca a versão vigente (selo "Atual" + abre expandida).
  final bool atual;

  const VersaoApp({
    required this.versao,
    required this.titulo,
    required this.mudancas,
    this.atual = false,
  });
}

/// Versões da mais recente (topo) para a mais antiga. A v1.7 é a atual.
const List<VersaoApp> kVersoes = [
  VersaoApp(
    versao: '1.8',
    titulo: 'Revisão final de segurança',
    atual: true,
    mudancas: [
      'Sessão protegida: se o acesso expirar, o app volta ao login automaticamente',
      'Privacidade real em toda a busca: telefone e e-mail da ONG só aparecem quando ela permite',
      'Modo demonstração desligado por padrão (ligado só no computador da feira)',
      'Proteção contra abuso reforçada: limite por origem real em contribuições, cadastro e recuperação de senha',
      'Contas encerradas não conseguem mais renovar o acesso',
      'App mais robusto: leitura de dados tolerante a formatos, evitando travamentos',
    ],
  ),
  VersaoApp(
    versao: '1.7',
    titulo: 'Assistente com Inteligência Artificial',
    mudancas: [
      'Dôra, assistente de doação com IA gratuita que conversa e recomenda ONGs reais',
      'Análise de foto: envie a imagem do que quer doar e a IA identifica',
      'Histórico de conversas estilo ChatGPT (criar, buscar, fixar, renomear, excluir)',
      'Localização adaptável (entende a cidade ou o bairro citado)',
      'Memória do histórico de doações do usuário',
      'Enviar com Enter e Shift+Enter para nova linha nos chats',
    ],
  ),
  VersaoApp(
    versao: '1.6',
    titulo: 'Tempo real & Segurança extra',
    mudancas: [
      'Matches e interesses em tempo real',
      'Verificação em duas etapas (2FA) no login',
      'Alterar e-mail com confirmação de senha',
      'Agrupamento de doações por doador no painel',
      'Edição de necessidades e conversas concluídas viram histórico',
    ],
  ),
  VersaoApp(
    versao: '1.5',
    titulo: 'Comunidade & Controle',
    mudancas: [
      'Bloqueio de doador (estilo WhatsApp)',
      'Privacidade real (exibir/ocultar telefone e e-mail)',
      'Seleção de Estado e Cidade com base no IBGE (offline)',
      'Detalhe da necessidade e "demonstrar interesse novamente"',
      'Acessibilidade real (alto contraste e navegação simplificada)',
      '"Como chegar" e endereço no Google Maps',
    ],
  ),
  VersaoApp(
    versao: '1.4',
    titulo: 'Experiência renovada',
    mudancas: [
      'Redesenho completo do app do doador (Início viva, 5 abas)',
      'Matches em 3 abas (Ativas, Aguardando, Concluídas)',
      'Perfil público do doador com avaliação estilo Uber',
      'Prestação de contas rica (fotos e valor) com prazo de 10 dias',
      'PIX simulado em 2 fases e streak do Top 1',
      'Chat estilo WhatsApp (visto, online, digitando, reações, anexos)',
    ],
  ),
  VersaoApp(
    versao: '1.3',
    titulo: 'Segurança & Conformidade',
    mudancas: [
      'Login com JWT e autorização por dono',
      'LGPD (política, termos, consentimento) e papel de administrador',
      'Exclusão segura de conta (soft-delete)',
      '"Esqueci a senha" e limite de tentativas (anti força-bruta)',
    ],
  ),
  VersaoApp(
    versao: '1.2',
    titulo: 'Engajamento & Doações',
    mudancas: [
      'Feed inteligente com busca e filtros',
      'Campanhas de arrecadação',
      'Doação financeira via PIX (simulado)',
      'Timeline de atividades, Mural de impacto, Ranking de transparência, Conquistas e Favoritos',
      'Relatórios em PDF',
    ],
  ),
  VersaoApp(
    versao: '1.1',
    titulo: 'Confiança & Transparência',
    mudancas: [
      'Verificação de ONG (selo)',
      'Prestação de contas das doações',
      'Avaliações das ONGs',
      'Central de notificações',
    ],
  ),
  VersaoApp(
    versao: '1.0',
    titulo: 'Fundação & Match',
    mudancas: [
      'Cadastro de doadores e ONGs',
      'Publicação de necessidades',
      'Match entre doador e ONG (interesse e aceite)',
      'Chat entre as partes',
      'Painel de impacto, perfil e configurações',
    ],
  ),
];
