package com.agua.versao1.estoque.service;

import com.agua.versao1.estoque.dto.EstoqueDTO;
import com.agua.versao1.estoque.dto.MovimentoEstoqueDTO;
import com.agua.versao1.estoque.entity.EstoqueAgua;
import com.agua.versao1.estoque.entity.MovimentoEstoque;
import com.agua.versao1.estoque.repository.EstoqueAguaRepository;
import com.agua.versao1.estoque.repository.MovimentoEstoqueRepository;
import com.agua.versao1.shared.firebase.FirebaseSyncService;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Service
@RequiredArgsConstructor
public class EstoqueService {

    private final EstoqueAguaRepository estoqueRepository;
    private final MovimentoEstoqueRepository movimentoRepository;
    private final FirebaseSyncService firebaseSyncService;

    // ─── Leituras ────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public EstoqueDTO.Response buscarActual() {
        EstoqueAgua estoque = estoqueRepository.findUltimo()
                .orElseThrow(() -> new RuntimeException("Estoque não encontrado"));
        return toResponse(estoque);
    }

    @Transactional(readOnly = true)
    public Page<MovimentoEstoqueDTO.Response> listarTodos(Pageable pageable) {
        return movimentoRepository.findAllByOrderByDataMovimentoDesc(pageable)
                .map(this::toMovimentoResponse);
    }

    @Transactional(readOnly = true)
    public Page<MovimentoEstoqueDTO.Response> listarManuais(Pageable pageable) {
        return movimentoRepository.findManuais(pageable)
                .map(this::toMovimentoResponse);
    }

    @Transactional(readOnly = true)
    public Page<MovimentoEstoqueDTO.Response> listarPorTipo(String tipo, Pageable pageable) {
        if (!tipo.equals("entrada") && !tipo.equals("saida")) {
            throw new RuntimeException("Tipo inválido. Use 'entrada' ou 'saida'");
        }
        return movimentoRepository.findByTipo(tipo, pageable)
                .map(this::toMovimentoResponse);
    }

    // ─── Mutações ────────────────────────────────────────────────────────────

    @Transactional
    public EstoqueDTO.Response adicionar(EstoqueDTO.AjusteRequest request) {
        EstoqueAgua estoque = estoqueRepository.findUltimo()
                .orElseThrow(() -> new RuntimeException("Estoque não encontrado"));

        BigDecimal anterior = estoque.getLitrosDisponiveis();
        BigDecimal novo = anterior.add(request.getLitros());

        estoque.setLitrosDisponiveis(novo);
        estoqueRepository.save(estoque);
        firebaseSyncService.sincronizarEstoque(estoque);   

        registarMovimento(estoque.getIdEstoque(), request.getIdUsuario(), null,
                "entrada", request.getLitros(), anterior, novo, request.getMotivo());

        return toResponse(estoque);
    }

    @Transactional
    public EstoqueDTO.Response remover(EstoqueDTO.AjusteRequest request) {
        EstoqueAgua estoque = estoqueRepository.findUltimo()
                .orElseThrow(() -> new RuntimeException("Estoque não encontrado"));

        BigDecimal anterior = estoque.getLitrosDisponiveis();
        BigDecimal novo = anterior.subtract(request.getLitros());

        if (novo.compareTo(BigDecimal.ZERO) < 0) {
            throw new RuntimeException("Litros insuficientes no estoque. Disponível: " + anterior);
        }

        estoque.setLitrosDisponiveis(novo);
        estoqueRepository.save(estoque);
        firebaseSyncService.sincronizarEstoque(estoque);   

        registarMovimento(estoque.getIdEstoque(), request.getIdUsuario(), null,
                "saida", request.getLitros(), anterior, novo, request.getMotivo());

        return toResponse(estoque);
    }

    @Transactional
    public EstoqueDTO.Response definir(EstoqueDTO.DefinirRequest request) {
        EstoqueAgua estoque = estoqueRepository.findUltimo()
                .orElseThrow(() -> new RuntimeException("Estoque não encontrado"));

        BigDecimal anterior = estoque.getLitrosDisponiveis();
        BigDecimal novoValor = request.getLitrosDisponiveis();
        BigDecimal delta = novoValor.subtract(anterior).abs();

        estoque.setLitrosDisponiveis(novoValor);
        estoque.setObservacao(request.getObservacao());
        estoqueRepository.save(estoque);
        firebaseSyncService.sincronizarEstoque(estoque);   

        // Só regista movimento se houve alteração
        if (delta.compareTo(BigDecimal.ZERO) > 0) {
            String tipo = novoValor.compareTo(anterior) > 0 ? "entrada" : "saida";
            registarMovimento(estoque.getIdEstoque(), request.getIdUsuario(), null,
                    tipo, delta, anterior, novoValor, request.getObservacao());
        }

        return toResponse(estoque);
    }

    // ─── Auxiliares ──────────────────────────────────────────────────────────

    private void registarMovimento(Integer idEstoque, Integer idUsuario, Integer idPedido,
                                    String tipo, BigDecimal litros,
                                    BigDecimal anterior, BigDecimal novo, String motivo) {
        MovimentoEstoque movimento = MovimentoEstoque.builder()
                .idUsuario(idUsuario)
                .idPedido(idPedido)
                .tipoMovimento(tipo)
                .litrosMovimentados(litros)
                .litrosAnterior(anterior)
                .litrosNovo(novo)
                .motivo(motivo)
                .build();
        movimentoRepository.save(movimento);
    }

    private EstoqueDTO.Response toResponse(EstoqueAgua estoque) {
        return EstoqueDTO.Response.builder()
                .idEstoque(estoque.getIdEstoque())
                .litrosDisponiveis(estoque.getLitrosDisponiveis())
                .ultimaAtualizacao(estoque.getUltimaAtualizacao())
                .observacao(estoque.getObservacao())
                .build();
    }

    private MovimentoEstoqueDTO.Response toMovimentoResponse(MovimentoEstoque m) {
        return MovimentoEstoqueDTO.Response.builder()
                .idMovimento(m.getIdMovimento())
                .idUsuario(m.getIdUsuario())
                .idPedido(m.getIdPedido())
                .tipoMovimento(m.getTipoMovimento())
                .litrosMovimentados(m.getLitrosMovimentados())
                .litrosAnterior(m.getLitrosAnterior())
                .litrosNovo(m.getLitrosNovo())
                .motivo(m.getMotivo())
                .dataMovimento(m.getDataMovimento())
                .manual(m.getIdPedido() == null)
                .build();
    }
}