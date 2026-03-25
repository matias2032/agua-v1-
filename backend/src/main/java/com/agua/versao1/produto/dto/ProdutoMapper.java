package com.agua.versao1.produto.mapper;

import com.agua.versao1.produto.dto.OperacaoDTO;
import com.agua.versao1.produto.dto.PrecoProdutoDTO;
import com.agua.versao1.produto.dto.ProdutoDTO;
import com.agua.versao1.produto.entity.DisponibilidadeProdutoView;
import com.agua.versao1.produto.entity.Operacao;
import com.agua.versao1.produto.entity.Produto;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;

@Component
public class ProdutoMapper {

    // ── Produto ───────────────────────────────────────────────────────────────

    public Produto toEntity(ProdutoDTO.Request dto) {
        return Produto.builder()
                .nomeProduto(dto.getNomeProduto())
                .descricao(dto.getDescricao())
                .precoCompra(dto.getPrecoCompra())
                .precoReenchimento(dto.getPrecoReenchimento())
                .capacidadeLitros(dto.getCapacidadeLitros())
                .ativo(true)
                .build();
    }

    public ProdutoDTO.Response toResponse(Produto produto) {
        return ProdutoDTO.Response.builder()
                .idProduto(produto.getIdProduto())
                .nomeProduto(produto.getNomeProduto())
                .descricao(produto.getDescricao())
                .precoCompra(produto.getPrecoCompra())
                .precoReenchimento(produto.getPrecoReenchimento())
                .capacidadeLitros(produto.getCapacidadeLitros())
                .ativo(produto.getAtivo())
                .build();
    }

    // ── Disponibilidade ───────────────────────────────────────────────────────

    public ProdutoDTO.Disponibilidade toDisponibilidade(DisponibilidadeProdutoView view) {
        return ProdutoDTO.Disponibilidade.builder()
                .idProduto(view.getIdProduto())
                .nomeProduto(view.getNomeProduto())
                .capacidadeLitros(view.getCapacidadeLitros())
                .precoCompra(view.getPrecoCompra())
                .precoReenchimento(view.getPrecoReenchimento())
                .litrosDisponiveis(view.getLitrosDisponiveis())
                .quantidadeDisponivel(view.getQuantidadeDisponivel())
                .ativo(view.getAtivo())
                .build();
    }

    // ── Operação ──────────────────────────────────────────────────────────────

    public OperacaoDTO.Response toOperacaoResponse(Operacao operacao) {
        return OperacaoDTO.Response.builder()
                .idOperacao(operacao.getIdOperacao())
                .nomeOperacao(operacao.getNomeOperacao())
                .fatorPreco(operacao.getFatorPreco())
                .descricao(operacao.getDescricao())
                .build();
    }

    // ── Preço calculado ───────────────────────────────────────────────────────

    public PrecoProdutoDTO toPrecoDTO(Produto produto, Operacao operacao) {
        // Usa precoReenchimento quando a operação tem fator < 1, precoCompra para compra nova
        BigDecimal precoBase = operacao.getFatorPreco().compareTo(BigDecimal.ONE) < 0
                ? produto.getPrecoReenchimento()
                : produto.getPrecoCompra();

        BigDecimal precoFinal = precoBase
                .multiply(operacao.getFatorPreco())
                .setScale(2, RoundingMode.HALF_UP);

        return PrecoProdutoDTO.builder()
                .idProduto(produto.getIdProduto())
                .nomeProduto(produto.getNomeProduto())
                .idOperacao(operacao.getIdOperacao())
                .nomeOperacao(operacao.getNomeOperacao())
                .precoBase(precoBase)
                .fatorPreco(operacao.getFatorPreco())
                .precoFinal(precoFinal)
                .build();
    }
}