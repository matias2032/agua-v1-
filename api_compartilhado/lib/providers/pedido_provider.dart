import 'package:flutter/foundation.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

import '../models/pedido_model.dart';
import '../models/pedido_request.dart';
import '../services/pedido_service.dart';

const _tag = 'PedidoProvider';

class PedidoProvider extends ChangeNotifier {
  final PedidoService _service;

  PedidoProvider({PedidoService? service})
      : _service = service ?? PedidoService.instance;

  // ── Estado ───────────────────────────────────────────────────────────────

  List<PedidoModel> _pedidos = [];
  PedidoModel? _pedidoActual;
  bool _carregando = false;
  String? _erro;

  // Paginação
  int _paginaActual = 0;
  int _totalPaginas = 0;
  int _totalElementos = 0;

  // Getters
  List<PedidoModel> get pedidos => List.unmodifiable(_pedidos);
  PedidoModel? get pedidoActual => _pedidoActual;
  bool get carregando => _carregando;
  String? get erro => _erro;
  bool get temErro => _erro != null;
  int get paginaActual => _paginaActual;
  int get totalPaginas => _totalPaginas;
  int get totalElementos => _totalElementos;
  bool get temProximaPagina => _paginaActual < _totalPaginas - 1;

  // ── Leituras ─────────────────────────────────────────────────────────────

  /// Carrega a primeira página de pedidos, com filtro de status opcional.
  Future<void> carregar({String? status, int size = 20}) async {
    _setCarregando(true);
    _paginaActual = 0;
    try {
      final pagina = await _service.listar(
          status: status, page: 0, size: size);
      _pedidos = pagina.conteudo;
      _totalPaginas = pagina.totalPaginas;
      _totalElementos = pagina.totalElementos;
      _setErro(null);
      AppLogger.info(_tag, 'Carregados ${_pedidos.length} pedidos');
    } catch (e) {
      _setErro(e.toString());
      AppLogger.error(_tag, 'Erro ao carregar pedidos: $e');
    } finally {
      _setCarregando(false);
    }
  }

  /// Carrega a próxima página e acrescenta à lista existente.
  Future<void> carregarMais({String? status, int size = 20}) async {
    if (!temProximaPagina || _carregando) return;
    _setCarregando(true);
    try {
      final proxima = _paginaActual + 1;
      final pagina = await _service.listar(
          status: status, page: proxima, size: size);
      _pedidos = [..._pedidos, ...pagina.conteudo];
      _paginaActual = proxima;
      _totalPaginas = pagina.totalPaginas;
      _setErro(null);
    } catch (e) {
      _setErro(e.toString());
      AppLogger.error(_tag, 'Erro ao carregar mais pedidos: $e');
    } finally {
      _setCarregando(false);
    }
  }

  /// Busca um pedido específico com todos os itens.
  Future<void> buscarPorId(int id) async {
    _setCarregando(true);
    try {
      _pedidoActual = await _service.buscarPorId(id);
      _setErro(null);
      AppLogger.info(_tag, 'Pedido $id carregado');
    } catch (e) {
      _setErro(e.toString());
      AppLogger.error(_tag, 'Erro ao buscar pedido $id: $e');
    } finally {
      _setCarregando(false);
    }
  }

  /// Lista pedidos de um funcionário específico.
  Future<List<PedidoModel>> listarPorUsuario(int idUsuario) async {
    _setCarregando(true);
    try {
      final lista = await _service.listarPorUsuario(idUsuario);
      _setErro(null);
      return lista;
    } catch (e) {
      _setErro(e.toString());
      AppLogger.error(_tag, 'Erro ao listar pedidos do utilizador $idUsuario: $e');
      return [];
    } finally {
      _setCarregando(false);
    }
  }

  // ── Mutações ─────────────────────────────────────────────────────────────

  /// Cria um novo pedido. Retorna o pedido criado ou null em caso de erro.
  Future<PedidoModel?> criar(PedidoRequest request, int idUsuario) async {
    _setCarregando(true);
    try {
      final novo = await _service.criar(request, idUsuario);
      _pedidos = [novo, ..._pedidos];
      _pedidoActual = novo;
      _setErro(null);
      AppLogger.info(_tag, 'Pedido criado: id=${novo.idPedido}');
      return novo;
    } catch (e) {
      _setErro(e.toString());
      AppLogger.error(_tag, 'Erro ao criar pedido: $e');
      return null;
    } finally {
      _setCarregando(false);
    }
  }

  /// Finaliza um pedido. Actualiza o estado local.
  Future<bool> finalizar(int id) async {
    _setCarregando(true);
    try {
      final actualizado = await _service.finalizar(id);
      _actualizarNaLista(actualizado);
      if (_pedidoActual?.idPedido == id) _pedidoActual = actualizado;
      _setErro(null);
      AppLogger.info(_tag, 'Pedido $id finalizado');
      return true;
    } catch (e) {
      _setErro(e.toString());
      AppLogger.error(_tag, 'Erro ao finalizar pedido $id: $e');
      return false;
    } finally {
      _setCarregando(false);
    }
  }

  /// Regista o valor pago num pedido. Actualiza o estado local.
  Future<bool> actualizarValorPago(int id, ValorPagoRequest request) async {
    _setCarregando(true);
    try {
      final actualizado = await _service.actualizarValorPago(id, request);
      _actualizarNaLista(actualizado);
      if (_pedidoActual?.idPedido == id) _pedidoActual = actualizado;
      _setErro(null);
      return true;
    } catch (e) {
      _setErro(e.toString());
      AppLogger.error(_tag, 'Erro ao actualizar valor pago do pedido $id: $e');
      return false;
    } finally {
      _setCarregando(false);
    }
  }

  /// Cancela um pedido. Remove da lista local se a filtragem excluir cancelados.
  Future<bool> cancelar(
    int id,
    CancelamentoPedidoRequest request,
    int idUsuario,
  ) async {
    _setCarregando(true);
    try {
      final actualizado = await _service.cancelar(id, request, idUsuario);
      _actualizarNaLista(actualizado);
      if (_pedidoActual?.idPedido == id) _pedidoActual = actualizado;
      _setErro(null);
      AppLogger.info(_tag, 'Pedido $id cancelado');
      return true;
    } catch (e) {
      _setErro(e.toString());
      AppLogger.error(_tag, 'Erro ao cancelar pedido $id: $e');
      return false;
    } finally {
      _setCarregando(false);
    }
  }

  // ── Auxiliares ────────────────────────────────────────────────────────────

  void limparErro() {
    _erro = null;
    notifyListeners();
  }

  void limparPedidoActual() {
    _pedidoActual = null;
    notifyListeners();
  }

  void _setCarregando(bool valor) {
    _carregando = valor;
    notifyListeners();
  }

  void _setErro(String? valor) {
    _erro = valor;
  }

  void _actualizarNaLista(PedidoModel actualizado) {
    _pedidos = _pedidos.map((p) {
      return p.idPedido == actualizado.idPedido ? actualizado : p;
    }).toList();
  }
}