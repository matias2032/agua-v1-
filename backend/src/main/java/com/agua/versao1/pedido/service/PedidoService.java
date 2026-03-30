package com.agua.versao1.pedido.service;

import com.agua.versao1.estoque.repository.EstoqueAguaRepository;
import com.agua.versao1.pedido.dto.PedidoDTO;
import com.agua.versao1.pedido.entity.ItemPedido;
import com.agua.versao1.pedido.entity.Pedido;
import com.agua.versao1.pedido.entity.PedidoCancelamento;
import com.agua.versao1.pedido.repository.ItemPedidoRepository;
import com.agua.versao1.pedido.repository.PedidoCancelamentoRepository;
import com.agua.versao1.pedido.repository.PedidoRepository;
import com.agua.versao1.produto.entity.Operacao;
import com.agua.versao1.produto.entity.Produto;
import com.agua.versao1.produto.repository.OperacaoRepository;
import com.agua.versao1.produto.repository.ProdutoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.agua.versao1.usuario.repository.UsuarioRepository;
import com.agua.versao1.shared.firebase.FirebaseSyncService;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service 
@RequiredArgsConstructor
public class PedidoService {

    private final PedidoRepository pedidoRepository;
    private final ItemPedidoRepository itemPedidoRepository;
    private final PedidoCancelamentoRepository cancelamentoRepository;
    private final ProdutoRepository produtoRepository;
    private final OperacaoRepository operacaoRepository;
    private final EstoqueAguaRepository estoqueRepository;
    private final UsuarioRepository usuarioRepository;
    private final FirebaseSyncService firebaseSyncService;

    // ─── Criar pedido ─────────────────────────────────────────────────────────

    /**
     * Cria um pedido com itens.
     * Fluxo (Regras 3, 4, 6, 7):
     * 1. Valida operação e tipo de pagamento
     * 2. Para cada item: busca produto, calcula litros e preço
     * 3. Verifica estoque total antes de persistir
     * 4. Persiste Pedido, depois cada ItemPedido (triggers disparam aqui)
     */
    @Transactional
    public PedidoDTO.Response criar(PedidoDTO.Request request, Integer idUsuario) {
        // 1. Validar operação do pedido
        Operacao operacaoPedido = operacaoRepository.findById(request.getIdOperacao())
                .orElseThrow(() -> new RuntimeException(
                        "Operação não encontrada: id=" + request.getIdOperacao()));

        List<ItemResolucao> itensResolvidos = new ArrayList<>();
        BigDecimal totalLitrosNecessarios = BigDecimal.ZERO;

        for (PedidoDTO.ItemRequest itemReq : request.getItens()) {
            Produto produto = produtoRepository.findByIdProdutoAndAtivoTrue(itemReq.getIdProduto())
                    .orElseThrow(() -> new RuntimeException(
                            "Produto não encontrado ou inactivo: id=" + itemReq.getIdProduto()));

            // A operação do item herda a do pedido se não vier explicitamente (Regra 3)
            Integer idOperacaoItem = itemReq.getIdOperacao() != null
                    ? itemReq.getIdOperacao()
                    : request.getIdOperacao();

            Operacao operacaoItem = idOperacaoItem.equals(request.getIdOperacao())
                    ? operacaoPedido
                    : operacaoRepository.findById(idOperacaoItem)
                            .orElseThrow(() -> new RuntimeException(
                                    "Operação do item não encontrada: id=" + idOperacaoItem));

            // litrosConsumidos = capacidade × quantidade (Regra 4)
            BigDecimal litrosConsumidos = produto.getCapacidadeLitros()
                    .multiply(BigDecimal.valueOf(itemReq.getQuantidade()));

            // precoUnitario = precoBase × fatorOperacao (Regra 3)
            // O precoBase depende do tipo de operação:
            // fator=1.000 → compra normal → precoCompra
            // fator<1.000 → reenchimento → precoReenchimento (já reflecte o desconto base)
            // Porém, segundo a especificação, a fórmula é: precoBase × fatorOperacao
            // onde precoBase é sempre precoCompra (o fator já encapsula o desconto)
          BigDecimal precoUnitario = (idOperacaoItem == 1)
        ? produto.getPrecoCompra()
        : produto.getPrecoReenchimento();
precoUnitario = precoUnitario.setScale(2, RoundingMode.HALF_UP);

            totalLitrosNecessarios = totalLitrosNecessarios.add(litrosConsumidos);

            itensResolvidos.add(new ItemResolucao(
                    produto, operacaoItem, itemReq.getQuantidade(),
                    litrosConsumidos, precoUnitario));
        }

        // 3. Verificar estoque suficiente antes de qualquer persistência (Regra 7)
        BigDecimal litrosDisponiveis = estoqueRepository.findUltimo()
                .orElseThrow(() -> new RuntimeException("Estoque não encontrado"))
                .getLitrosDisponiveis();

        if (totalLitrosNecessarios.compareTo(litrosDisponiveis) > 0) {
            throw new RuntimeException(String.format(
                    "Estoque insuficiente. Necessário: %.3f L, Disponível: %.3f L",
                    totalLitrosNecessarios, litrosDisponiveis));
        }

        // 4. Calcular total do pedido (Regra 6)
        BigDecimal total = itensResolvidos.stream()
                .map(ir -> ir.precoUnitario.multiply(BigDecimal.valueOf(ir.quantidade)))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // 5. Persistir Pedido
        Pedido pedido = Pedido.builder()
                .nomeCliente(request.getNomeCliente())
                .telefoneCliente(request.getTelefoneCliente())
                .emailCliente(request.getEmailCliente())
                .idUsuario(idUsuario)
                .idOperacao(request.getIdOperacao())
                .idTipoPagamento(request.getIdTipoPagamento())
                .total(total)
                .valorPago(request.getValorPago() != null ? request.getValorPago() : BigDecimal.ZERO)
                .endereco(request.getEndereco())
                .bairro(request.getBairro())
                .pontoReferencia(request.getPontoReferencia())
                .observacao(request.getObservacao())
                .build();

        pedido = pedidoRepository.save(pedido);
        final Integer idPedido = pedido.getIdPedido();

        // 6. Persistir cada ItemPedido — trigger trg_saida_estoque_venda dispara aqui (Regra 4)
        List<ItemPedido> itensSalvos = new ArrayList<>();
        for (ItemResolucao ir : itensResolvidos) {
            ItemPedido item = ItemPedido.builder()
                    .idPedido(idPedido)
                    .idProduto(ir.produto.getIdProduto())
                    .idOperacao(ir.operacao.getIdOperacao())
                    .quantidade(ir.quantidade)
                    .litrosConsumidos(ir.litrosConsumidos)
                    .precoUnitario(ir.precoUnitario)
                    .build();
            itensSalvos.add(itemPedidoRepository.save(item));
        }

        // Recarregar pedido para obter troco calculado pelo banco
        pedido = pedidoRepository.findById(idPedido)
                .orElseThrow(() -> new RuntimeException("Pedido não encontrado após persistência"));

                firebaseSyncService.sincronizarPedido(pedido, itensSalvos); 

        return toResponse(pedido, itensSalvos, operacaoPedido, null);
        
    }

    // ─── Leituras ─────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public Page<PedidoDTO.Response> listar(String status, Pageable pageable) {
        Page<Pedido> pagina = (status != null && !status.isBlank())
                ? pedidoRepository.findByStatus(status, pageable)
                : pedidoRepository.findAllByOrderByDataPedidoDesc(pageable);

        return pagina.map(p -> {
            List<ItemPedido> itens = itemPedidoRepository.findByIdPedido(p.getIdPedido());
            return toResponse(p, itens, null, null);
        });
    }

    @Transactional(readOnly = true)
    public PedidoDTO.Response buscarPorId(Integer id) {
        Pedido pedido = pedidoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Pedido não encontrado: id=" + id));
        List<ItemPedido> itens = itemPedidoRepository.findByIdPedido(id);
        return toResponse(pedido, itens, null, null);
    }

    @Transactional(readOnly = true)
    public List<PedidoDTO.Response> listarPorUsuario(Integer idUsuario) {
        return pedidoRepository.findByIdUsuario(idUsuario).stream()
                .map(p -> {
                    List<ItemPedido> itens = itemPedidoRepository.findByIdPedido(p.getIdPedido());
                    return toResponse(p, itens, null, null);
                })
                .toList();
    }

    // ─── Mutações de estado ───────────────────────────────────────────────────

    @Transactional
    public PedidoDTO.Response finalizar(Integer id) {
        
        Pedido pedido = pedidoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Pedido não encontrado: id=" + id));

        if ("cancelado".equals(pedido.getStatusPedido())) {
            throw new RuntimeException("Pedido cancelado não pode ser finalizado");
        }
        if ("finalizado".equals(pedido.getStatusPedido())) {
            throw new RuntimeException("Pedido já está finalizado");
        }

        pedido.setStatusPedido("finalizado");
        pedido.setDataFinalizacao(LocalDateTime.now());
        pedidoRepository.save(pedido);

        List<ItemPedido> itens = itemPedidoRepository.findByIdPedido(id);
         firebaseSyncService.sincronizarPedido(pedido, itens); 
        return toResponse(pedido, itens, null, null);
    }

    // Adicionar após o método finalizar():

@Transactional
public PedidoDTO.Response adicionarItem(Integer idPedido, PedidoDTO.AdicionarItemRequest request) {
    // 1. Validar pedido existe e está pendente
    Pedido pedido = pedidoRepository.findById(idPedido)
            .orElseThrow(() -> new RuntimeException("Pedido não encontrado: id=" + idPedido));

    if ("cancelado".equals(pedido.getStatusPedido())) {
        throw new RuntimeException("Não é possível adicionar itens a um pedido cancelado");
    }
    if ("finalizado".equals(pedido.getStatusPedido())) {
        throw new RuntimeException("Não é possível adicionar itens a um pedido finalizado");
    }

    // 2. Resolver produto
    Produto produto = produtoRepository.findByIdProdutoAndAtivoTrue(request.getIdProduto())
            .orElseThrow(() -> new RuntimeException(
                    "Produto não encontrado ou inactivo: id=" + request.getIdProduto()));

    // 3. Resolver operação — herda a do pedido se não vier
    Integer idOperacaoItem = request.getIdOperacao() != null
            ? request.getIdOperacao()
            : pedido.getIdOperacao();

    Operacao operacao = operacaoRepository.findById(idOperacaoItem)
            .orElseThrow(() -> new RuntimeException(
                    "Operação não encontrada: id=" + idOperacaoItem));

    // 4. Calcular litros e preço
    BigDecimal litrosConsumidos = produto.getCapacidadeLitros()
            .multiply(BigDecimal.valueOf(request.getQuantidade()));

BigDecimal precoUnitario = (idOperacaoItem == 1)
        ? produto.getPrecoCompra()
        : produto.getPrecoReenchimento();
precoUnitario = precoUnitario.setScale(2, RoundingMode.HALF_UP);

    // 5. Verificar estoque suficiente
    BigDecimal litrosDisponiveis = estoqueRepository.findUltimo()
            .orElseThrow(() -> new RuntimeException("Estoque não encontrado"))
            .getLitrosDisponiveis();

    if (litrosConsumidos.compareTo(litrosDisponiveis) > 0) {
        throw new RuntimeException(String.format(
                "Estoque insuficiente. Necessário: %.3f L, Disponível: %.3f L",
                litrosConsumidos, litrosDisponiveis));
    }

    // 6. Persistir item — trigger trg_saida_estoque_venda dispara aqui
    ItemPedido novoItem = ItemPedido.builder()
            .idPedido(idPedido)
            .idProduto(produto.getIdProduto())
            .idOperacao(idOperacaoItem)
            .quantidade(request.getQuantidade())
            .litrosConsumidos(litrosConsumidos)
            .precoUnitario(precoUnitario)
            .build();

    itemPedidoRepository.save(novoItem);

    // 7. Recalcular total do pedido
    List<ItemPedido> todosItens = itemPedidoRepository.findByIdPedido(idPedido);
    BigDecimal novoTotal = todosItens.stream()
            .map(i -> i.getPrecoUnitario().multiply(BigDecimal.valueOf(i.getQuantidade())))
            .reduce(BigDecimal.ZERO, BigDecimal::add);

    pedido.setTotal(novoTotal);
    pedidoRepository.save(pedido);

    // Recarregar para obter valores gerados pelo banco
    pedido = pedidoRepository.findById(idPedido)
            .orElseThrow(() -> new RuntimeException("Pedido não encontrado após actualização"));

                firebaseSyncService.sincronizarPedido(pedido, todosItens);

    return toResponse(pedido, todosItens, null, null);
}

    @Transactional
    public PedidoDTO.Response actualizarValorPago(Integer id, PedidoDTO.ValorPagoRequest request) {
        Pedido pedido = pedidoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Pedido não encontrado: id=" + id));

        if ("cancelado".equals(pedido.getStatusPedido())) {
            throw new RuntimeException("Não é possível actualizar valor pago de um pedido cancelado");
        }

        pedido.setValorPago(request.getValorPago());
        pedidoRepository.save(pedido);

        // Recarregar para obter troco actualizado pelo banco
        pedido = pedidoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Pedido não encontrado após actualização"));

        List<ItemPedido> itens = itemPedidoRepository.findByIdPedido(id);
         firebaseSyncService.sincronizarPedido(pedido, itens); 
        return toResponse(pedido, itens, null, null);
    }

    @Transactional
    public PedidoDTO.Response cancelar(Integer id, PedidoDTO.CancelamentoRequest request, Integer idUsuario) {
        Pedido pedido = pedidoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Pedido não encontrado: id=" + id));

        // Regra 5: pedido finalizado não pode ser cancelado
        if ("finalizado".equals(pedido.getStatusPedido())) {
            throw new RuntimeException("Pedido finalizado não pode ser cancelado");
        }
        if ("cancelado".equals(pedido.getStatusPedido())) {
            throw new RuntimeException("Pedido já está cancelado");
        }

        // Inserir em pedido_cancelamento — trigger trg_estorno_cancelamento trata o resto (Regra 5)
        // O trigger actualiza o status e estorna os litros automaticamente
        PedidoCancelamento cancelamento = PedidoCancelamento.builder()
                .idPedido(id)
                .motivo(request.getMotivo())
                .idUsuarioCancelou(idUsuario)
                .build();
        cancelamentoRepository.save(cancelamento);

        // Recarregar pedido — o trigger já actualizou o status para 'cancelado'
        pedido = pedidoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Pedido não encontrado após cancelamento"));

        List<ItemPedido> itens = itemPedidoRepository.findByIdPedido(id);
         firebaseSyncService.sincronizarPedido(pedido, itens); 
        return toResponse(pedido, itens, null, null);
    }

    // ─── Auxiliares ──────────────────────────────────────────────────────────

private PedidoDTO.Response toResponse(
            Pedido pedido,
            List<ItemPedido> itens,
            Operacao operacaoPedido,
            String nomeTipoPagamento) {
 
        // Resolver nome + apelido do operador
        String nomeUsuario    = null;
        String apelidoUsuario = null;
        if (pedido.getIdUsuario() != null) {
            var usuario = usuarioRepository.findById(pedido.getIdUsuario()).orElse(null);
            if (usuario != null) {
                nomeUsuario    = usuario.getNome();
                apelidoUsuario = usuario.getApelido();
            }
        }
 
        List<PedidoDTO.ItemResponse> itensResponse = itens.stream()
                .map(item -> PedidoDTO.ItemResponse.builder()
                        .idItemPedido(item.getIdItemPedido())
                        .idProduto(item.getIdProduto())
                        .idOperacao(item.getIdOperacao())
                        .quantidade(item.getQuantidade())
                        .litrosConsumidos(item.getLitrosConsumidos())
                        .precoUnitario(item.getPrecoUnitario())
                        .subtotal(item.getSubtotal())
                        .build())
                .toList();
 
        return PedidoDTO.Response.builder()
                .idPedido(pedido.getIdPedido())
                .reference(pedido.getReference())
                .nomeCliente(pedido.getNomeCliente())
                .telefoneCliente(pedido.getTelefoneCliente())
                .emailCliente(pedido.getEmailCliente())
                .idUsuario(pedido.getIdUsuario())
                .nomeUsuario(nomeUsuario)        // ← novo
                .apelidoUsuario(apelidoUsuario)  // ← novo
                .idOperacao(pedido.getIdOperacao())
                .nomeOperacao(operacaoPedido != null ? operacaoPedido.getNomeOperacao() : null)
                .idTipoPagamento(pedido.getIdTipoPagamento())
                .nomeTipoPagamento(nomeTipoPagamento)
                .dataPedido(pedido.getDataPedido())
                .dataFinalizacao(pedido.getDataFinalizacao())
                .statusPedido(pedido.getStatusPedido())
                .total(pedido.getTotal())
                .valorPago(pedido.getValorPago())
                .troco(pedido.getTroco())
                .endereco(pedido.getEndereco())
                .bairro(pedido.getBairro())
                .pontoReferencia(pedido.getPontoReferencia())
                .notificacaoVista(pedido.getNotificacaoVista())
                .ocultoCliente(pedido.getOcultoCliente())
                .observacao(pedido.getObservacao())
                .itens(itensResponse)
                .build();
    }


    // Record interno para transporte de dados durante a criação
    private record ItemResolucao(
            Produto produto,
            Operacao operacao,
            Integer quantidade,
            BigDecimal litrosConsumidos,
            BigDecimal precoUnitario) {}
}