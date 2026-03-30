package com.agua.versao1.produto.service;

import com.agua.versao1.produto.dto.OperacaoDTO;
import com.agua.versao1.shared.firebase.FirebaseSyncService;
import com.agua.versao1.produto.dto.PrecoProdutoDTO;
import com.agua.versao1.produto.dto.ProdutoDTO;
import com.agua.versao1.produto.entity.Operacao;
import com.agua.versao1.produto.entity.Produto;
import com.agua.versao1.produto.exception.OperacaoNaoEncontradaException;
import com.agua.versao1.produto.exception.ProdutoNaoEncontradoException;
import com.agua.versao1.produto.mapper.ProdutoMapper;
import com.agua.versao1.produto.repository.DisponibilidadeProdutoRepository;
import com.agua.versao1.produto.repository.OperacaoRepository;
import com.agua.versao1.produto.repository.ProdutoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ProdutoService {

    private final ProdutoRepository produtoRepository;
    private final OperacaoRepository operacaoRepository;
    private final DisponibilidadeProdutoRepository disponibilidadeRepository;
    private final ProdutoMapper mapper;
        private final FirebaseSyncService firebaseSyncService;

    // ─── Produtos ─────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<ProdutoDTO.Response> listarAtivos() {
        return produtoRepository.findAllByAtivoTrue()
                .stream()
                .map(mapper::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ProdutoDTO.Response> listarTodos() {
        return produtoRepository.findAll()
                .stream()
                .map(mapper::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public ProdutoDTO.Response buscarPorId(Integer id) {
        Produto produto = produtoRepository.findById(id)
                .orElseThrow(() -> new ProdutoNaoEncontradoException(id));
        return mapper.toResponse(produto);
    }

    @Transactional
    public ProdutoDTO.Response criar(ProdutoDTO.Request request) {
        Produto produto = mapper.toEntity(request);
        Produto salvo = produtoRepository.save(produto);
firebaseSyncService.sincronizarProduto(salvo);
return mapper.toResponse(salvo);
    }

    @Transactional
    public ProdutoDTO.Response atualizar(Integer id, ProdutoDTO.Request request) {
        Produto produto = produtoRepository.findById(id)
                .orElseThrow(() -> new ProdutoNaoEncontradoException(id));

        produto.setNomeProduto(request.getNomeProduto());
        produto.setDescricao(request.getDescricao());
        produto.setPrecoCompra(request.getPrecoCompra());
        produto.setPrecoReenchimento(request.getPrecoReenchimento());
        produto.setCapacidadeLitros(request.getCapacidadeLitros());

       Produto salvo = produtoRepository.save(produto);
firebaseSyncService.sincronizarProduto(salvo);
return mapper.toResponse(salvo);
    }

@Transactional
public ProdutoDTO.Response ativar(Integer id) {
    produtoRepository.findById(id)
            .orElseThrow(() -> new ProdutoNaoEncontradoException(id));

    produtoRepository.ativarPorId(id);

    Produto salvo = produtoRepository.findById(id)
            .orElseThrow(() -> new ProdutoNaoEncontradoException(id));
    firebaseSyncService.sincronizarProduto(salvo);   // ← após buscar estado real
    return mapper.toResponse(salvo);
}

@Transactional
public ProdutoDTO.Response desativar(Integer id) {
    produtoRepository.findById(id)
            .orElseThrow(() -> new ProdutoNaoEncontradoException(id));

    produtoRepository.desativarPorId(id);

    Produto salvo = produtoRepository.findById(id)
            .orElseThrow(() -> new ProdutoNaoEncontradoException(id));
    firebaseSyncService.sincronizarProduto(salvo);   // ← após buscar estado real
    return mapper.toResponse(salvo);
}
    // ─── Disponibilidade (vw_disponibilidade_produto) ─────────────────────────

    /**
     * Retorna todos os produtos ativos com a quantidade disponível calculada
     * em função dos litros em estoque.
     * Regra: quantidade_disponivel = FLOOR(litros_disponiveis / capacidade_litros)
     */
    @Transactional(readOnly = true)
    public List<ProdutoDTO.Disponibilidade> listarDisponibilidade() {
        return disponibilidadeRepository.findAll()
                .stream()
                .map(mapper::toDisponibilidade)
                .toList();
    }

    @Transactional(readOnly = true)
    public ProdutoDTO.Disponibilidade buscarDisponibilidadePorId(Integer id) {
        return disponibilidadeRepository.findByIdProduto(id)
                .map(mapper::toDisponibilidade)
                .orElseThrow(() -> new ProdutoNaoEncontradoException(id));
    }

    // ─── Operações ────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<OperacaoDTO.Response> listarOperacoes() {
        return operacaoRepository.findAll()
                .stream()
                .map(mapper::toOperacaoResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public OperacaoDTO.Response buscarOperacaoPorId(Integer id) {
        Operacao operacao = operacaoRepository.findById(id)
                .orElseThrow(() -> new OperacaoNaoEncontradaException(id));
        return mapper.toOperacaoResponse(operacao);
    }

    // ─── Preço calculado ─────────────────────────────────────────────────────

    /**
     * Calcula o preço de um produto para uma operação específica.
     * Usado pelo módulo de pedidos antes de criar um item.
     */
    @Transactional(readOnly = true)
    public PrecoProdutoDTO calcularPreco(Integer idProduto, Integer idOperacao) {
        Produto produto = produtoRepository.findByIdProdutoAndAtivoTrue(idProduto)
                .orElseThrow(() -> new ProdutoNaoEncontradoException(idProduto));
        Operacao operacao = operacaoRepository.findById(idOperacao)
                .orElseThrow(() -> new OperacaoNaoEncontradaException(idOperacao));
        return mapper.toPrecoDTO(produto, operacao);
    }
}