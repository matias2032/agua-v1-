package com.agua.versao1.estoque.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "estoque_agua")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EstoqueAgua {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_estoque")
    private Integer idEstoque;

    @Column(name = "litros_disponiveis", nullable = false, precision = 12, scale = 3)
    private BigDecimal litrosDisponiveis;

    @Column(name = "ultima_atualizacao", nullable = false)
    private LocalDateTime ultimaAtualizacao;

    @Column(name = "observacao")
    private String observacao;

    @PrePersist
    @PreUpdate
    public void prePersist() {
        this.ultimaAtualizacao = LocalDateTime.now();
    }
}