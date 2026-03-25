package com.agua.versao1.usuario.controller;

import com.agua.versao1.usuario.dto.request.UsuarioCreateRequest;
import com.agua.versao1.usuario.dto.request.UsuarioUpdateRequest;
import com.agua.versao1.usuario.dto.response.UsuarioResponse;
import com.agua.versao1.usuario.service.UsuarioService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/usuarios")
@RequiredArgsConstructor
@Slf4j
public class UsuarioController {

    private final UsuarioService usuarioService;

    /** GET /api/usuarios?perfil=2&ativo=true */
    @GetMapping
    public ResponseEntity<List<UsuarioResponse>> listar(
            @RequestParam(required = false) Integer perfil,
            @RequestParam(required = false) Boolean ativo
    ) {
        log.info("GET /api/usuarios — perfil={}, ativo={}", perfil, ativo);
        return ResponseEntity.ok(usuarioService.listarUsuarios(perfil, ativo));
    }

    /** GET /api/usuarios/{id} */
    @GetMapping("/{id}")
    public ResponseEntity<UsuarioResponse> buscarPorId(@PathVariable Integer id) {
        log.info("GET /api/usuarios/{}", id);
        return ResponseEntity.ok(usuarioService.buscarPorId(id));
    }

    /** POST /api/usuarios */
    @PostMapping
    public ResponseEntity<UsuarioResponse> criar(
            @Valid @RequestBody UsuarioCreateRequest req
    ) {
        log.info("POST /api/usuarios — email={}", req.getEmail());
        return ResponseEntity.status(HttpStatus.CREATED).body(usuarioService.criarUsuario(req));
    }

    /** PUT /api/usuarios/{id} */
    @PutMapping("/{id}")
    public ResponseEntity<UsuarioResponse> atualizar(
            @PathVariable Integer id,
            @Valid @RequestBody UsuarioUpdateRequest req
    ) {
        log.info("PUT /api/usuarios/{}", id);
        return ResponseEntity.ok(usuarioService.atualizarUsuario(id, req));
    }

    /** PATCH /api/usuarios/{id}/toggle-status */
    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<UsuarioResponse> toggleStatus(@PathVariable Integer id) {
        log.info("PATCH /api/usuarios/{}/toggle-status", id);
        return ResponseEntity.ok(usuarioService.toggleStatus(id));
    }

    /** PATCH /api/usuarios/{id}/reset-password */
    @PatchMapping("/{id}/reset-password")
    public ResponseEntity<UsuarioResponse> resetarSenha(@PathVariable Integer id) {
        log.info("PATCH /api/usuarios/{}/reset-password", id);
        return ResponseEntity.ok(usuarioService.resetarSenha(id));
    }
}