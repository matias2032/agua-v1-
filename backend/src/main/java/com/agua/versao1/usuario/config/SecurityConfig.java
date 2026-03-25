package com.agua.versao1.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;

/**
 * Configuração de segurança para criptografia de senhas e autenticação
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    /**
     * Bean do BCrypt para hash de senhas
     * Força: 12 rounds (padrão é 10)
     */
    @Bean
    public BCryptPasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }

    /**
     * Configuração da cadeia de filtros de segurança
     * TEMPORÁRIO: Permite acesso sem autenticação para desenvolvimento
     * TODO: Implementar JWT/OAuth2 em produção
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // Desabilita CSRF (necessário para APIs REST)
            .csrf(csrf -> csrf.disable())
            
            // Configura CORS para permitir requisições do Flutter
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            
            // Configuração de autorização
            .authorizeHttpRequests(auth -> auth
                // Permite acesso público às APIs
                .requestMatchers("/api/**").permitAll()
                
                // Permite acesso ao H2 Console (se estiver usando)
                .requestMatchers("/h2-console/**").permitAll()
                
                // Outras requisições podem exigir autenticação futuramente
                .anyRequest().permitAll() // Ou use .authenticated() quando implementar login
            )
            
            // Desabilita frame options para permitir H2 Console (se necessário)
            .headers(headers -> headers
                .frameOptions(frame -> frame.sameOrigin())
            );
        
        return http.build();
    }

    /**
     * Configuração de CORS (Cross-Origin Resource Sharing)
     * Permite que o Flutter (rodando em localhost ou IP local) acesse a API
     */
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    
    // allowedOriginPatterns suporta "*" com allowCredentials=true
    // allowedOrigins com "*" é INCOMPATÍVEL com allowCredentials=true
    configuration.setAllowedOriginPatterns(Arrays.asList("*"));
    
    configuration.setAllowedMethods(Arrays.asList(
        "GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"
    ));
    
    configuration.setAllowedHeaders(Arrays.asList("*"));
    
    // Uma única chamada — remover o setExposedHeaders duplicado
configuration.setExposedHeaders(Arrays.asList(
    "Authorization", "Content-Type", "X-Total-Count", "X-User-Id"
));
    
    configuration.setAllowCredentials(true);
    configuration.setMaxAge(3600L);
    
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    // Aplica a TODAS as rotas, não só /api/**
    source.registerCorsConfiguration("/**", configuration);
    
    return source;
}
}