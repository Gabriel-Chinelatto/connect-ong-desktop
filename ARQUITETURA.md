# Arquitetura - Connect ONG (Painel Desktop da ONG)

Documentacao interna do aplicativo **desktop** do Connect ONG. Foco em
**intencao, regras de negocio e tratamento de dados** - nao em detalhar
widget a widget.

## 1. Visao geral do produto

O **Connect ONG** e uma plataforma que conecta **DOADORES** a **ONGs**. Ela e
composta por **tres frontends** e um backend compartilhado:

- **App mobile (Flutter)** - aplicativo do **doador**.
- **App desktop (Flutter)** - **ESTE projeto**: o **painel administrativo da ONG**.
- **App web** - terceiro frontend.
- **API (Spring Boot)** - backend RESTful unico, com banco **MySQL**.

Todos os frontends falam com a mesma API. A API **exige autenticacao JWT**:
cada usuario/ONG so acessa os proprios dados.

## 2. Papel deste app (painel ADMIN da ONG)

Este desktop e a ferramenta de gestao da ONG. Pelo painel, a ONG:

1. **Cria necessidades e campanhas** (pedidos de doacao com meta/urgencia).
2. **Recebe interesses** de doadores nessas necessidades.
3. **Aceita ou recusa** cada interesse. Aceitar **vira um match** (libera o
   chat e a prestacao de contas); recusar descarta o interesse.
4. **Conversa no chat** do match com o doador.
5. **Presta contas** (mostra como a doacao foi usada: titulo, descricao, foto).
6. **Acompanha transparencia, ranking e conquistas** e gera **relatorios PDF**.

Regra de escopo: a ONG so opera os dados das **proprias** necessidades,
campanhas e matches - garantido pelo JWT enviado em cada requisicao.

## 3. Camadas

```
UI (lib/screens, lib/widgets)
        |  chama
Servicos (lib/services)  --- package http --->  API Spring Boot / MySQL
        |  converte JSON em
Modelos (lib/models)
```

- **UI - `lib/screens/` e `lib/widgets/`**: as telas (login, cadastro, painel
  da ONG, chat, configuracoes, perfil, mural de impacto, ranking, conquistas,
  perfil publico, notificacoes, documentos legais). Cada tela orquestra a
  navegacao e exibe os dados que recebe dos servicos.
- **Servicos - `lib/services/`**: toda a comunicacao HTTP com a API usando o
  pacote `http`. Cada servico mapeia um conjunto de endpoints (necessidades,
  interesses, mensagens, campanhas, prestacoes, perfil, preferencias, etc.) e
  converte o JSON da resposta em modelos.
- **Modelos - `lib/models/`**: classes simples (com `fromJson`) que espelham
  as entidades/DTOs do backend (Ong, Necessidade, Interesse, Mensagem,
  Campanha, Conquista, RankingOng, Preferencia, etc.).
- **Tema e config - `lib/theme/`, `lib/config/`**: paleta da marca, temas
  claro/escuro com ajustes de acessibilidade e o controlador de preferencias.

## 4. Gerenciamento de estado

- **`setState` por tela**: cada tela e um `StatefulWidget` que cuida do proprio
  estado local (carregando, listas, formularios). Padrao simples, sem framework
  de estado externo.
- **Singleton `ConfigController` (ChangeNotifier)** em `lib/config/`: estado
  **global** de preferencias (tema, tamanho de fonte, alto contraste, fonte
  para dislexia, notificacoes) e do **usuario logado** (`usuarioId`). O
  `MaterialApp` (em `lib/main.dart`) escuta esse controlador e se reconstroi
  quando as preferencias mudam, refletindo a alteracao no app inteiro.

## 5. Tratamento de dados e sessao

- **Login e JWT**: a tela de login chama `AuthService.login`
  (`POST /usuarios/login`). Em caso de sucesso, o **token JWT** retornado e
  capturado e guardado no `ApiService`.
- **Token em memoria (sem persistencia)**: o `ApiService` mantem o token
  **apenas em memoria**. O desktop **nao persiste sessao** - portanto o usuario
  **faz login a cada abertura** do app. (Existem ganchos `carregarToken` /
  `setToken` preparados para plugar `SharedPreferences` no futuro, hoje no-op.)
- **Autenticacao das requisicoes**: todas as chamadas a API enviam o cabecalho
  `Authorization: Bearer <accessToken>`, montado centralmente em
  `ApiService.jsonHeaders()` (POST/PUT com corpo JSON) e
  `ApiService.authHeaders()` (GET/DELETE).
- **Timeout de 10 segundos**: **toda** chamada HTTP usa
  `.timeout(const Duration(seconds: 10))`, para nao travar a UI se o servidor
  nao responder. Estouro de tempo e erros viram excecao (ou retorno
  vazio/false em alguns servicos), tratados pela tela.
- **Codificacao**: as respostas sao lidas com `utf8.decode(response.bodyBytes)`
  para preservar acentuacao do portugues.

## 6. Detalhes nao-obvios

- **Chat por polling (2s)**: a tela de chat (`chat_ong_screen`) recarrega as
  mensagens a cada **2 segundos** com um `Timer.periodic`, simulando tempo real
  ja que nao ha WebSocket. O timer e cancelado no `dispose`.
- **Identificacao da ONG pelo email**: apos o login, o app descobre qual ONG o
  usuario gerencia comparando o email; ha um seletor de fallback no painel.
- **Modo Feira (demo)**: `DemoService` pede ao backend para semear dados
  demonstrativos, util em apresentacoes.
- **Relatorio PDF**: gerado no proprio app (`relatorio_pdf_service`) a partir
  do perfil publico da ONG, sem endpoint dedicado.

## 7. Stack

- Flutter / Dart, pacote `http` para rede.
- `google_fonts` (Poppins; Lexend no modo dislexia), `flutter_svg`,
  pacotes `pdf` / `printing` para relatorios.
- Backend: Spring Boot + MySQL (repositorio separado).
