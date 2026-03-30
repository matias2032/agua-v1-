package com.agua.versao1.usuario.service;

import com.agua.versao1.shared.firebase.FirebaseSyncService;
import com.agua.versao1.usuario.dto.request.UsuarioCreateRequest;
import com.agua.versao1.usuario.dto.request.UsuarioUpdateRequest;
import com.agua.versao1.usuario.dto.response.UsuarioResponse;
import com.agua.versao1.usuario.entity.Usuario;
import com.agua.versao1.usuario.exception.BusinessException;
import com.agua.versao1.usuario.exception.ResourceNotFoundException;
import com.agua.versao1.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class UsuarioService {

    private final UsuarioRepository    usuarioRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    private static final String SENHA_PADRAO  = "12345678";
    private static final int    ID_PERFIL_ADMIN = 1;
    private final FirebaseSyncService firebaseSyncService;

    // ── Listar ───────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<UsuarioResponse> listarUsuarios(Integer idPerfil, Boolean ativo) {
        log.info("Listando usuários — perfil={}, ativo={}", idPerfil, ativo);

        List<Usuario> usuarios;

        if (idPerfil != null && ativo != null) {
            usuarios = usuarioRepository.findByPerfilAndAtivoExceptAdmins(idPerfil, ativo);
        } else if (idPerfil != null) {
            usuarios = usuarioRepository.findByPerfilExceptAdmins(idPerfil);
        } else if (ativo != null) {
            usuarios = usuarioRepository.findByAtivoExceptAdmins(ativo);
        } else {
            usuarios = usuarioRepository.findAllExceptAdmins();
        }

        return usuarios.stream()
                .map(UsuarioResponse::fromEntity)
                .collect(Collectors.toList());
    }

    // ── Buscar por ID ─────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public UsuarioResponse buscarPorId(Integer id) {
        log.info("Buscando usuário ID={}", id);
        return UsuarioResponse.fromEntity(buscarOuFalhar(id));
    }

    // ── Criar ─────────────────────────────────────────────────────────────────

    @Transactional
    public UsuarioResponse criarUsuario(UsuarioCreateRequest req) {
        log.info("Criando usuário email={}", req.getEmail());

        if (usuarioRepository.existsByEmail(req.getEmail())) {
            throw new BusinessException("Já existe um usuário com este email.");
        }

        if (req.getIdPerfil() == ID_PERFIL_ADMIN) {
            throw new BusinessException("Não é permitido criar usuários administradores via este endpoint.");
        }

        Usuario u = Usuario.builder()
                .nome         (req.getNome())
                .apelido      (req.getApelido())
                .email        (req.getEmail())
                .senhaHash    (passwordEncoder.encode(req.getSenha()))
                .telefone     (req.getTelefone())
                .idPerfil     (req.getIdPerfil())
                .ativo        (true)
                .primeiraSenha(true)   // força troca na 1.ª entrada
                .build();

        Usuario salvo = usuarioRepository.save(u);
        firebaseSyncService.sincronizarUsuario(salvo);
        log.info("Usuário criado ID={}", salvo.getIdUsuario());
        return UsuarioResponse.fromEntity(salvo);
    }

    // ── Atualizar ─────────────────────────────────────────────────────────────

    @Transactional
    public UsuarioResponse atualizarUsuario(Integer id, UsuarioUpdateRequest req) {
        log.info("Atualizando usuário ID={}", id);

        Usuario u = buscarOuFalhar(id);

        // Não permite elevar outro utilizador a admin
        if (Integer.valueOf(ID_PERFIL_ADMIN).equals(req.getIdPerfil())
                && !Integer.valueOf(ID_PERFIL_ADMIN).equals(u.getIdPerfil())) {
            throw new BusinessException("Não é permitido atribuir perfil de Administrador.");
        }

        // E-mail já usado por outro registo
        if (!u.getEmail().equals(req.getEmail())
                && usuarioRepository.existsByEmail(req.getEmail())) {
            throw new BusinessException("Já existe outro usuário com este email.");
        }

        u.setNome     (req.getNome());
        u.setApelido  (req.getApelido());
        u.setEmail    (req.getEmail());
        u.setTelefone (req.getTelefone());
        u.setIdPerfil (req.getIdPerfil());

        log.info("Usuário ID={} atualizado", id);
      Usuario salvo = usuarioRepository.save(u);
firebaseSyncService.sincronizarUsuario(salvo);   // ← adicionar
return UsuarioResponse.fromEntity(salvo);

    }

    // ── Toggle status ─────────────────────────────────────────────────────────

    @Transactional
    public UsuarioResponse toggleStatus(Integer id) {
        log.info("Toggle status usuário ID={}", id);

        Usuario u = buscarOuFalhar(id);

        if (Integer.valueOf(ID_PERFIL_ADMIN).equals(u.getIdPerfil())) {
            throw new BusinessException("Não é permitido desativar administradores.");
        }

        u.toggleStatus();
        log.info("Usuário ID={} → {}", id, Boolean.TRUE.equals(u.getAtivo()) ? "ATIVO" : "INATIVO");
        Usuario salvo = usuarioRepository.save(u);
firebaseSyncService.sincronizarUsuario(salvo);   // ← adicionar
return UsuarioResponse.fromEntity(salvo);
    }

    // ── Reset de senha ────────────────────────────────────────────────────────

    @Transactional
    public UsuarioResponse resetarSenha(Integer id) {
        log.info("Reset de senha — usuário ID={}", id);

        Usuario u = buscarOuFalhar(id);
        u.setSenhaHash    (passwordEncoder.encode(SENHA_PADRAO));
        u.setPrimeiraSenha(true);

        log.info("Senha resetada para padrão — ID={}", id);
        Usuario salvo = usuarioRepository.save(u);
firebaseSyncService.sincronizarUsuario(salvo);   // ← adicionar
return UsuarioResponse.fromEntity(salvo);
    }

    // ── Auxiliar ──────────────────────────────────────────────────────────────

    private Usuario buscarOuFalhar(Integer id) {
        return usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado com ID: " + id));
    }
}