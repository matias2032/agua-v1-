package com.agua.versao1.produto.dto;

import lombok.*;

import java.math.BigDecimal;

/**
 * Retorna o preço final de um produto para uma determinada operação.
 * precoFinal = precoBase × fatorPreco da operação
 *
 * Exemplo:
 *   Galão 18L, compra  → 120.00 × 1.000 = 120.00
 *   Galão 18L, reench. → 120.00 × 0.700 =  84.00
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PrecoProdutoDTO {
    private Integer idProduto;
    private String nomeProduto;
    private Integer idOperacao;
    private String nomeOperacao;
    private BigDecimal precoBase;
    private BigDecimal fatorPreco;
    private BigDecimal precoFinal;
}