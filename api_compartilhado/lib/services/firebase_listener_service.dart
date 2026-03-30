// lib/services/firebase_listener_service.dart
//
// Subscreve as colecções Firestore e expõe streams para os providers.
// O Flutter escuta estes streams e actualiza o UI em tempo real.
//
// Dependências (pubspec.yaml):
//   firebase_core: ^3.x.x
//   cloud_firestore: ^5.x.x

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Modelo leve que representa um pedido recebido do Firestore.
/// Mapeado directamente do documento — sem conversão extra.
class PedidoFirestore {
  final int idPedido;
  final String? reference;
  final String? nomeCliente;
  final String? telefoneCliente;
  final String statusPedido;
  final double total;
  final double valorPago;
  final double? troco;
  final DateTime dataPedido;
  final DateTime? dataFinalizacao;
  final int idUsuario;
  final int idOperacao;
  final int idTipoPagamento;
  final List<Map<String, dynamic>> itens;

  const PedidoFirestore({
    required this.idPedido,
    this.reference,
    this.nomeCliente,
    this.telefoneCliente,
    required this.statusPedido,
    required this.total,
    required this.valorPago,
    this.troco,
    required this.dataPedido,
    this.dataFinalizacao,
    required this.idUsuario,
    required this.idOperacao,
    required this.idTipoPagamento,
    required this.itens,
  });

  factory PedidoFirestore.fromMap(Map<String, dynamic> map) {
    return PedidoFirestore(
      idPedido:        (map['idPedido'] as num).toInt(),
      reference:       map['reference'] as String?,
      nomeCliente:     map['nomeCliente'] as String?,
      telefoneCliente: map['telefoneCliente'] as String?,
      statusPedido:    (map['statusPedido'] as String?) ?? 'pendente',
      total:           (map['total'] as num?)?.toDouble() ?? 0.0,
      valorPago:       (map['valorPago'] as num?)?.toDouble() ?? 0.0,
      troco:           (map['troco'] as num?)?.toDouble(),
      dataPedido:      _toDateTime(map['dataPedido']),
      dataFinalizacao: map['dataFinalizacao'] != null
                          ? _toDateTime(map['dataFinalizacao'])
                          : null,
      idUsuario:       (map['idUsuario'] as num).toInt(),
      idOperacao:      (map['idOperacao'] as num).toInt(),
      idTipoPagamento: (map['idTipoPagamento'] as num).toInt(),
      itens:           (map['itens'] as List<dynamic>?)
                          ?.cast<Map<String, dynamic>>() ?? [],
    );
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}

/// Modelo do snapshot de estoque recebido do Firestore.
class EstoqueFirestore {
  final int idEstoque;
  final double litrosDisponiveis;
  final DateTime ultimaAtualizacao;
  final String? observacao;

  const EstoqueFirestore({
    required this.idEstoque,
    required this.litrosDisponiveis,
    required this.ultimaAtualizacao,
    this.observacao,
  });

  factory EstoqueFirestore.fromMap(Map<String, dynamic> map) {
    return EstoqueFirestore(
      idEstoque:          (map['idEstoque'] as num).toInt(),
      litrosDisponiveis:  (map['litrosDisponiveis'] as num?)?.toDouble() ?? 0.0,
      ultimaAtualizacao:  PedidoFirestore._toDateTime(map['ultimaAtualizacao']),
      observacao:         map['observacao'] as String?,
    );
  }
}

class UsuarioFirestore {
  final int idUsuario;
  final String nome;
  final String apelido;
  final String email;
  final String telefone;
  final bool ativo;
  final int idPerfil;
  final bool primeiraSenha;
  final DateTime dataCadastro;

  const UsuarioFirestore({
    required this.idUsuario,
    required this.nome,
    required this.apelido,
    required this.email,
    required this.telefone,
    required this.ativo,
    required this.idPerfil,
    required this.primeiraSenha,
    required this.dataCadastro,
  });

  factory UsuarioFirestore.fromMap(Map<String, dynamic> map) => UsuarioFirestore(
    idUsuario:     (map['idUsuario'] as num).toInt(),
    nome:          map['nome'] as String? ?? '',
    apelido:       map['apelido'] as String? ?? '',
    email:         map['email'] as String? ?? '',
    telefone:      map['telefone'] as String? ?? '',
    ativo:         map['ativo'] as bool? ?? false,
    idPerfil:      (map['idPerfil'] as num).toInt(),
    primeiraSenha: map['primeiraSenha'] as bool? ?? false,
    dataCadastro:  PedidoFirestore._toDateTime(map['dataCadastro']),
  );
}

/// Serviço singleton que gere as subscrições ao Firestore.
///
/// Uso típico num Provider/ChangeNotifier:
///   final stream = FirebaseListenerService.instance.pedidosStream;
///   stream.listen((pedidos) => setState(() => _pedidos = pedidos));
class FirebaseListenerService {
  static final FirebaseListenerService instance =
      FirebaseListenerService._internal();
  factory FirebaseListenerService() => instance;
  FirebaseListenerService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ─── Stream: lista de todos os pedidos (ordenada por data, desc) ──────────

  /// Emite a lista completa sempre que qualquer pedido é criado/alterado.
  /// Filtra por [status] se fornecido (ex: 'pendente').
  Stream<List<PedidoFirestore>> pedidosStream({String? status}) {
    Query<Map<String, dynamic>> query = _db
        .collection('pedidos')
        .orderBy('dataPedido', descending: true);

    if (status != null && status.isNotEmpty) {
      query = query.where('statusPedido', isEqualTo: status);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((doc) => PedidoFirestore.fromMap(doc.data()))
        .toList());
  }

  /// Stream de um único pedido por ID.
  Stream<PedidoFirestore?> pedidoByIdStream(int idPedido) {
    return _db
        .collection('pedidos')
        .doc(idPedido.toString())
        .snapshots()
        .map((snap) {
          if (!snap.exists || snap.data() == null) return null;
          return PedidoFirestore.fromMap(snap.data()!);
        });
  }

  // ─── Stream: estoque actual ───────────────────────────────────────────────

  /// Emite o snapshot de estoque sempre que o backend o actualiza.
  Stream<EstoqueFirestore?> estoqueStream() {
    return _db
        .collection('estoque')
        .doc('atual')
        .snapshots()
        .map((snap) {
          if (!snap.exists || snap.data() == null) return null;
          return EstoqueFirestore.fromMap(snap.data()!);
        });
  }

  // ─── Leitura pontual (sem stream) ────────────────────────────────────────

  /// Lê o estoque uma única vez (para modo offline / cache inicial).
  Future<EstoqueFirestore?> lerEstoqueUmaVez() async {
    try {
      final snap = await _db
          .collection('estoque')
          .doc('atual')
          .get(const GetOptions(source: Source.serverAndCache));

      if (!snap.exists || snap.data() == null) return null;
      return EstoqueFirestore.fromMap(snap.data()!);
    } catch (_) {
      return null;
    }
  }

  /// Lê a lista de pedidos uma única vez (do cache se offline).
  Future<List<PedidoFirestore>> lerPedidosUmaVez({String? status}) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('pedidos')
          .orderBy('dataPedido', descending: true);

      if (status != null && status.isNotEmpty) {
        query = query.where('statusPedido', isEqualTo: status);
      }

      final snap = await query.get(
          const GetOptions(source: Source.serverAndCache));

      return snap.docs
          .map((doc) => PedidoFirestore.fromMap(doc.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Stream<List<UsuarioFirestore>> usuariosStream({bool? apenasAtivos}) {
  Query<Map<String, dynamic>> query = _db
      .collection('usuarios')
      .orderBy('nome');

  if (apenasAtivos == true) {
    query = query.where('ativo', isEqualTo: true);
  }

  return query.snapshots().map((snap) => snap.docs
      .map((doc) => UsuarioFirestore.fromMap(doc.data()))
      .toList());
}


}