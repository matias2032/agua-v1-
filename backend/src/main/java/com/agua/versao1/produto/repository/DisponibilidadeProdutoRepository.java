package com.agua.versao1.produto.repository;

import com.agua.versao1.produto.entity.DisponibilidadeProdutoView;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DisponibilidadeProdutoRepository extends JpaRepository<DisponibilidadeProdutoView, Integer> {

    List<DisponibilidadeProdutoView> findAll();

    Optional<DisponibilidadeProdutoView> findByIdProduto(Integer idProduto);
}