package com.agua.versao1.produto.controller;

import com.agua.versao1.produto.dto.OperacaoDTO;
import com.agua.versao1.produto.dto.PrecoProdutoDTO;
import com.agua.versao1.produto.dto.ProdutoDTO;
import com.agua.versao1.produto.service.ProdutoService;
import com.agua.versao1.shared.response.ApiResponse; // IMPORTANTE: Importar seu envelope
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class ProdutoController {

    private final ProdutoService produtoService;

    // === PRODUTOS ===

    @GetMapping("/api/produtos")
    public ResponseEntity<ApiResponse<List<ProdutoDTO.Disponibilidade>>> listarProdutos() {
        return ResponseEntity.ok(ApiResponse.ok(produtoService.listarDisponibilidade()));
    }

    @GetMapping("/api/produtos/todos")
    public ResponseEntity<ApiResponse<List<ProdutoDTO.Response>>> listarTodos() {
        return ResponseEntity.ok(ApiResponse.ok(produtoService.listarTodos()));
    }

    @GetMapping("/api/produtos/{id}")
    public ResponseEntity<ApiResponse<ProdutoDTO.Disponibilidade>> buscarPorId(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.ok(produtoService.buscarDisponibilidadePorId(id)));
    }

    @PostMapping("/api/produtos")
    public ResponseEntity<ApiResponse<ProdutoDTO.Response>> criar(@Valid @RequestBody ProdutoDTO.Request request) {
        ProdutoDTO.Response criado = produtoService.criar(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(criado));
    }

    @PutMapping("/api/produtos/{id}")
    public ResponseEntity<ApiResponse<ProdutoDTO.Response>> atualizar(
            @PathVariable Integer id,
            @Valid @RequestBody ProdutoDTO.Request request) {
        return ResponseEntity.ok(ApiResponse.ok(produtoService.atualizar(id, request)));
    }

    @PatchMapping("/api/produtos/{id}/ativar")
    public ResponseEntity<ApiResponse<ProdutoDTO.Response>> ativar(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.ok(produtoService.ativar(id)));
    }

    @PatchMapping("/api/produtos/{id}/desativar")
    public ResponseEntity<ApiResponse<ProdutoDTO.Response>> desativar(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.ok(produtoService.desativar(id)));
    }

    @GetMapping("/api/produtos/{id}/preco")
    public ResponseEntity<ApiResponse<PrecoProdutoDTO>> calcularPreco(
            @PathVariable Integer id,
            @RequestParam Integer operacaoId) {
        return ResponseEntity.ok(ApiResponse.ok(produtoService.calcularPreco(id, operacaoId)));
    }

    // === OPERAÇÕES ===

    @GetMapping("/api/operacoes")
    public ResponseEntity<ApiResponse<List<OperacaoDTO.Response>>> listarOperacoes() {
        return ResponseEntity.ok(ApiResponse.ok(produtoService.listarOperacoes()));
    }

    @GetMapping("/api/operacoes/{id}")
    public ResponseEntity<ApiResponse<OperacaoDTO.Response>> buscarOperacao(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.ok(produtoService.buscarOperacaoPorId(id)));
    }
}