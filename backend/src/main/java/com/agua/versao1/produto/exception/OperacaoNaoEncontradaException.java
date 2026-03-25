package com.agua.versao1.produto.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class OperacaoNaoEncontradaException extends RuntimeException {

    public OperacaoNaoEncontradaException(Integer idOperacao) {
        super("Operação não encontrada: id=" + idOperacao);
    }
}