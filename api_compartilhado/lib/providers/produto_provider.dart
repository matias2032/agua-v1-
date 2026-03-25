import 'package:flutter/foundation.dart';

import '../exceptions/produto_exceptions.dart';
import '../models/disponibilidade_produto_model.dart';
import '../models/operacao_model.dart';
import '../models/preco_produto_model.dart';
import '../models/produto_model.dart';
import '../models/produto_request.dart';
import '../services/produto_service.dart';
import '../utils/app_logger.dart';

const _tag = 'ProdutoProvider';

enum EstadoCarregamento { inicial, carregando, sucesso, erro }

class ProdutoProvider extends ChangeNotifier {
  final ProdutoService _service;

  ProdutoProvider({ProdutoService? service})
      : _service = service ?? ProdutoService.instance;

  // ── Estado ────────────────────────────────────────────────────────────────

  EstadoCarregamento _estado = EstadoCarregamento.inicial;
  EstadoCarregamento get estado => _estado;

  String? _mensagemErro;
  String? get mensagemErro => _mensagemErro;

  List<DisponibilidadeProdutoModel> _produtos = [];
  List<DisponibilidadeProdutoModel> get produtos => _produtos;

  List<ProdutoModel> _todosProdutos = [];
  List<ProdutoModel> get todosProdutos => _todosProdutos;

  List<OperacaoModel> _operacoes = [];
  List<OperacaoModel> get operacoes => _operacoes;

  PrecoProdutoModel? _precoCalculado;
  PrecoProdutoModel? get precoCalculado => _precoCalculado;

  bool get carregando => _estado == EstadoCarregamento.carregando;

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _iniciarCarregamento() {
    _estado = EstadoCarregamento.carregando;
    _mensagemErro = null;
    notifyListeners();
  }

  void _definirSucesso() {
    _estado = EstadoCarregamento.sucesso;
    notifyListeners();
  }

  void _definirErro(Object e) {
    _estado = EstadoCarregamento.erro;
    if (e is ProdutoNaoEncontradoException) {
      _mensagemErro = e.mensagem;
    } else if (e is ProdutoValidacaoException) {
      _mensagemErro = 'Validação: ${e.mensagem}';
    } else if (e is ProdutoServiceException) {
      _mensagemErro = e.mensagem;
    } else {
      _mensagemErro = 'Erro inesperado: $e';
    }
    AppLogger.error(_tag, _mensagemErro!, e);
    notifyListeners();
  }

  // ── Ações CRUD ─────────────────────────────────────────────────────────────

  Future<void> carregarProdutos() async {
    AppLogger.info(_tag, 'carregarProdutos iniciado');
    _iniciarCarregamento();
    try {
      _produtos = await _service.listarProdutos();
      AppLogger.info(_tag, 'carregarProdutos → ${_produtos.length} produtos');
      _definirSucesso();
    } catch (e) {
      _definirErro(e);
    }
  }

  Future<void> carregarTodos() async {
    AppLogger.info(_tag, 'carregarTodos iniciado');
    _iniciarCarregamento();
    try {
      _todosProdutos = await _service.listarTodos();
      AppLogger.info(_tag, 'carregarTodos → ${_todosProdutos.length} produtos');
      _definirSucesso();
    } catch (e) {
      _definirErro(e);
    }
  }

  Future<void> carregarOperacoes() async {
    if (_operacoes.isNotEmpty) return;
    AppLogger.info(_tag, 'carregarOperacoes iniciado');
    try {
      _operacoes = await _service.listarOperacoes();
      AppLogger.info(_tag, 'carregarOperacoes → ${_operacoes.length} ops');
      notifyListeners();
    } catch (e) {
      AppLogger.error(_tag, 'Falha ao carregar operações', e);
    }
  }

  /// Retorna true em caso de sucesso.
  Future<bool> criarProduto(ProdutoRequest request) async {
    AppLogger.info(_tag, 'criarProduto: ${request.nomeProduto}');
    _iniciarCarregamento();
    try {
      final novo = await _service.criar(request);
      AppLogger.info(_tag, 'Produto criado: id=${novo.idProduto}');
      await carregarProdutos();
      return true;
    } catch (e) {
      _definirErro(e);
      return false;
    }
  }

  Future<bool> atualizarProduto(int id, ProdutoRequest request) async {
    AppLogger.info(_tag, 'atualizarProduto id=$id');
    _iniciarCarregamento();
    try {
      final atualizado = await _service.atualizar(id, request);
      AppLogger.info(_tag, 'Produto atualizado: ${atualizado.nomeProduto}');
      await carregarProdutos();
      return true;
    } catch (e) {
      _definirErro(e);
      return false;
    }
  }

  Future<bool> ativarProduto(int id) async {
    AppLogger.info(_tag, 'ativarProduto id=$id');
    _iniciarCarregamento();
    try {
      await _service.ativar(id);
      AppLogger.info(_tag, 'Produto id=$id ativado');
      await carregarProdutos();
      return true;
    } catch (e) {
      _definirErro(e);
      return false;
    }
  }

  Future<bool> desativarProduto(int id) async {
    AppLogger.info(_tag, 'desativarProduto id=$id');
    _iniciarCarregamento();
    try {
      await _service.desativar(id);
      AppLogger.info(_tag, 'Produto id=$id desativado');
      await carregarProdutos();
      return true;
    } catch (e) {
      _definirErro(e);
      return false;
    }
  }

  Future<void> calcularPreco(
      {required int idProduto, required int idOperacao}) async {
    AppLogger.info(
        _tag, 'calcularPreco produto=$idProduto operacao=$idOperacao');
    _iniciarCarregamento();
    try {
      _precoCalculado = await _service.calcularPreco(
        idProduto: idProduto,
        idOperacao: idOperacao,
      );
      AppLogger.info(
          _tag, 'Preço calculado: ${_precoCalculado!.precoFinal} MT');
      _definirSucesso();
    } catch (e) {
      _definirErro(e);
    }
  }

  void limparErro() {
    _mensagemErro = null;
    _estado = EstadoCarregamento.inicial;
    notifyListeners();
  }
}