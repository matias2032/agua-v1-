package com.agua.versao1.estoque.repository;

import com.agua.versao1.estoque.entity.EstoqueAgua;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface EstoqueAguaRepository extends JpaRepository<EstoqueAgua, Integer> {

    @Query("SELECT e FROM EstoqueAgua e WHERE e.idEstoque = (SELECT MAX(e2.idEstoque) FROM EstoqueAgua e2)")
    Optional<EstoqueAgua> findUltimo();
}