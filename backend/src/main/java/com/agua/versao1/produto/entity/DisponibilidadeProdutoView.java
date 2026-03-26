package com.agua.versao1.produto.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.Immutable;
import org.hibernate.annotations.Subselect;

import java.math.BigDecimal;

/**
 * Mapeamento somente-leitura da view vw_disponibilidade_produto.
 * A quantidade_disponivel é calculada pelo banco:
 *   FLOOR(litros_disponiveis / capacidade_litros)
 */
@Entity
@Immutable
@Subselect("""
        SELECT
            p.id_produto,
            p.nome_produto,
            p.capacidade_litros,
            p.preco_compra,
            p.preco_reenchimento,
            p.ativo,
            e.litros_disponiveis,
            FLOOR(e.litros_disponiveis / p.capacidade_litros)::INTEGER AS quantidade_disponivel
        FROM produto p
        CROSS JOIN estoque_agua e
              WHERE e.id_estoque = (SELECT MAX(id_estoque) FROM estoque_agua)
        """)

@Getter
@NoArgsConstructor
public class DisponibilidadeProdutoView {

    @Id
    @Column(name = "id_produto")
    private Integer idProduto;

    @Column(name = "nome_produto")
    private String nomeProduto;

    @Column(name = "capacidade_litros")
    private BigDecimal capacidadeLitros;

    @Column(name = "preco_compra")
    private BigDecimal precoCompra;

    @Column(name = "preco_reenchimento")
    private BigDecimal precoReenchimento;

    @Column(name = "litros_disponiveis")
    private BigDecimal litrosDisponiveis;

    // Quantidade de galões que podem ser vendidos dado o estoque atual
    @Column(name = "quantidade_disponivel")
    private Integer quantidadeDisponivel;

    @Column(name = "ativo")
private Boolean ativo;
}