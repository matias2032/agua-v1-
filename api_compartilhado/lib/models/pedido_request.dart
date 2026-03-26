import 'package:decimal/decimal.dart';

/// Espelha [PedidoDTO.Request] do backend Java.
/// Usado em POST /api/pedidos
class PedidoRequest {
  // Dados do cliente — opcionais (Regra 1: cliente não precisa ter conta)
  final String? nomeCliente;
  final String? telefoneCliente;
  final String? emailCliente;

  // id_usuario vem do header X-Usuario-Id (ou sessão) — nunca incluído aqui (Regra 2)
  final int idOperacao;
  final int idTipoPagamento;
  final List<ItemPedidoRequest> itens;
  final Decimal? valorPago;

  // Entrega — opcionais
  final String? endereco;
  final String? bairro;
  final String? pontoReferencia;
  final String? observacao;

  const PedidoRequest({
    this.nomeCliente,
    this.telefoneCliente,
    this.emailCliente,
    required this.idOperacao,
    required this.idTipoPagamento,
    required this.itens,
    this.valorPago,
    this.endereco,
    this.bairro,
    this.pontoReferencia,
    this.observacao,
  });

  Map<String, dynamic> toJson() => {
        if (nomeCliente != null) 'nomeCliente': nomeCliente,
        if (telefoneCliente != null) 'telefoneCliente': telefoneCliente,
        if (emailCliente != null) 'emailCliente': emailCliente,
        'idOperacao': idOperacao,
        'idTipoPagamento': idTipoPagamento,
        'itens': itens.map((e) => e.toJson()).toList(),
        if (valorPago != null) 'valorPago': valorPago!.toStringAsFixed(2),
        if (endereco != null) 'endereco': endereco,
        if (bairro != null) 'bairro': bairro,
        if (pontoReferencia != null) 'pontoReferencia': pontoReferencia,
        if (observacao != null) 'observacao': observacao,
      };
}

/// Espelha [PedidoDTO.ItemRequest] do backend Java.
class ItemPedidoRequest {
  final int idProduto;
  final int quantidade;

  /// Opcional — herda a operação do pedido se não informado (Regra 3)
  final int? idOperacao;

  const ItemPedidoRequest({
    required this.idProduto,
    required this.quantidade,
    this.idOperacao,
  });

  Map<String, dynamic> toJson() => {
        'idProduto': idProduto,
        'quantidade': quantidade,
        if (idOperacao != null) 'idOperacao': idOperacao,
      };
}

/// Espelha [PedidoDTO.CancelamentoRequest] do backend Java.
class CancelamentoPedidoRequest {
  final String? motivo;

  const CancelamentoPedidoRequest({this.motivo});

  Map<String, dynamic> toJson() => {
        if (motivo != null) 'motivo': motivo,
      };
}

/// Espelha [PedidoDTO.ValorPagoRequest] do backend Java.
class ValorPagoRequest {
  final Decimal valorPago;

  const ValorPagoRequest({required this.valorPago});

  Map<String, dynamic> toJson() => {
        'valorPago': valorPago.toStringAsFixed(2),
      };
}