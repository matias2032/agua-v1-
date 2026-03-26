package com.agua.versao1.pedido.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "item_pedido")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ItemPedido {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_item_pedido")
    private Integer idItemPedido;

    @Column(name = "id_pedido", nullable = false)
    private Integer idPedido;

    @Column(name = "id_produto", nullable = false)
    private Integer idProduto;

    @Column(name = "id_operacao", nullable = false)
    private Integer idOperacao;

    @Column(name = "quantidade", nullable = false)
    private Integer quantidade;

    // Snapshot dos litros consumidos no momento da venda
    // Trigger trg_saida_estoque_venda usa este campo para debitar o estoque (Regra 4)
    @Column(name = "litros_consumidos", nullable = false)
    private BigDecimal litrosConsumidos;

    @Column(name = "preco_unitario", nullable = false)
    private BigDecimal precoUnitario;

    // Coluna gerada pelo banco: preco_unitario * quantidade — não inserir/actualizar (Regra 6)
    @Column(name = "subtotal", insertable = false, updatable = false)
    private BigDecimal subtotal;
}