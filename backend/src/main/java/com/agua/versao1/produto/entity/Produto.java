package com.agua.versao1.produto.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "produto")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Produto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_produto")
    private Integer idProduto;

    @Column(name = "nome_produto", nullable = false, length = 100)
    private String nomeProduto;

    @Column(name = "descricao")
    private String descricao;

    @Column(name = "preco_compra", nullable = false, precision = 10, scale = 2)
    private BigDecimal precoCompra;

    @Column(name = "preco_reenchimento", nullable = false, precision = 10, scale = 2)
    private BigDecimal precoReenchimento;

    // Capacidade do recipiente em litros (ex: 6.0, 18.0)
    @Column(name = "capacidade_litros", nullable = false, precision = 8, scale = 3)
    private BigDecimal capacidadeLitros;

    @Column(name = "ativo", nullable = false)
    @Builder.Default
    private Boolean ativo = true;

    @OneToMany(mappedBy = "produto", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<ProdutoImagem> imagens = new ArrayList<>();
}