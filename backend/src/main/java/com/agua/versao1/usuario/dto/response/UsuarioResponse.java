package com.agua.versao1.usuario.dto.response;

import com.agua.versao1.usuario.entity.Usuario;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;

import java.time.LocalDateTime;

/**
 * DTO de resposta — campos alinhados com UsuarioModel no Flutter.
 *
 * Campos removidos vs projecto anterior:
 *   - idProvincia  (não existe neste schema)
 *   - idCidade     (não existe neste schema)
 *
 * Tipos alterados vs projecto anterior:
 *   - ativo        : Boolean  (era Integer)  → Flutter recebe true/false
 *   - primeiraSenha: Boolean  (era Integer)  → Flutter recebe true/false
 *
 * IMPORTANTE: senhaHash NUNCA é exposta.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UsuarioResponse {

    private Integer idUsuario;
    private String  nome;
    private String  apelido;
    private String  email;
    private String  telefone;

    /** true = activo | false = inactivo */
    private Boolean ativo;

    /** "Ativo" ou "Inativo" — exibição directa na UI */
    private String  statusDescricao;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime dataCadastro;

    private Integer idPerfil;

    /** true = utilizador ainda não alterou a senha padrão */
    private Boolean primeiraSenha;

    // ── Conversão estática Entity → DTO ──────────────────────────────────────

    public static UsuarioResponse fromEntity(Usuario u) {
        if (u == null) return null;

        return UsuarioResponse.builder()
                .idUsuario      (u.getIdUsuario())
                .nome           (u.getNome())
                .apelido        (u.getApelido())
                .email          (u.getEmail())
                .telefone       (u.getTelefone())
                .ativo          (u.getAtivo())
                .statusDescricao(Boolean.TRUE.equals(u.getAtivo()) ? "Ativo" : "Inativo")
                .dataCadastro   (u.getDataCadastro())
                .idPerfil       (u.getIdPerfil())
                .primeiraSenha  (u.getPrimeiraSenha())
                .build();
    }
}