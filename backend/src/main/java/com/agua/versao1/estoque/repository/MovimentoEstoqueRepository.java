package com.agua.versao1.estoque.repository;

import com.agua.versao1.estoque.entity.MovimentoEstoque;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface MovimentoEstoqueRepository extends JpaRepository<MovimentoEstoque, Integer> {

    Page<MovimentoEstoque> findAllByOrderByDataMovimentoDesc(Pageable pageable);

    @Query("SELECT m FROM MovimentoEstoque m WHERE m.idPedido IS NULL ORDER BY m.dataMovimento DESC")
    Page<MovimentoEstoque> findManuais(Pageable pageable);

    @Query("SELECT m FROM MovimentoEstoque m WHERE m.tipoMovimento = :tipo ORDER BY m.dataMovimento DESC")
    Page<MovimentoEstoque> findByTipo(@Param("tipo") String tipo, Pageable pageable);
}