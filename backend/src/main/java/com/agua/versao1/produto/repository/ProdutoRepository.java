package com.agua.versao1.produto.repository;

import com.agua.versao1.produto.entity.Produto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;   // ← falta
import org.springframework.data.jpa.repository.Query;       // ← falta
import org.springframework.data.repository.query.Param;     // ← falta
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProdutoRepository extends JpaRepository<Produto, Integer> {

    List<Produto> findAllByAtivoTrue();
    Optional<Produto> findByIdProdutoAndAtivoTrue(Integer idProduto);
    boolean existsByNomeProdutoIgnoreCase(String nomeProduto);

    @Modifying
    @Query("UPDATE Produto p SET p.ativo = true WHERE p.idProduto = :id")
    int ativarPorId(@Param("id") Integer id);

    @Modifying
    @Query("UPDATE Produto p SET p.ativo = false WHERE p.idProduto = :id")
    int desativarPorId(@Param("id") Integer id);
}