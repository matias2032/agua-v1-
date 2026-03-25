package com.agua.versao1.produto.repository;

import com.agua.versao1.produto.entity.Operacao;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OperacaoRepository extends JpaRepository<Operacao, Integer> {

    List<Operacao> findAll();
}