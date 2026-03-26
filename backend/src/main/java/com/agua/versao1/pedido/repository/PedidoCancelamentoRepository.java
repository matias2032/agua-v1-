package com.agua.versao1.pedido.repository;

import com.agua.versao1.pedido.entity.PedidoCancelamento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PedidoCancelamentoRepository extends JpaRepository<PedidoCancelamento, Integer> {
}