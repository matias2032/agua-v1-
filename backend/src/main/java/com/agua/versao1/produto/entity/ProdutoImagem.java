package com.agua.versao1.produto.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "produto_imagem")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProdutoImagem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_imagem")
    private Integer idImagem;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_produto", nullable = false)
    private Produto produto;

    @Column(name = "caminho_imagem", length = 255)
    private String caminhoImagem;

    @Column(name = "legenda", length = 100)
    private String legenda;

    @Column(name = "imagem_principal", nullable = false)
    @Builder.Default
    private Boolean imagemPrincipal = false;
}