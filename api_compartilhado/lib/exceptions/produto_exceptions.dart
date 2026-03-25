/// Lançada quando o servidor retorna 404 para um produto.
class ProdutoNaoEncontradoException implements Exception {
  final String mensagem;
  const ProdutoNaoEncontradoException(this.mensagem);

  @override
  String toString() => 'ProdutoNaoEncontradoException: $mensagem';
}

/// Lançada quando o servidor retorna 404 para uma operação.
class OperacaoNaoEncontradaException implements Exception {
  final String mensagem;
  const OperacaoNaoEncontradaException(this.mensagem);

  @override
  String toString() => 'OperacaoNaoEncontradaException: $mensagem';
}

/// Lançada quando a API retorna 422 (erro de validação do backend).
class ProdutoValidacaoException implements Exception {
  final String mensagem;
  const ProdutoValidacaoException(this.mensagem);

  @override
  String toString() => 'ProdutoValidacaoException: $mensagem';
}

/// Lançada para qualquer erro HTTP inesperado (5xx, timeout, etc.).
class ProdutoServiceException implements Exception {
  final String mensagem;
  final int? statusCode;

  const ProdutoServiceException(this.mensagem, {this.statusCode});

  @override
  String toString() =>
      'ProdutoServiceException[$statusCode]: $mensagem';
}