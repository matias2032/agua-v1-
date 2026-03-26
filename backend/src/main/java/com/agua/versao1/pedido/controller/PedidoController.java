package com.agua.versao1.pedido.controller;

import com.agua.versao1.pedido.dto.PedidoDTO;
import com.agua.versao1.pedido.service.PedidoService;
import com.agua.versao1.shared.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller do módulo de pedidos.
 *
 * NOTA: O idUsuario vem da sessão activa.
 * Nos endpoints que precisam do utilizador autenticado, deve substituir
 * SessaoService.instance.getIdUsuario() pela integração com Spring Security
 * (ex: @AuthenticationPrincipal, SecurityContextHolder, etc.) conforme o
 * padrão adoptado no resto do projecto.
 *
 * O parâmetro idUsuario está recebido via @RequestHeader("X-Usuario-Id")
 * como placeholder — adaptar para o mecanismo de sessão real do projecto.
 */
@RestController
@RequiredArgsConstructor
public class PedidoController {

    private final PedidoService pedidoService;

    // ─── Criar pedido ─────────────────────────────────────────────────────────

    @PostMapping("/api/pedidos")
    public ResponseEntity<ApiResponse<PedidoDTO.Response>> criar(
            @Valid @RequestBody PedidoDTO.Request request,
            @RequestHeader("X-Usuario-Id") Integer idUsuario) {
        PedidoDTO.Response criado = pedidoService.criar(request, idUsuario);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(criado));
    }

    // ─── Listar pedidos (paginado, filtro por status opcional) ───────────────

    @GetMapping("/api/pedidos")
    public ResponseEntity<ApiResponse<Page<PedidoDTO.Response>>> listar(
            @RequestParam(required = false) String status,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(pedidoService.listar(status, pageable)));
    }

    // ─── Buscar pedido por ID com itens ──────────────────────────────────────

    @GetMapping("/api/pedidos/{id}")
    public ResponseEntity<ApiResponse<PedidoDTO.Response>> buscarPorId(
            @PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.ok(pedidoService.buscarPorId(id)));
    }

    // ─── Pedidos de um funcionário ────────────────────────────────────────────

    @GetMapping("/api/pedidos/usuario/{idUsuario}")
    public ResponseEntity<ApiResponse<List<PedidoDTO.Response>>> listarPorUsuario(
            @PathVariable Integer idUsuario) {
        return ResponseEntity.ok(ApiResponse.ok(pedidoService.listarPorUsuario(idUsuario)));
    }

    // ─── Finalizar pedido ─────────────────────────────────────────────────────

    @PatchMapping("/api/pedidos/{id}/finalizar")
    public ResponseEntity<ApiResponse<PedidoDTO.Response>> finalizar(
            @PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.ok(pedidoService.finalizar(id)));
    }

    // ─── Registar valor pago ──────────────────────────────────────────────────

    @PatchMapping("/api/pedidos/{id}/valor-pago")
    public ResponseEntity<ApiResponse<PedidoDTO.Response>> actualizarValorPago(
            @PathVariable Integer id,
            @Valid @RequestBody PedidoDTO.ValorPagoRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(pedidoService.actualizarValorPago(id, request)));
    }

    // ─── Cancelar pedido ──────────────────────────────────────────────────────

    @PostMapping("/api/pedidos/{id}/cancelar")
    public ResponseEntity<ApiResponse<PedidoDTO.Response>> cancelar(
            @PathVariable Integer id,
            @RequestBody PedidoDTO.CancelamentoRequest request,
            @RequestHeader("X-Usuario-Id") Integer idUsuario) {
        return ResponseEntity.ok(ApiResponse.ok(pedidoService.cancelar(id, request, idUsuario)));
    }
}