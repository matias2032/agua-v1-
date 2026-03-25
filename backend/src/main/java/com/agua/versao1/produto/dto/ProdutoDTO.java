package com.agua.versao1.produto.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

// ─── Request: criar produto ───────────────────────────────────────────────────
public class ProdutoDTO {

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Request {

        @NotBlank(message = "Nome do produto é obrigatório")
        @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres")
        private String nomeProduto;

        private String descricao;

        @NotNull(message = "Preço de compra é obrigatório")
        @DecimalMin(value = "0.00", message = "Preço de compra não pode ser negativo")
        @Digits(integer = 8, fraction = 2)
        private BigDecimal precoCompra;

        @NotNull(message = "Preço de reenchimento é obrigatório")
        @DecimalMin(value = "0.00", message = "Preço de reenchimento não pode ser negativo")
        @Digits(integer = 8, fraction = 2)
        private BigDecimal precoReenchimento;

        @NotNull(message = "Capacidade em litros é obrigatória")
        @DecimalMin(value = "0.001", inclusive = true, message = "Capacidade deve ser maior que zero")
        @Digits(integer = 5, fraction = 3)
        private BigDecimal capacidadeLitros;
    }

    // ─── Response: detalhes do produto ───────────────────────────────────────
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Response {
        private Integer idProduto;
        private String nomeProduto;
        private String descricao;
        private BigDecimal precoCompra;
        private BigDecimal precoReenchimento;
        private BigDecimal capacidadeLitros;
        private Boolean ativo;
    }

    // ─── Response: produto com disponibilidade calculada pelo estoque ────────
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
public static class Disponibilidade {
    private Integer idProduto;
    private String nomeProduto;
    private BigDecimal capacidadeLitros;
    private BigDecimal precoCompra;
    private BigDecimal precoReenchimento;
    private BigDecimal litrosDisponiveis;
    private Integer quantidadeDisponivel;
    private Boolean ativo;  // ← adicionar
}
}