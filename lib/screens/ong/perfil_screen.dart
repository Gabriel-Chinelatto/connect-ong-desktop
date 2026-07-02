import 'package:flutter/material.dart';

import '../../config/config_controller.dart';
import '../../services/api_service.dart';
import '../../services/perfil_service.dart';
import '../../theme/app_colors.dart';

/// Perfil do usuario responsavel pela ONG.
///
/// Permite ver e editar os dados do perfil (nome, contato, bio, foto) e
/// alterar a senha, salvando via [PerfilService].
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final PerfilService _service = PerfilService();

  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _cidade = TextEditingController();
  final _estado = TextEditingController();
  final _bio = TextEditingController();
  final _fotoUrl = TextEditingController();

  int? _usuarioId;
  String _email = '';
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _cidade.dispose();
    _estado.dispose();
    _bio.dispose();
    _fotoUrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    _usuarioId = ConfigController.instance.usuarioId;
    if (_usuarioId == null) {
      setState(() => _carregando = false);
      return;
    }
    try {
      final p = await _service.obter(_usuarioId!);
      if (!mounted) return;
      setState(() {
        _email = p['email'] ?? '';
        _nome.text = p['nome'] ?? '';
        _telefone.text = p['telefone'] ?? '';
        _cidade.text = p['cidade'] ?? '';
        _estado.text = p['estado'] ?? '';
        _bio.text = p['bio'] ?? '';
        _fotoUrl.text = p['fotoUrl'] ?? '';
        _carregando = false;
      });
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    if (_usuarioId == null) return;
    setState(() => _salvando = true);
    try {
      await _service.atualizar(_usuarioId!, {
        'nome': _nome.text.trim(),
        'telefone': _telefone.text.trim(),
        'cidade': _cidade.text.trim(),
        'estado': _estado.text.trim(),
        'bio': _bio.text.trim(),
        'fotoUrl': _fotoUrl.text.trim(),
      });
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado! 💚'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.mensagemAmigavel(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iniciais = _nome.text.isNotEmpty ? _nome.text[0].toUpperCase() : '?';
    final foto = _fotoUrl.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.primary,
                        backgroundImage:
                            foto.isNotEmpty ? NetworkImage(foto) : null,
                        child: foto.isEmpty
                            ? Text(iniciais,
                                style: const TextStyle(
                                    fontSize: 40, color: Colors.white))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(child: Text(_email)),
                    const SizedBox(height: 24),
                    _campo(_nome, 'Nome'),
                    _campo(_telefone, 'Telefone'),
                    _campo(_cidade, 'Cidade'),
                    _campo(_estado, 'Estado'),
                    _campo(_bio, 'Bio', linhas: 3),
                    _campo(_fotoUrl, 'URL da foto (opcional)'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _salvando ? null : _salvar,
                        icon: _salvando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save),
                        label: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _campo(TextEditingController c, String label, {int linhas = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        maxLines: linhas,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
