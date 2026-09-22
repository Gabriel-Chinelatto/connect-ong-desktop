import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Documentos legais da plataforma (LGPD - Lei 13.709/2018).
///
/// Uma unica tela que exibe a Politica de Privacidade ou os Termos de Uso,
/// de acordo com o [tipo] informado. Usada tanto na Central de Configuracoes
/// quanto no fluxo de cadastro da ONG (consentimento).
enum DocumentoLegal { privacidade, termos }

class DocumentosLegaisScreen extends StatelessWidget {
  final DocumentoLegal tipo;

  const DocumentosLegaisScreen({super.key, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final doc = tipo == DocumentoLegal.privacidade
        ? _politicaPrivacidade
        : _termosDeUso;

    return Scaffold(
      appBar: AppBar(title: Text(doc.titulo)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              Text(
                doc.titulo,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ultima atualizacao: ${doc.atualizacao}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13),
              ),
              const SizedBox(height: 24),
              for (final s in doc.secoes) ...[
                Text(
                  s.titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.texto,
                  style: const TextStyle(fontSize: 15, height: 1.55),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// Conteudo dos documentos (compartilhado pela UI)
// =========================================================================

class _SecaoLegal {
  final String titulo;
  final String texto;
  const _SecaoLegal(this.titulo, this.texto);
}

class _DocumentoConteudo {
  final String titulo;
  final String atualizacao;
  final List<_SecaoLegal> secoes;
  const _DocumentoConteudo(this.titulo, this.atualizacao, this.secoes);
}

// Versão 2026-09-22: a MESMA gravada no aceite (Consentimento.VERSAO_ATUAL na
// API) e a do app do doador. Se o texto mudar, suba as três.
const _DocumentoConteudo _politicaPrivacidade = _DocumentoConteudo(
  'Política de Privacidade',
  'Setembro de 2026 (versão 2026-09-22)',
  [
    _SecaoLegal(
      '1. Quem somos',
      'O Connect ONG é uma plataforma que conecta doadores a organizações não '
          'governamentais (ONGs), facilitando doações de itens e financeiras. '
          'Esta política explica como tratamos dados pessoais, em conformidade '
          'com a Lei Geral de Proteção de Dados (LGPD — Lei 13.709/2018). O '
          'projeto é desenvolvido por estudantes do COTIL/UNICAMP; enquanto não '
          'houver uma pessoa jurídica operando a plataforma, a equipe do '
          'projeto responde como controladora e encarregada dos dados.',
    ),
    _SecaoLegal(
      '2. Dados que coletamos',
      'Da ONG: nome, e-mail, telefone, cidade, endereço, CNPJ (opcional), '
          'descrição, logo e fotos — dados institucionais, exibidos aos '
          'doadores. Da conta de acesso: e-mail e senha (guardada só como um '
          'resumo irreversível, BCrypt). Do uso: necessidades, campanhas, '
          'mensagens do chat, prestações de contas e avaliações. Segurança: '
          'registro de acessos (data e IP). Consentimento: a versão dos Termos '
          'e desta Política aceita no cadastro, com data e IP.',
    ),
    _SecaoLegal(
      '3. Por que usamos (bases legais)',
      'Para executar o serviço — publicar necessidades, receber interesses, '
          'conversar com doadores e prestar contas (LGPD, art. 7º, V). Com '
          'consentimento — exibir telefone e e-mail ao público (art. 7º, I). '
          'Por legítimo interesse — prevenir fraudes e proteger a conta '
          '(art. 7º, IX). Para cumprir a lei — o Marco Civil da Internet exige '
          'guardar registros de acesso por 6 meses (art. 7º, II).',
    ),
    _SecaoLegal(
      '4. Dados dos doadores que a ONG recebe',
      'Ao aceitar um interesse, a ONG passa a conversar com o doador e vê o '
          'que ele autorizou mostrar. Esses dados devem ser usados só para '
          'concluir a doação — não para outras finalidades, listas de contato '
          'ou repasse a terceiros.',
    ),
    _SecaoLegal(
      '5. Compartilhamento',
      'Usamos dois fornecedores fora do Brasil (art. 33): a hospedagem da API '
          '(Render, EUA) e o provedor de inteligência artificial (Groq, EUA). '
          'Antes de um texto ir para a IA, removemos e-mail, telefone, CPF e '
          'CNPJ. Não vendemos dados a ninguém.',
    ),
    _SecaoLegal(
      '6. Por quanto tempo guardamos',
      'Enquanto a conta existir. Ao excluir a conta, os dados pessoais da '
          'conta de acesso são anonimizados na mesma hora e a ONG deixa de '
          'aparecer na plataforma; o histórico de doações segue existindo sem '
          'identificar pessoas (art. 16). Registros de acesso ficam 6 meses.',
    ),
    _SecaoLegal(
      '7. Direitos (LGPD, art. 18)',
      'Acessar e levar os dados: Configurações › Privacidade e meus dados '
          '(mostra tudo e salva em JSON). Corrigir: Editar perfil da ONG. '
          'Excluir: Configurações › Zona de perigo. Revogar um consentimento: '
          'desligue a opção em Privacidade.',
    ),
    _SecaoLegal(
      '8. Segurança',
      'Telefones de pessoas, mensagens do chat e denúncias são guardados '
          'criptografados (AES-256-GCM). Senhas ficam em BCrypt e códigos de '
          'verificação em HMAC. A comunicação é por HTTPS, cada tela só mostra '
          'os dados do próprio dono e há limite de tentativas contra quem tenta '
          'adivinhar senhas. Mantenha a senha em sigilo e ative a verificação '
          'em duas etapas.',
    ),
    _SecaoLegal(
      '9. Contato',
      'Dúvidas sobre esta política ou pedidos sobre os dados: fale com a '
          'equipe do Connect ONG pelos canais oficiais do projeto.',
    ),
  ],
);

const _DocumentoConteudo _termosDeUso = _DocumentoConteudo(
  'Termos de Uso',
  'Junho de 2026',
  [
    _SecaoLegal(
      '1. Aceitacao',
      'Ao cadastrar a ONG e utilizar o Connect ONG, voce concorda com estes '
          'Termos de Uso e com a Politica de Privacidade. Se nao concordar, nao '
          'utilize a plataforma.',
    ),
    _SecaoLegal(
      '2. A plataforma',
      'O Connect ONG e uma ponte entre doadores e ONGs. Nao somos parte das '
          'doacoes em si: facilitamos o encontro e a comunicacao entre as '
          'partes. A responsabilidade pela entrega e pelo uso correto das '
          'doacoes e das partes envolvidas.',
    ),
    _SecaoLegal(
      '3. Responsabilidades da ONG',
      'A ONG se compromete a fornecer informacoes verdadeiras sobre a '
          'organizacao, manter a senha em sigilo, usar as doacoes para os fins '
          'declarados e respeitar os doadores. Informacoes falsas podem levar a '
          'suspensao da conta.',
    ),
    _SecaoLegal(
      '4. Conteudo e conduta',
      'E proibido publicar conteudo ofensivo, enganoso ou que desrespeite a '
          'dignidade de qualquer pessoa ou organizacao. Contas que '
          'descumprirem estas regras podem ser suspensas ou removidas.',
    ),
    _SecaoLegal(
      '5. Doacoes',
      'As doacoes registradas na plataforma sao um compromisso entre doador e '
          'ONG. O Connect ONG nao cobra taxas sobre doacoes e nao se '
          'responsabiliza por acordos firmados fora da plataforma.',
    ),
    _SecaoLegal(
      '6. Alteracoes',
      'Podemos atualizar estes Termos para refletir melhorias ou exigencias '
          'legais. Mudancas relevantes serao comunicadas dentro do sistema. O '
          'uso continuado apos as mudancas representa concordancia com a nova '
          'versao.',
    ),
  ],
);
