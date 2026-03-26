package com.agua.versao1.estoque.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class MovimentoEstoqueDTO {

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Response {
        private Integer idMovimento;
        private Integer idUsuario;
        private Integer idPedido;
        private String tipoMovimento;
        private BigDecimal litrosMovimentados;
        private BigDecimal litrosAnterior;
        private BigDecimal litrosNovo;
        private String motivo;
        private LocalDateTime dataMovimento;
        private boolean manual; // calculado: idPedido == null
    }
}