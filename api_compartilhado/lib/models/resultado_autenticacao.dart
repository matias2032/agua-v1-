// lib/models/resultado_autenticacao.dart

import 'usuario_model.dart';

/// Status possíveis retornados pelo ServicoAutenticacao
enum StatusAutenticacao {
  sucesso,
  primeiraSenha,
  credenciaisInvalidas,
  usuarioNaoEncontrado,
  contaInativa,
  erroDesconhecido,
}

/// Resultado encapsulado do processo de autenticação
/// Compatível com tela_login.dart e primeira_troca_senha.dart
class ResultadoAutenticacao {
  final StatusAutenticacao status;
  final String mensagem;
  final UsuarioModel? usuario;

  ResultadoAutenticacao({
    required this.status,
    required this.mensagem,
    this.usuario,
  });

  /// Atalho: login foi bem-sucedido e não é primeira senha
  bool get isSuccesso => status == StatusAutenticacao.sucesso;

  /// Atalho: precisa trocar senha obrigatoriamente
  bool get isPrimeiraSenha => status == StatusAutenticacao.primeiraSenha;

  /// Atalho: houve qualquer tipo de falha
  bool get isFalha =>
      status == StatusAutenticacao.credenciaisInvalidas ||
      status == StatusAutenticacao.usuarioNaoEncontrado ||
      status == StatusAutenticacao.contaInativa ||
      status == StatusAutenticacao.erroDesconhecido;
}