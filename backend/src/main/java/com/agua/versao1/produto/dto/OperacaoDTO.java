package com.agua.versao1.produto.dto;

import lombok.*;

import java.math.BigDecimal;

public class OperacaoDTO {

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Response {
        private Integer idOperacao;
        private String nomeOperacao;
        private BigDecimal fatorPreco;
        private String descricao;
    }
}