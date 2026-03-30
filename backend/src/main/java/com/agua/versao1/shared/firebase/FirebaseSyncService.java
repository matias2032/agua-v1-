package com.agua.versao1.shared.firebase;

import com.agua.versao1.estoque.entity.EstoqueAgua;
import com.agua.versao1.pedido.entity.ItemPedido;
import com.agua.versao1.pedido.entity.Pedido;
import com.agua.versao1.produto.entity.Produto;
import com.google.cloud.Timestamp;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.FirebaseApp;
import com.google.firebase.cloud.FirestoreClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Serviço responsável por espelhar os dados do PostgreSQL no Firestore.
 *
 * Todas as chamadas são @Async — não bloqueiam a transacção principal.
 * O Firestore actua apenas como canal de leitura em tempo real para os
 * clientes Flutter; o PostgreSQL continua a ser a fonte de verdade.
 *
 * Colecções Firestore:
 *   - pedidos/{idPedido}           → documento completo do pedido + itens
 *   - estoque/atual                → snapshot do estoque de água
 *   - produtos/{idProduto}         → snapshot do produto
 */
@Service
public class FirebaseSyncService {

    private static final Logger log = LoggerFactory.getLogger(FirebaseSyncService.class);

    // ─── Guarda obtida de forma lazy — FirebaseApp pode não estar inicializado ──

    private Firestore getFirestore() {
        if (FirebaseApp.getApps().isEmpty()) {
            return null;
        }
        return FirestoreClient.getFirestore();
    }

    // ─── Pedido ──────────────────────────────────────────────────────────────

    /**
     * Escreve (ou substitui) o documento do pedido no Firestore.
     * Inclui a lista de itens como sub-campo do documento.
     *
     * @param pedido     entidade JPA já persistida
     * @param itens      lista de itens do pedido
     */
    @Async
    public void sincronizarPedido(Pedido pedido, List<ItemPedido> itens) {
        Firestore db = getFirestore();
        if (db == null) {
            log.debug("Firebase não disponível — sincronizarPedido ignorado.");
            return;
        }

        try {
            Map<String, Object> doc = pedidoToMap(pedido, itens);
            String docId = String.valueOf(pedido.getIdPedido());

            db.collection("pedidos")
              .document(docId)
              .set(doc)
              .get(); // bloqueamos apenas dentro da thread @Async

            log.debug("✅ Pedido {} sincronizado no Firestore.", pedido.getIdPedido());

        } catch (Exception e) {
            log.error("❌ Erro ao sincronizar pedido {} no Firestore: {}",
                      pedido.getIdPedido(), e.getMessage(), e);
        }
    }

    /**
     * Remove o documento do pedido do Firestore.
     * Usar apenas se um pedido for apagado fisicamente (cenário raro).
     */
    @Async
    public void removerPedido(Integer idPedido) {
        Firestore db = getFirestore();
        if (db == null) return;

        try {
            db.collection("pedidos")
              .document(String.valueOf(idPedido))
              .delete()
              .get();

            log.debug("🗑️  Pedido {} removido do Firestore.", idPedido);

        } catch (Exception e) {
            log.error("❌ Erro ao remover pedido {} do Firestore: {}",
                      idPedido, e.getMessage(), e);
        }
    }

    // ─── Estoque ─────────────────────────────────────────────────────────────

    /**
     * Actualiza o snapshot de estoque no Firestore.
     * Usa um documento fixo "atual" na colecção "estoque".
     */
    @Async
    public void sincronizarEstoque(EstoqueAgua estoque) {
        Firestore db = getFirestore();
        if (db == null) {
            log.debug("Firebase não disponível — sincronizarEstoque ignorado.");
            return;
        }

        try {
            Map<String, Object> doc = new HashMap<>();
            doc.put("idEstoque", estoque.getIdEstoque());
            doc.put("litrosDisponiveis", estoque.getLitrosDisponiveis().doubleValue());
            doc.put("ultimaAtualizacao", toTimestamp(estoque.getUltimaAtualizacao()));
            doc.put("observacao", estoque.getObservacao());

            db.collection("estoque")
              .document("atual")
              .set(doc)
              .get();

            log.debug("✅ Estoque sincronizado no Firestore: {} L",
                      estoque.getLitrosDisponiveis());

        } catch (Exception e) {
            log.error("❌ Erro ao sincronizar estoque no Firestore: {}",
                      e.getMessage(), e);
        }
    }

    // ─── Produto ─────────────────────────────────────────────────────────────

    /**
     * Escreve (ou substitui) o documento do produto no Firestore.
     */
    @Async
    public void sincronizarProduto(Produto produto) {
        Firestore db = getFirestore();
        if (db == null) {
            log.debug("Firebase não disponível — sincronizarProduto ignorado.");
            return;
        }

        try {
            Map<String, Object> doc = new HashMap<>();
            doc.put("idProduto", produto.getIdProduto());
            doc.put("nomeProduto", produto.getNomeProduto());
            doc.put("descricao", produto.getDescricao());
            doc.put("precoCompra", produto.getPrecoCompra().doubleValue());
            doc.put("precoReenchimento", produto.getPrecoReenchimento().doubleValue());
            doc.put("capacidadeLitros", produto.getCapacidadeLitros().doubleValue());
            doc.put("ativo", produto.getAtivo());

            db.collection("produtos")
              .document(String.valueOf(produto.getIdProduto()))
              .set(doc)
              .get();

            log.debug("✅ Produto {} sincronizado no Firestore.", produto.getIdProduto());

        } catch (Exception e) {
            log.error("❌ Erro ao sincronizar produto {} no Firestore: {}",
                      produto.getIdProduto(), e.getMessage(), e);
        }
    }

    // ─── Usuario ─────────────────────────────────────────────────────────────────

@Async
public void sincronizarUsuario(com.agua.versao1.usuario.entity.Usuario usuario) {
    Firestore db = getFirestore();
    if (db == null) { log.debug("Firebase não disponível — sincronizarUsuario ignorado."); return; }
    try {
        db.collection("usuarios")
          .document(String.valueOf(usuario.getIdUsuario()))
          .set(usuarioToMap(usuario))
          .get();
        log.debug("✅ Usuário {} sincronizado no Firestore.", usuario.getIdUsuario());
    } catch (Exception e) {
        log.error("❌ Erro ao sincronizar usuário {} no Firestore: {}", usuario.getIdUsuario(), e.getMessage(), e);
    }
}

@Async
public void removerUsuario(Integer idUsuario) {
    Firestore db = getFirestore();
    if (db == null) return;
    try {
        db.collection("usuarios").document(String.valueOf(idUsuario)).delete().get();
        log.debug("🗑️  Usuário {} removido do Firestore.", idUsuario);
    } catch (Exception e) {
        log.error("❌ Erro ao remover usuário {} do Firestore: {}", idUsuario, e.getMessage(), e);
    }
}

private Map<String, Object> usuarioToMap(com.agua.versao1.usuario.entity.Usuario u) {
    Map<String, Object> doc = new HashMap<>();
    doc.put("idUsuario",     u.getIdUsuario());
    doc.put("nome",          u.getNome());
    doc.put("apelido",       u.getApelido() != null ? u.getApelido() : "");
    doc.put("email",         u.getEmail());
    doc.put("telefone",      u.getTelefone() != null ? u.getTelefone() : "");
    doc.put("ativo",         u.getAtivo() != null ? u.getAtivo() : false);
    doc.put("idPerfil",      u.getIdPerfil());
    doc.put("primeiraSenha", u.getPrimeiraSenha() != null ? u.getPrimeiraSenha() : false);
    doc.put("dataCadastro",  toTimestamp(u.getDataCadastro()));
    // senhaHash nunca é exposta
    return doc;
}

    // ─── Conversores ─────────────────────────────────────────────────────────

    /**
     * Converte a entidade Pedido + itens num Map compatível com o Firestore.
     * BigDecimal → double | LocalDateTime → Timestamp
     */
    public Map<String, Object> pedidoToMap(Pedido pedido, List<ItemPedido> itens) {
        Map<String, Object> doc = new HashMap<>();

        doc.put("idPedido",          pedido.getIdPedido());
        doc.put("reference",         pedido.getReference());
        doc.put("nomeCliente",       pedido.getNomeCliente());
        doc.put("telefoneCliente",   pedido.getTelefoneCliente());
        doc.put("emailCliente",      pedido.getEmailCliente());
        doc.put("idUsuario",         pedido.getIdUsuario());
        doc.put("idOperacao",        pedido.getIdOperacao());
        doc.put("idTipoPagamento",   pedido.getIdTipoPagamento());
        doc.put("statusPedido",      pedido.getStatusPedido());
        doc.put("endereco",          pedido.getEndereco());
        doc.put("bairro",            pedido.getBairro());
        doc.put("pontoReferencia",   pedido.getPontoReferencia());
        doc.put("observacao",        pedido.getObservacao());
        doc.put("notificacaoVista",  pedido.getNotificacaoVista());
        doc.put("ocultoCliente",     pedido.getOcultoCliente());

        // BigDecimal → double
        doc.put("total",     pedido.getTotal()     != null ? pedido.getTotal().doubleValue()     : 0.0);
        doc.put("valorPago", pedido.getValorPago() != null ? pedido.getValorPago().doubleValue() : 0.0);
        doc.put("troco",     pedido.getTroco()     != null ? pedido.getTroco().doubleValue()     : null);

        // LocalDateTime → Firestore Timestamp
        doc.put("dataPedido",      toTimestamp(pedido.getDataPedido()));
        doc.put("dataFinalizacao", toTimestamp(pedido.getDataFinalizacao()));

        // Itens como lista de maps
        if (itens != null) {
            doc.put("itens", itens.stream().map(this::itemToMap).toList());
        }

        return doc;
    }

    /**
     * Converte um ItemPedido num Map para embutir no documento do pedido.
     */
    public Map<String, Object> itemToMap(ItemPedido item) {
        Map<String, Object> map = new HashMap<>();
        map.put("idItemPedido",    item.getIdItemPedido());
        map.put("idProduto",       item.getIdProduto());
        map.put("idOperacao",      item.getIdOperacao());
        map.put("quantidade",      item.getQuantidade());
        map.put("litrosConsumidos",item.getLitrosConsumidos() != null
                                        ? item.getLitrosConsumidos().doubleValue() : 0.0);
        map.put("precoUnitario",   item.getPrecoUnitario() != null
                                        ? item.getPrecoUnitario().doubleValue() : 0.0);
        map.put("subtotal",        item.getSubtotal() != null
                                        ? item.getSubtotal().doubleValue() : null);
        return map;
    }

    // ─── Utilitário de conversão de data ─────────────────────────────────────

    /**
     * Converte LocalDateTime (fuso horário do servidor) em Timestamp do Firestore.
     * Devolve null se o valor de entrada for null.
     */
    private Timestamp toTimestamp(java.time.LocalDateTime ldt) {
        if (ldt == null) return null;
        java.time.Instant instant = ldt.toInstant(ZoneOffset.of("+02:00")); // Africa/Maputo = UTC+2
        return Timestamp.ofTimeSecondsAndNanos(instant.getEpochSecond(), instant.getNano());
    }
}