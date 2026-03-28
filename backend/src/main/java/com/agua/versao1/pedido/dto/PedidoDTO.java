package com.agua.versao1.pedido.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public class PedidoDTO {

    // ─── Request (criar pedido) ───────────────────────────────────────────────

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Request {

        // Dados do cliente — opcionais (Regra 1)
        private String nomeCliente;
        private String telefoneCliente;
        private String emailCliente;

        // id_usuario vem da sessão no service (Regra 2) — não exposto aqui

        @NotNull(message = "Operação é obrigatória")
        private Integer idOperacao;

        @NotNull(message = "Tipo de pagamento é obrigatório")
        private Integer idTipoPagamento;

        @NotNull(message = "A lista de itens não pode ser nula")
        @Size(min = 1, message = "O pedido deve ter pelo menos um item")
        @Valid
        private List<ItemRequest> itens;

        private BigDecimal valorPago;

        // Entrega (opcionais)
        private String endereco;
        private String bairro;
        private String pontoReferencia;
        private String observacao;
    }

    // ─── ItemRequest ─────────────────────────────────────────────────────────

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ItemRequest {

        @NotNull(message = "Produto é obrigatório")
        private Integer idProduto;

        @NotNull(message = "Quantidade é obrigatória")
        @Min(value = 1, message = "Quantidade mínima é 1")
        private Integer quantidade;

        // A operação do item herda a do pedido por defeito, mas pode ser sobreposta (Regra 3)
        private Integer idOperacao;
    }

    // ─── Response (pedido completo) ───────────────────────────────────────────

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Response {

        private Integer idPedido;
        private String reference;

        private String nomeCliente;
        private String telefoneCliente;
        private String emailCliente;

        private Integer idUsuario;
        private Integer idOperacao;
        private String nomeOperacao;
        private Integer idTipoPagamento;
        private String nomeTipoPagamento;

        private LocalDateTime dataPedido;
        private LocalDateTime dataFinalizacao;
        private String statusPedido;

        private BigDecimal total;
        private BigDecimal valorPago;
        private BigDecimal troco;

        private String endereco;
        private String bairro;
        private String pontoReferencia;
        private Boolean notificacaoVista;
        private Boolean ocultoCliente;
        private String observacao;
        private String nomeUsuario;
        private String apelidoUsuario;


        private List<ItemResponse> itens;
    }

    // ─── ItemResponse ─────────────────────────────────────────────────────────

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ItemResponse {

        private Integer idItemPedido;
        private Integer idProduto;
        private String nomeProduto;
        private Integer idOperacao;
        private String nomeOperacao;
        private Integer quantidade;
        private BigDecimal litrosConsumidos;
        private BigDecimal precoUnitario;
        private BigDecimal subtotal;
    }

    // ─── CancelamentoRequest ──────────────────────────────────────────────────

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CancelamentoRequest {

        private String motivo;

        // id_usuario_cancelou vem da sessão no service (Regra 2)
    }

    // ─── ValorPagoRequest ─────────────────────────────────────────────────────

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ValorPagoRequest {

        @NotNull(message = "Valor pago é obrigatório")
        @DecimalMin(value = "0.0", message = "Valor pago não pode ser negativo")
        private BigDecimal valorPago;
    }

    @Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public static class AdicionarItemRequest {

    @NotNull(message = "Produto é obrigatório")
    private Integer idProduto;

    @NotNull(message = "Quantidade é obrigatória")
    @Min(value = 1, message = "Quantidade mínima é 1")
    private Integer quantidade;

    // Se não vier, herda a operação do pedido (Regra 3)
    private Integer idOperacao;
}
}