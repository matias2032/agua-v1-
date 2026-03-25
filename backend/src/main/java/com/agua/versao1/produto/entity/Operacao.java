package com.agua.versao1.produto.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "operacao")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Operacao {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_operacao")
    private Integer idOperacao;

    @Column(name = "nome_operacao", nullable = false, unique = true, length = 100)
    private String nomeOperacao;

    // Fator aplicado sobre o preço base do produto (0.0 a 1.0)
    // Ex: reenchimento = 0.700 → 30% mais barato que a compra
    @Column(name = "fator_preco", nullable = false, precision = 4, scale = 3)
    private BigDecimal fatorPreco;

    @Column(name = "descricao")
    private String descricao;
}