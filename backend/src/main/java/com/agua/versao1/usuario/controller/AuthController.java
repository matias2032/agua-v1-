package com.agua.versao1.usuario.controller;

import com.agua.versao1.usuario.dto.response.UsuarioResponse;
import com.agua.versao1.usuario.entity.Usuario;
import com.agua.versao1.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Slf4j
public class AuthController {

    private final UsuarioRepository     usuarioRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    // ── POST /api/auth/login ─────────────────────────────────────────────────
    /**
     * Body esperado (Flutter → Java):
     * { "credencial": "email|telefone|apelido", "senha": "..." }
     *
     * Resposta (Java → Flutter):
     * { "usuario": { ...UsuarioResponse }, "primeiraSenha": true|false }
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> body) {

        String credencial = body.get("credencial");
        String senha      = body.get("senha");

        log.info("═══════════════════════════════════════════");
        log.info("🔐 TENTATIVA DE LOGIN — credencial='{}'", credencial);

        if (credencial == null || credencial.isBlank() || senha == null || senha.isBlank()) {
            log.warn("⚠️  Campos em branco");
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Credencial e senha são obrigatórios."));
        }

        Optional<Usuario> opt = usuarioRepository.findByEmailOrTelefoneOrApelido(credencial);

        if (opt.isEmpty()) {
            log.warn("❌ Nenhum utilizador para credencial='{}'", credencial);
            return ResponseEntity.status(401)
                    .body(Map.of("message", "Credencial ou senha incorretos."));
        }

        Usuario u = opt.get();
        log.info("✅ Utilizador encontrado — ID={} nome='{} {}'",
                u.getIdUsuario(), u.getNome(), u.getApelido());

        if (Boolean.FALSE.equals(u.getAtivo())) {
            log.warn("🚫 Conta INATIVA — ID={}", u.getIdUsuario());
            return ResponseEntity.status(401)
                    .body(Map.of("message", "Conta inativa. Contacte o administrador.", "inativo", true));
        }

        // Normaliza $2b$ → $2a$ (hashes gerados fora do Spring)
        String hashVerificado = normalizarHashBcrypt(u.getSenhaHash());
        boolean senhaCorreta  = passwordEncoder.matches(senha, hashVerificado);

        log.info("   BCrypt.matches() → {}", senhaCorreta ? "✅ CORRETO" : "❌ INCORRETO");

        if (!senhaCorreta) {
            log.warn("❌ Senha incorreta para ID={}", u.getIdUsuario());
            return ResponseEntity.status(401)
                    .body(Map.of("message", "Credencial ou senha incorretos."));
        }

        log.info("✅ LOGIN APROVADO — ID={} | primeiraSenha={}", u.getIdUsuario(), u.getPrimeiraSenha());
        log.info("═══════════════════════════════════════════");

        return ResponseEntity.ok(Map.of(
                "usuario",       UsuarioResponse.fromEntity(u),
                "primeiraSenha", Boolean.TRUE.equals(u.getPrimeiraSenha())
        ));
    }

    // ── PATCH /api/auth/{id}/trocar-senha ────────────────────────────────────
    /**
     * Chamado na 1.ª entrada, quando primeiraSenha = true.
     * Body: { "novaSenha": "..." }
     */
    @PatchMapping("/{id}/trocar-senha")
    public ResponseEntity<?> trocarSenha(
            @PathVariable Integer id,
            @RequestBody Map<String, String> body) {

        String novaSenha = body.get("novaSenha");
        log.info("🔄 TROCA DE SENHA — ID={}", id);

        if (novaSenha == null || novaSenha.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "A nova senha não pode estar vazia."));
        }

        return usuarioRepository.findById(id).map(u -> {
            u.setSenhaHash    (passwordEncoder.encode(novaSenha));
            u.setPrimeiraSenha(false);
            usuarioRepository.save(u);
            log.info("✅ Senha trocada — ID={}", id);
            return ResponseEntity.ok().build();
        }).orElseGet(() -> {
            log.warn("❌ ID={} não encontrado", id);
            return ResponseEntity.notFound().build();
        });
    }

    // ── PATCH /api/auth/{id}/alterar-senha ───────────────────────────────────
    /**
     * Utilizado quando o utilizador já está autenticado e quer alterar a senha.
     * Body: { "senhaAtual": "...", "novaSenha": "..." }
     */
    @PatchMapping("/{id}/alterar-senha")
    public ResponseEntity<?> alterarSenha(
            @PathVariable Integer id,
            @RequestBody Map<String, String> body) {

        String senhaAtual = body.get("senhaAtual");
        String novaSenha  = body.get("novaSenha");
        log.info("🔐 ALTERAR SENHA — ID={}", id);

        if (novaSenha == null || novaSenha.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "A nova senha não pode estar vazia."));
        }

        return usuarioRepository.findById(id).map(u -> {
            String hashNormalizado   = normalizarHashBcrypt(u.getSenhaHash());
            boolean senhaAtualCorreta = passwordEncoder.matches(senhaAtual, hashNormalizado);

            if (!senhaAtualCorreta) {
                log.warn("❌ Senha actual incorreta — ID={}", id);
                return ResponseEntity.status(400)
                        .body(Map.of("message", "Senha actual incorreta."));
            }

            u.setSenhaHash    (passwordEncoder.encode(novaSenha));
            u.setPrimeiraSenha(false);
            usuarioRepository.save(u);
            log.info("✅ Senha alterada — ID={}", id);
            return ResponseEntity.ok().build();

        }).orElseGet(() -> {
            log.warn("❌ ID={} não encontrado", id);
            return ResponseEntity.notFound().build();
        });
    }

    // ── Utilitário ────────────────────────────────────────────────────────────
    /**
     * O Flutter/Node.js gera hashes BCrypt com prefixo "$2b$".
     * O Spring Security usa "$2a$" — são idênticos algoritmicamente.
     */
    private String normalizarHashBcrypt(String hash) {
        if (hash != null && hash.startsWith("$2b$")) {
            return "$2a$" + hash.substring(4);
        }
        return hash;
    }
}