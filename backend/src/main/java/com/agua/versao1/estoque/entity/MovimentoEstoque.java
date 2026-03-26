package com.agua.versao1.estoque.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "movimento_estoque")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MovimentoEstoque {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_movimento")
    private Integer idMovimento;

    @Column(name = "id_usuario", nullable = false)
    private Integer idUsuario;

    @Column(name = "id_pedido")
    private Integer idPedido;

    @Column(name = "tipo_movimento", nullable = false)
    private String tipoMovimento;

    @Column(name = "litros_movimentados", nullable = false, precision = 12, scale = 3)
    private BigDecimal litrosMovimentados;

    @Column(name = "litros_anterior", nullable = false, precision = 12, scale = 3)
    private BigDecimal litrosAnterior;

    @Column(name = "litros_novo", nullable = false, precision = 12, scale = 3)
    private BigDecimal litrosNovo;

    @Column(name = "motivo")
    private String motivo;

    @Column(name = "data_movimento", nullable = false)
    private LocalDateTime dataMovimento;

    @PrePersist
    public void prePersist() {
        if (this.dataMovimento == null) {
            this.dataMovimento = LocalDateTime.now();
        }
    }
}