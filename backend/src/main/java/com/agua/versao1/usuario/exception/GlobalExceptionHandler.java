package com.agua.versao1.usuario.exception;
 
import lombok.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
 
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
 
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {
 
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex, WebRequest req) {
        log.error("Recurso não encontrado: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(404)
                .error("Recurso não encontrado")
                .message(ex.getMessage())
                .path(path(req))
                .build());
    }
 
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ErrorResponse> handleBusiness(BusinessException ex, WebRequest req) {
        log.error("Regra de negócio violada: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(400)
                .error("Erro de negócio")
                .message(ex.getMessage())
                .path(path(req))
                .build());
    }
 
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ValidationErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach(e -> {
            String field = ((FieldError) e).getField();
            errors.put(field, e.getDefaultMessage());
        });
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ValidationErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(400)
                .error("Erro de validação")
                .message("Campos inválidos")
                .errors(errors)
                .build());
    }
 
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneric(Exception ex, WebRequest req) {
        log.error("Erro interno: ", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(500)
                .error("Erro interno")
                .message("Ocorreu um erro inesperado.")
                .path(path(req))
                .build());
    }
 
    private String path(WebRequest req) {
        return req.getDescription(false).replace("uri=", "");
    }
 
    // ── Payloads de resposta ──────────────────────────────────────────────────
 
    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class ErrorResponse {
        private LocalDateTime timestamp;
        private Integer       status;
        private String        error;
        private String        message;
        private String        path;
    }
 
    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class ValidationErrorResponse {
        private LocalDateTime       timestamp;
        private Integer             status;
        private String              error;
        private String              message;
        private Map<String, String> errors;
    }
}