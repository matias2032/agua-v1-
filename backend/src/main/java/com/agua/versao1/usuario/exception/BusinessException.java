package com.agua.versao1.usuario.exception;
 
public class BusinessException extends RuntimeException {
    public BusinessException(String message)                  { super(message); }
    public BusinessException(String message, Throwable cause) { super(message, cause); }
}