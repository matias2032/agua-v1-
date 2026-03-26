package com.agua.versao1.pedido.repository;

import com.agua.versao1.pedido.entity.Pedido;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PedidoRepository extends JpaRepository<Pedido, Integer> {

    Page<Pedido> findAllByOrderByDataPedidoDesc(Pageable pageable);

    @Query("SELECT p FROM Pedido p WHERE p.statusPedido = :status ORDER BY p.dataPedido DESC")
    Page<Pedido> findByStatus(@Param("status") String status, Pageable pageable);

    @Query("SELECT p FROM Pedido p WHERE p.idUsuario = :idUsuario ORDER BY p.dataPedido DESC")
    List<Pedido> findByIdUsuario(@Param("idUsuario") Integer idUsuario);
}