import 'package:flutter/foundation.dart';

import '../models/estoque_model.dart';
import 'package:api_compartilhado/api_compartilhado.dart';


enum EstadoEstoque { inicial, carregando, sucesso, erro }

class EstoqueProvider extends ChangeNotifier {
  final EstoqueService _service;

  EstoqueProvider({EstoqueService? service})
      : _service = service ?? EstoqueService();

  // ─── Estado exposto ───────────────────────────────────────────────────────

  EstadoEstoque estado = EstadoEstoque.inicial;
  EstoqueModel? estoque;
  String? erro;

  bool get carregando => estado == EstadoEstoque.carregando;

  PaginaMovimentos? paginaManuais;
  PaginaMovimentos? paginaTodos;

  // ─── Estoque ─────────────────────────────────────────────────────────────

  Future<void> carregar() async {
    _setCarregando();
    try {
      estoque = await _service.buscarActual();
      _setSucesso();
    } catch (e) {
      _setErro(e.toString());
    }
  }

  Future<bool> adicionar(
    double litros,
    int idUsuario, {
    String? motivo,
  }) async {
    _setCarregando();
    try {
      estoque = await _service.adicionar(litros, idUsuario, motivo: motivo);
      _setSucesso();
      return true;
    } catch (e) {
      _setErro(e.toString());
      return false;
    }
  }

  Future<bool> remover(
    double litros,
    int idUsuario, {
    String? motivo,
  }) async {
    _setCarregando();
    try {
      estoque = await _service.remover(litros, idUsuario, motivo: motivo);
      _setSucesso();
      return true;
    } catch (e) {
      _setErro(e.toString());
      return false;
    }
  }

  Future<bool> definir(
    double litros,
    int idUsuario, {
    String? observacao,
  }) async {
    _setCarregando();
    try {
      estoque = await _service.definir(litros, idUsuario, observacao: observacao);
      _setSucesso();
      return true;
    } catch (e) {
      _setErro(e.toString());
      return false;
    }
  }

  // ─── Movimentos paginados ────────────────────────────────────────────────

  Future<void> carregarManuais({int page = 0}) async {
    _setCarregando();
    try {
      paginaManuais = await _service.listarManuais(page: page);
      _setSucesso();
    } catch (e) {
      _setErro(e.toString());
    }
  }

  Future<void> carregarTodos({int page = 0}) async {
    _setCarregando();
    try {
      paginaTodos = await _service.listarTodos(page: page);
      _setSucesso();
    } catch (e) {
      _setErro(e.toString());
    }
  }

  // ─── Helpers de estado ────────────────────────────────────────────────────

  void _setCarregando() {
    estado = EstadoEstoque.carregando;
    erro = null;
    notifyListeners();
  }

  void _setSucesso() {
    estado = EstadoEstoque.sucesso;
    erro = null;
    notifyListeners();
  }

  void _setErro(String mensagem) {
    estado = EstadoEstoque.erro;
    erro = mensagem;
    notifyListeners();
  }
}