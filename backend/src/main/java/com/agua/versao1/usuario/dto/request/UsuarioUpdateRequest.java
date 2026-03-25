package com.agua.versao1.usuario.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UsuarioUpdateRequest {

    @NotBlank(message = "O nome é obrigatório")
    @Size(max = 150, message = "O nome deve ter no máximo 150 caracteres")
    private String nome;

    @Size(max = 100, message = "O apelido deve ter no máximo 100 caracteres")
    private String apelido;

    @NotBlank(message = "O email é obrigatório")
    @Email(message = "Email inválido")
    private String email;

    @Size(max = 30, message = "O telefone deve ter no máximo 30 caracteres")
    private String telefone;

    @NotNull(message = "O perfil é obrigatório")
    private Integer idPerfil;
}