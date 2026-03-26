import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _credencialCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _enviando = false;
  bool _mostrarSenha = false;
  String? _erro;

  final _servico = ServicoAutenticacao();

  @override
  void dispose() {
    _credencialCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enviando = true;
      _erro = null;
    });

    final resultado = await _servico.login(
      _credencialCtrl.text.trim(),
      _senhaCtrl.text,
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    switch (resultado.status) {
      case StatusAutenticacao.sucesso:
        await SessaoService.instance.setUsuario(resultado.usuario!);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/menu');

      case StatusAutenticacao.primeiraSenha:
        await SessaoService.instance.setUsuario(resultado.usuario!);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/primeira_troca_senha');

      case StatusAutenticacao.credenciaisInvalidas:
      case StatusAutenticacao.erroDesconhecido:
        setState(() => _erro = resultado.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Ícone / Logo ──────────────────────────────────────
                  Icon(
                    Icons.water_drop_outlined,
                    size: 72,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sistema de Água',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Faça login para continuar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 40),

                  // ─── Campo credencial ──────────────────────────────────
                  TextFormField(
                    controller: _credencialCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email, telefone ou apelido',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),

                  // ─── Campo senha ───────────────────────────────────────
                  TextFormField(
                    controller: _senhaCtrl,
                    obscureText: !_mostrarSenha,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarSenha
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _mostrarSenha = !_mostrarSenha),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 12),

                  // ─── Mensagem de erro ──────────────────────────────────
                  if (_erro != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 18, color: colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _erro!,
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ─── Botão entrar ──────────────────────────────────────
                  FilledButton.icon(
                    icon: _enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login),
                    label: Text(_enviando ? 'A entrar…' : 'Entrar'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _enviando ? null : _login,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}