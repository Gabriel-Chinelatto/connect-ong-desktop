import 'package:flutter/material.dart';

import '../../config/config_controller.dart';
import '../../models/preferencia.dart';
import '../../services/perfil_service.dart';
import '../../theme/app_colors.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  late Preferencia _p;

  @override
  void initState() {
    super.initState();
    _p = ConfigController.instance.prefs.copy();
  }

  void _aplicar() {
    setState(() {});
    ConfigController.instance.atualizar(_p.copy());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _secao('Aparência', Icons.palette_outlined),
              _escolha('Tema', const ['CLARO', 'ESCURO', 'AUTOMATICO'],
                  const ['Claro', 'Escuro', 'Automático'], _p.tema, (v) {
                _p.tema = v;
                _aplicar();
              }),
              _escolha('Tamanho da fonte', const ['PEQUENA', 'MEDIA', 'GRANDE'],
                  const ['Pequena', 'Média', 'Grande'], _p.tamanhoFonte, (v) {
                _p.tamanhoFonte = v;
                _aplicar();
              }),
              _switch('Alto contraste', 'Mais contraste para leitura',
                  _p.altoContraste, (v) {
                _p.altoContraste = v;
                _aplicar();
              }),
              _switch('Fonte para dislexia', 'Usa uma fonte mais legível',
                  _p.fonteDislexia, (v) {
                _p.fonteDislexia = v;
                _aplicar();
              }),
              _switch('Navegação simplificada', 'Modo mais simples de usar',
                  _p.navegacaoSimplificada, (v) {
                _p.navegacaoSimplificada = v;
                _aplicar();
              }),
              _secao('Notificações', Icons.notifications_outlined),
              _switch('Novas mensagens', null, _p.notifMensagens, (v) {
                _p.notifMensagens = v;
                _aplicar();
              }),
              _switch('Match de doações', null, _p.notifMatch, (v) {
                _p.notifMatch = v;
                _aplicar();
              }),
              _switch('Atualizações de campanhas', null, _p.notifCampanhas, (v) {
                _p.notifCampanhas = v;
                _aplicar();
              }),
              _switch('Novas necessidades', null, _p.notifNecessidades, (v) {
                _p.notifNecessidades = v;
                _aplicar();
              }),
              _switch('Notícias da plataforma', null, _p.notifNoticias, (v) {
                _p.notifNoticias = v;
                _aplicar();
              }),
              _secao('Privacidade', Icons.lock_outline),
              _switch('Exibir telefone', null, _p.mostrarTelefone, (v) {
                _p.mostrarTelefone = v;
                _aplicar();
              }),
              _switch('Exibir e-mail', null, _p.mostrarEmail, (v) {
                _p.mostrarEmail = v;
                _aplicar();
              }),
              _switch('Perfil público', null, _p.perfilPublico, (v) {
                _p.perfilPublico = v;
                _aplicar();
              }),
              _switch('Receber sugestões', null, _p.receberSugestoes, (v) {
                _p.receberSugestoes = v;
                _aplicar();
              }),
              _secao('Segurança', Icons.shield_outlined),
              ListTile(
                leading: const Icon(Icons.password),
                title: const Text('Alterar senha'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _abrirAlterarSenha,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secao(String titulo, IconData icone) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Icon(icone, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(titulo,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _switch(String titulo, String? subtitulo, bool valor,
      ValueChanged<bool> onChange) {
    return SwitchListTile(
      title: Text(titulo),
      subtitle: subtitulo == null ? null : Text(subtitulo),
      value: valor,
      activeThumbColor: AppColors.primary,
      onChanged: onChange,
    );
  }

  Widget _escolha(String titulo, List<String> valores, List<String> rotulos,
      String selecionado, ValueChanged<String> onChange) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(titulo),
          ),
          Wrap(
            spacing: 8,
            children: List.generate(valores.length, (i) {
              final sel = valores[i] == selecionado;
              return ChoiceChip(
                label: Text(rotulos[i]),
                selected: sel,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: sel ? Colors.white : null),
                onSelected: (_) => onChange(valores[i]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirAlterarSenha() async {
    final atual = TextEditingController();
    final nova = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final usuarioId = ConfigController.instance.usuarioId;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: atual,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Informe a senha atual' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nova,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                validator: (v) =>
                    (v == null || v.length < 4) ? 'Mínimo 4 caracteres' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              if (usuarioId == null) return;
              try {
                await PerfilService()
                    .alterarSenha(usuarioId, atual.text, nova.text);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Senha alterada com sucesso! 💚'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content:
                        Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
