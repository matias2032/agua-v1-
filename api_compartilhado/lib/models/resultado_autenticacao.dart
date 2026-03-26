import 'usuario_model.dart';

enum StatusAutenticacao {
  sucesso,
  primeiraSenha,
  credenciaisInvalidas,
  erroDesconhecido,
}

class ResultadoAutenticacao {
  final StatusAutenticacao status;
  final String? mensagem;
  final UsuarioModel? usuario;

  const ResultadoAutenticacao({
    required this.status,
    this.mensagem,
    this.usuario,
  });
}