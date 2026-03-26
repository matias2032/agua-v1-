package com.agua.versao1.estoque.controller;

// TODO: confirma o package do ApiResponse e ajusta esta linha.
// Abre qualquer outro Controller do teu projecto e copia o import do ApiResponse desse ficheiro.
import com.agua.versao1.shared.response.ApiResponse; 

import com.agua.versao1.estoque.dto.EstoqueDTO;
import com.agua.versao1.estoque.dto.MovimentoEstoqueDTO;
import com.agua.versao1.estoque.service.EstoqueService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
public class EstoqueController {

    private final EstoqueService estoqueService;

    // ─── Estoque — /api/estoque ───────────────────────────────────────────────

    @GetMapping("/api/estoque")
    public ResponseEntity<ApiResponse<EstoqueDTO.Response>> buscarActual() {
        return ResponseEntity.ok(ApiResponse.ok(estoqueService.buscarActual()));
    }

    @PatchMapping("/api/estoque/adicionar")
    public ResponseEntity<ApiResponse<EstoqueDTO.Response>> adicionar(
            @Valid @RequestBody EstoqueDTO.AjusteRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(estoqueService.adicionar(request)));
    }

    @PatchMapping("/api/estoque/remover")
    public ResponseEntity<ApiResponse<EstoqueDTO.Response>> remover(
            @Valid @RequestBody EstoqueDTO.AjusteRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(estoqueService.remover(request)));
    }

    @PutMapping("/api/estoque")
    public ResponseEntity<ApiResponse<EstoqueDTO.Response>> definir(
            @Valid @RequestBody EstoqueDTO.DefinirRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(estoqueService.definir(request)));
    }

    // ─── Movimentos — /api/movimentos-estoque ────────────────────────────────

    @GetMapping("/api/movimentos-estoque")
    public ResponseEntity<ApiResponse<Page<MovimentoEstoqueDTO.Response>>> listarTodos(
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(estoqueService.listarTodos(pageable)));
    }

    @GetMapping("/api/movimentos-estoque/manuais")
    public ResponseEntity<ApiResponse<Page<MovimentoEstoqueDTO.Response>>> listarManuais(
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(estoqueService.listarManuais(pageable)));
    }

    @GetMapping("/api/movimentos-estoque/tipo/{tipo}")
    public ResponseEntity<ApiResponse<Page<MovimentoEstoqueDTO.Response>>> listarPorTipo(
            @PathVariable String tipo,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(estoqueService.listarPorTipo(tipo, pageable)));
    }
}