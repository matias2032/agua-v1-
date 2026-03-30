package com.agua.versao1.shared.firebase;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;

/**
 * Inicializa o Firebase Admin SDK ao arrancar o Spring Boot.
 *
 * O ficheiro firebase-service-account.json deve estar em:
 *   src/main/resources/firebase-service-account.json
 *
 * Se o ficheiro não existir (ex: ambiente de dev sem Firebase),
 * a inicialização é ignorada com um aviso no log — o sistema
 * continua a funcionar normalmente sem sincronização Firebase.
 */
@Configuration
public class FirebaseConfig {

    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

    @PostConstruct
    public void inicializarFirebase() {
        // Evita re-inicializar se já existe uma instância (ex: hot-reload)
        if (!FirebaseApp.getApps().isEmpty()) {
            log.info("Firebase já inicializado — ignorando.");
            return;
        }

        try {
            ClassPathResource resource = new ClassPathResource("firebase-service-account.json");

            if (!resource.exists()) {
                log.warn("⚠️  firebase-service-account.json não encontrado. " +
                         "Sincronização Firebase desactivada.");
                return;
            }

            try (InputStream serviceAccount = resource.getInputStream()) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                FirebaseApp.initializeApp(options);
                log.info("✅ Firebase Admin SDK inicializado com sucesso.");
            }

        } catch (IOException e) {
            log.error("❌ Falha ao inicializar Firebase Admin SDK: {}", e.getMessage(), e);
            // Não lança excepção — o sistema funciona sem Firebase
        }
    }
}