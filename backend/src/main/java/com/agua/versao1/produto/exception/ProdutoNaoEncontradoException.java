package com.agua.versao1.produto.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class ProdutoNaoEncontradoException extends RuntimeException {

    public ProdutoNaoEncontradoException(Integer idProduto) {
        super("Produto não encontrado: id=" + idProduto);
    }

    public ProdutoNaoEncontradoException(String mensagem) {
        super(mensagem);
    }
}