package com.agua.versao1.produto.repository;

import com.agua.versao1.produto.entity.Produto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProdutoRepository extends JpaRepository<Produto, Integer> {

    List<Produto> findAllByAtivoTrue();

    Optional<Produto> findByIdProdutoAndAtivoTrue(Integer idProduto);

    boolean existsByNomeProdutoIgnoreCase(String nomeProduto);
}