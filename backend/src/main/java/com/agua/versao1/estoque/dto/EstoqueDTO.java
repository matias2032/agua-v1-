package com.agua.versao1.estoque.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class EstoqueDTO {

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Response {
        private Integer idEstoque;
        private BigDecimal litrosDisponiveis;
        private LocalDateTime ultimaAtualizacao;
        private String observacao;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AjusteRequest {

        @NotNull(message = "litros é obrigatório")
        @DecimalMin(value = "0.001", message = "litros deve ser maior que 0")
        private BigDecimal litros;

        @NotNull(message = "idUsuario é obrigatório")
        private Integer idUsuario;

        private String motivo;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DefinirRequest {

        @NotNull(message = "litrosDisponiveis é obrigatório")
        @DecimalMin(value = "0.0", message = "litrosDisponiveis não pode ser negativo")
        private BigDecimal litrosDisponiveis;

        @NotNull(message = "idUsuario é obrigatório")
        private Integer idUsuario;

        private String observacao;
    }
}