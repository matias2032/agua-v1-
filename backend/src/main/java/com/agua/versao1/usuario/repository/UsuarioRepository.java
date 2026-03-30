package com.agua.versao1.usuario.repository;

import com.agua.versao1.usuario.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Integer> {

    Optional<Usuario> findByEmail(String email);

    boolean existsByEmail(String email);

    /** Busca por email, telefone ou apelido — usado no login */
   @Query("SELECT u FROM Usuario u WHERE u.email = :c OR u.telefone = :c OR u.apelido = :c")
List<Usuario> findByEmailOrTelefoneOrApelido(@Param("c") String credencial);

    /** Lista todos exceto admins (id_perfil = 1) */
    @Query("SELECT u FROM Usuario u WHERE u.idPerfil != 1")
    List<Usuario> findAllExceptAdmins();

    @Query("SELECT u FROM Usuario u WHERE u.idPerfil = :idPerfil AND u.idPerfil != 1")
    List<Usuario> findByPerfilExceptAdmins(@Param("idPerfil") Integer idPerfil);

    @Query("SELECT u FROM Usuario u WHERE u.ativo = :ativo AND u.idPerfil != 1")
    List<Usuario> findByAtivoExceptAdmins(@Param("ativo") Boolean ativo);

    @Query("SELECT u FROM Usuario u WHERE u.idPerfil = :idPerfil AND u.ativo = :ativo AND u.idPerfil != 1")
    List<Usuario> findByPerfilAndAtivoExceptAdmins(
            @Param("idPerfil") Integer idPerfil,
            @Param("ativo") Boolean ativo
    );
}