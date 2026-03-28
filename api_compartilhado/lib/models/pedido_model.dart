import 'package:decimal/decimal.dart';

/// Espelha [PedidoDTO.Response] do backend Java.
/// [troco] é coluna gerada: GREATEST(valor_pago - total, 0)
class PedidoModel {
  final int idPedido;
  final String? reference;

  // Dados do cliente (sem conta obrigatória — Regra 1)
  final String? nomeCliente;
  final String? telefoneCliente;
  final String? emailCliente;

  // Funcionário que registou o pedido (Regra 2)
  final int idUsuario;
  final String? nomeUsuario;    // ← novo
  final String? apelidoUsuario; // ← novo

  final int idOperacao;
  final String? nomeOperacao;
  final int idTipoPagamento;
  final String? nomeTipoPagamento;

  final DateTime dataPedido;
  final DateTime? dataFinalizacao;
  final String statusPedido;

  final Decimal total;
  final Decimal valorPago;

  // Readonly — calculado pelo banco (Regra 6)
  final Decimal? troco;

  // Entrega
  final String? endereco;
  final String? bairro;
  final String? pontoReferencia;
  final bool notificacaoVista;
  final bool ocultoCliente;
  final String? observacao;

  final List<ItemPedidoModel> itens;

  const PedidoModel({
    required this.idPedido,
    this.reference,
    this.nomeCliente,
    this.telefoneCliente,
    this.emailCliente,
    required this.idUsuario,
    this.nomeUsuario,
    this.apelidoUsuario,
    required this.idOperacao,
    this.nomeOperacao,
    required this.idTipoPagamento,
    this.nomeTipoPagamento,
    required this.dataPedido,
    this.dataFinalizacao,
    required this.statusPedido,
    required this.total,
    required this.valorPago,
    this.troco,
    this.endereco,
    this.bairro,
    this.pontoReferencia,
    this.notificacaoVista = false,
    this.ocultoCliente = false,
    this.observacao,
    this.itens = const [],
  });

  bool get isPendente   => statusPedido == 'pendente';
  bool get isFinalizado => statusPedido == 'finalizado';
  bool get isCancelado  => statusPedido == 'cancelado';

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    return PedidoModel(
      idPedido:          json['idPedido'] as int,
      reference:         json['reference'] as String?,
      nomeCliente:       json['nomeCliente'] as String?,
      telefoneCliente:   json['telefoneCliente'] as String?,
      emailCliente:      json['emailCliente'] as String?,
      idUsuario:         json['idUsuario'] as int,
      nomeUsuario:       json['nomeUsuario'] as String?,      // ← novo
      apelidoUsuario:    json['apelidoUsuario'] as String?,   // ← novo
      idOperacao:        json['idOperacao'] as int,
      nomeOperacao:      json['nomeOperacao'] as String?,
      idTipoPagamento:   json['idTipoPagamento'] as int,
      nomeTipoPagamento: json['nomeTipoPagamento'] as String?,
      dataPedido:        DateTime.parse(json['dataPedido'] as String),
      dataFinalizacao:   json['dataFinalizacao'] != null
          ? DateTime.parse(json['dataFinalizacao'] as String)
          : null,
      statusPedido:      json['statusPedido'] as String,
      total:             Decimal.parse(json['total'].toString()),
      valorPago:         Decimal.parse(json['valorPago'].toString()),
      troco:             json['troco'] != null
          ? Decimal.parse(json['troco'].toString())
          : null,
      endereco:          json['endereco'] as String?,
      bairro:            json['bairro'] as String?,
      pontoReferencia:   json['pontoReferencia'] as String?,
      notificacaoVista:  json['notificacaoVista'] as bool? ?? false,
      ocultoCliente:     json['ocultoCliente'] as bool? ?? false,
      observacao:        json['observacao'] as String?,
      itens: (json['itens'] as List<dynamic>? ?? [])
          .map((e) => ItemPedidoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'idPedido':          idPedido,
        'reference':         reference,
        'nomeCliente':       nomeCliente,
        'telefoneCliente':   telefoneCliente,
        'emailCliente':      emailCliente,
        'idUsuario':         idUsuario,
        'nomeUsuario':       nomeUsuario,
        'apelidoUsuario':    apelidoUsuario,
        'idOperacao':        idOperacao,
        'nomeOperacao':      nomeOperacao,
        'idTipoPagamento':   idTipoPagamento,
        'nomeTipoPagamento': nomeTipoPagamento,
        'dataPedido':        dataPedido.toIso8601String(),
        'dataFinalizacao':   dataFinalizacao?.toIso8601String(),
        'statusPedido':      statusPedido,
        'total':             total.toString(),
        'valorPago':         valorPago.toString(),
        'troco':             troco?.toString(),
        'endereco':          endereco,
        'bairro':            bairro,
        'pontoReferencia':   pontoReferencia,
        'notificacaoVista':  notificacaoVista,
        'ocultoCliente':     ocultoCliente,
        'observacao':        observacao,
        'itens':             itens.map((e) => e.toJson()).toList(),
      };

  PedidoModel copyWith({
    int? idPedido,
    String? reference,
    String? nomeCliente,
    String? telefoneCliente,
    String? emailCliente,
    int? idUsuario,
    String? nomeUsuario,
    String? apelidoUsuario,
    int? idOperacao,
    String? nomeOperacao,
    int? idTipoPagamento,
    String? nomeTipoPagamento,
    DateTime? dataPedido,
    DateTime? dataFinalizacao,
    String? statusPedido,
    Decimal? total,
    Decimal? valorPago,
    Decimal? troco,
    String? endereco,
    String? bairro,
    String? pontoReferencia,
    bool? notificacaoVista,
    bool? ocultoCliente,
    String? observacao,
    List<ItemPedidoModel>? itens,
  }) {
    return PedidoModel(
      idPedido:          idPedido          ?? this.idPedido,
      reference:         reference         ?? this.reference,
      nomeCliente:       nomeCliente       ?? this.nomeCliente,
      telefoneCliente:   telefoneCliente   ?? this.telefoneCliente,
      emailCliente:      emailCliente      ?? this.emailCliente,
      idUsuario:         idUsuario         ?? this.idUsuario,
      nomeUsuario:       nomeUsuario       ?? this.nomeUsuario,
      apelidoUsuario:    apelidoUsuario    ?? this.apelidoUsuario,
      idOperacao:        idOperacao        ?? this.idOperacao,
      nomeOperacao:      nomeOperacao      ?? this.nomeOperacao,
      idTipoPagamento:   idTipoPagamento   ?? this.idTipoPagamento,
      nomeTipoPagamento: nomeTipoPagamento ?? this.nomeTipoPagamento,
      dataPedido:        dataPedido        ?? this.dataPedido,
      dataFinalizacao:   dataFinalizacao   ?? this.dataFinalizacao,
      statusPedido:      statusPedido      ?? this.statusPedido,
      total:             total             ?? this.total,
      valorPago:         valorPago         ?? this.valorPago,
      troco:             troco             ?? this.troco,
      endereco:          endereco          ?? this.endereco,
      bairro:            bairro            ?? this.bairro,
      pontoReferencia:   pontoReferencia   ?? this.pontoReferencia,
      notificacaoVista:  notificacaoVista  ?? this.notificacaoVista,
      ocultoCliente:     ocultoCliente     ?? this.ocultoCliente,
      observacao:        observacao        ?? this.observacao,
      itens:             itens             ?? this.itens,
    );
  }

  @override
  String toString() =>
      'PedidoModel(id: $idPedido, status: $statusPedido, total: $total MT)';
}

/// Espelha [PedidoDTO.ItemResponse] do backend Java.
/// [subtotal] é coluna gerada: preco_unitario * quantidade — readonly.
class ItemPedidoModel {
  final int idItemPedido;
  final int idProduto;
  final String? nomeProduto;
  final int idOperacao;
  final String? nomeOperacao;
  final int quantidade;
  final Decimal litrosConsumidos;
  final Decimal precoUnitario;

  // Readonly — calculado pelo banco (Regra 6)
  final Decimal? subtotal;

  const ItemPedidoModel({
    required this.idItemPedido,
    required this.idProduto,
    this.nomeProduto,
    required this.idOperacao,
    this.nomeOperacao,
    required this.quantidade,
    required this.litrosConsumidos,
    required this.precoUnitario,
    this.subtotal,
  });

  factory ItemPedidoModel.fromJson(Map<String, dynamic> json) {
    return ItemPedidoModel(
      idItemPedido:      json['idItemPedido'] as int,
      idProduto:         json['idProduto'] as int,
      nomeProduto:       json['nomeProduto'] as String?,
      idOperacao:        json['idOperacao'] as int,
      nomeOperacao:      json['nomeOperacao'] as String?,
      quantidade:        json['quantidade'] as int,
      litrosConsumidos:  Decimal.parse(json['litrosConsumidos'].toString()),
      precoUnitario:     Decimal.parse(json['precoUnitario'].toString()),
      subtotal: json['subtotal'] != null
          ? Decimal.parse(json['subtotal'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'idItemPedido':     idItemPedido,
        'idProduto':        idProduto,
        'nomeProduto':      nomeProduto,
        'idOperacao':       idOperacao,
        'nomeOperacao':     nomeOperacao,
        'quantidade':       quantidade,
        'litrosConsumidos': litrosConsumidos.toString(),
        'precoUnitario':    precoUnitario.toString(),
        'subtotal':         subtotal?.toString(),
      };

  @override
  String toString() =>
      'ItemPedidoModel(produto: $idProduto, qtd: $quantidade, subtotal: $subtotal MT)';
}