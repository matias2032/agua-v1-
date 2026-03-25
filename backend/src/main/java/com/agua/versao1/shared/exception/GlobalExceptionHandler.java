package com.agua.versao1.shared.exception;

import com.agua.versao1.produto.exception.OperacaoNaoEncontradaException;
import com.agua.versao1.produto.exception.ProdutoNaoEncontradoException;
import com.agua.versao1.usuario.exception.BusinessException;
import com.agua.versao1.usuario.exception.ResourceNotFoundException;
import com.agua.versao1.shared.response.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;

import java.util.stream.Collectors;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    // ── 404 NOT FOUND ───────────────────────────────────────────────────────
    @ExceptionHandler({
        ResourceNotFoundException.class, 
        ProdutoNaoEncontradoException.class, 
        OperacaoNaoEncontradaException.class
    })
    public ResponseEntity<ApiResponse<Void>> handleNotFound(RuntimeException ex, WebRequest req) {
        log.error("Recurso não encontrado [{}]: {}", path(req), ex.getMessage());
        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.erro(ex.getMessage()));
    }

    // ── 400 BAD REQUEST (Regras de Negócio) ─────────────────────────────────
    @ExceptionHandler({
        BusinessException.class,
        IllegalArgumentException.class,
        IllegalStateException.class
    })
    public ResponseEntity<ApiResponse<Void>> handleBusiness(RuntimeException ex, WebRequest req) {
        log.warn("Violação de regra de negócio [{}]: {}", path(req), ex.getMessage());
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.erro(ex.getMessage()));
    }

    // ── 422 UNPROCESSABLE ENTITY (Validação de Campos) ──────────────────────
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidation(MethodArgumentNotValidException ex, WebRequest req) {
        String detalhes = ex.getBindingResult().getFieldErrors()
                .stream()
                .map(f -> f.getField() + ": " + f.getDefaultMessage())
                .collect(Collectors.joining("; "));
        
        log.warn("Erro de validação [{}]: {}", path(req), detalhes);
        
        return ResponseEntity
                .status(HttpStatus.UNPROCESSABLE_ENTITY)
                .body(ApiResponse.erro("Campos inválidos: " + detalhes));
    }

    // ── 500 INTERNAL SERVER ERROR (Erro Genérico) ───────────────────────────
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleGeneric(Exception ex, WebRequest req) {
        log.error("ERRO CRÍTICO NO SISTEMA [{}]: ", path(req), ex);
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.erro("Ocorreu um erro interno inesperado. Por favor, tente mais tarde."));
    }

    private String path(WebRequest req) {
        return req.getDescription(false).replace("uri=", "");
    }
}