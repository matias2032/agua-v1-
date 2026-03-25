package com.agua.versao1.shared.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.*;

import java.time.Instant;

/**
 * Envelope padrão de resposta da API.
 *
 * Sucesso:  { "sucesso": true,  "dados": {...},  "erro": null  }
 * Erro:     { "sucesso": false, "dados": null,   "erro": "..." }
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

    private boolean sucesso;
    private T dados;
    private String erro;

    @Builder.Default
    private Instant timestamp = Instant.now();

    public static <T> ApiResponse<T> ok(T dados) {
        return ApiResponse.<T>builder()
                .sucesso(true)
                .dados(dados)
                .build();
    }

    public static <T> ApiResponse<T> erro(String mensagem) {
        return ApiResponse.<T>builder()
                .sucesso(false)
                .erro(mensagem)
                .build();
    }
}