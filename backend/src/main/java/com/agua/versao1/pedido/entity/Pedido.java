package com.agua.versao1.pedido.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "pedido")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Pedido {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_pedido")
    private Integer idPedido;

    @Column(name = "reference", unique = true)
    private String reference;

    // Dados do cliente (sem conta obrigatória — Regra 1)
    @Column(name = "nome_cliente")
    private String nomeCliente;

    @Column(name = "telefone_cliente")
    private String telefoneCliente;

    @Column(name = "email_cliente")
    private String emailCliente;

    // Funcionário que registou o pedido (Regra 2)
    @Column(name = "id_usuario", nullable = false)
    private Integer idUsuario;

    @Column(name = "id_operacao", nullable = false)
    private Integer idOperacao;

    @Column(name = "id_tipo_pagamento", nullable = false)
    private Integer idTipoPagamento;

    @Column(name = "data_pedido", nullable = false)
    private LocalDateTime dataPedido;

    @Column(name = "data_finalizacao")
    private LocalDateTime dataFinalizacao;

    @Column(name = "status_pedido", nullable = false)
    @Builder.Default
    private String statusPedido = "pendente";

    @Column(name = "total", nullable = false)
    private BigDecimal total;

    @Column(name = "valor_pago", nullable = false)
    @Builder.Default
    private BigDecimal valorPago = BigDecimal.ZERO;

    // Coluna gerada pelo banco — não inserir/actualizar manualmente (Regra 6)
    @Column(name = "troco", insertable = false, updatable = false)
    private BigDecimal troco;

    // Entrega
    @Column(name = "endereco")
    private String endereco;

    @Column(name = "bairro")
    private String bairro;

    @Column(name = "ponto_referencia")
    private String pontoReferencia;

    @Column(name = "notificacao_vista", nullable = false)
    @Builder.Default
    private Boolean notificacaoVista = false;

    @Column(name = "oculto_cliente", nullable = false)
    @Builder.Default
    private Boolean ocultoCliente = false;

    @Column(name = "observacao")
    private String observacao;

    @OneToMany(mappedBy = "idPedido", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<ItemPedido> itens = new ArrayList<>();

    @PrePersist
    public void prePersist() {
        if (this.dataPedido == null) {
            this.dataPedido = LocalDateTime.now();
        }
        if (this.statusPedido == null) {
            this.statusPedido = "pendente";
        }
    }
}