import 'package:decimal/decimal.dart';

/// Espelha [ProdutoDTO.Request] do backend Java.
/// Usado em POST /api/produtos e PUT /api/produtos/{id}
class ProdutoRequest {
  final String nomeProduto;
  final String? descricao;
  final Decimal precoCompra;
  final Decimal precoReenchimento;
  final Decimal capacidadeLitros;

  const ProdutoRequest({
    required this.nomeProduto,
    this.descricao,
    required this.precoCompra,
    required this.precoReenchimento,
    required this.capacidadeLitros,
  });

  Map<String, dynamic> toJson() => {
        'nomeProduto': nomeProduto,
        'descricao': descricao,
        'precoCompra': precoCompra.toStringAsFixed(2),
        'precoReenchimento': precoReenchimento.toStringAsFixed(2),
        'capacidadeLitros': capacidadeLitros.toStringAsFixed(3),
      };
}