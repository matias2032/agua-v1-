package com.agua.versao1.pedido.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "pedido_cancelamento")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PedidoCancelamento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cancelamento")
    private Integer idCancelamento;

    @Column(name = "id_pedido", nullable = false)
    private Integer idPedido;

    @Column(name = "motivo")
    private String motivo;

    // Funcionário que cancelou o pedido
    @Column(name = "id_usuario_cancelou", nullable = false)
    private Integer idUsuarioCancelou;

    @Column(name = "data_cancelamento", nullable = false)
    private LocalDateTime dataCancelamento;

    @PrePersist
    public void prePersist() {
        if (this.dataCancelamento == null) {
            this.dataCancelamento = LocalDateTime.now();
        }
    }
}