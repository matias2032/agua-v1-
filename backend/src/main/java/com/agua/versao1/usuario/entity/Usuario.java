package com.agua.versao1.usuario.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "usuario")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_usuario")
    private Integer idUsuario;

    @Column(name = "nome", nullable = false, length = 150)
    private String nome;

    @Column(name = "apelido", length = 100)
    private String apelido;

    @Column(name = "email", nullable = false, unique = true)
    private String email;

    @Column(name = "senha_hash", nullable = false)
    private String senhaHash;

    @Column(name = "telefone", length = 30)
    private String telefone;

    @Column(name = "ativo", nullable = false)
@Builder.Default
private Boolean ativo = true;



    @CreationTimestamp
    @Column(name = "data_cadastro", nullable = false, updatable = false)
    private LocalDateTime dataCadastro;

    @Column(name = "id_perfil")
    private Integer idPerfil;

    @Column(name = "primeira_senha", nullable = false)
 @Builder.Default
private Boolean primeiraSenha = true;

    // ── Métodos auxiliares ────────────────────────────────────────────────────

    public void ativar()      { this.ativo = true;  }
    public void desativar()   { this.ativo = false; }
    public void toggleStatus(){ this.ativo = !this.ativo; }
}