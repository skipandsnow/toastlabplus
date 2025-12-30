package com.toastlabplus;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import com.google.cloud.spring.autoconfigure.core.GcpContextAutoConfiguration;
import com.google.cloud.spring.autoconfigure.storage.GcpStorageAutoConfiguration;

@SpringBootApplication(exclude = { GcpContextAutoConfiguration.class, GcpStorageAutoConfiguration.class })
public class McpServerApplication {

    // Secrets to load from GCP Secret Manager
    private static final String[] GCP_SECRETS = {
            "TAVILY_API_KEY",
            "JWT_SECRET",
            "DB_PASSWORD",
            "ADMIN_PASSWORD"
    };

    public static void main(String[] args) {
        loadSecretsFromGcp();
        SpringApplication.run(McpServerApplication.class, args);
    }

    private static void loadSecretsFromGcp() {
        try (com.google.cloud.secretmanager.v1.SecretManagerServiceClient client = com.google.cloud.secretmanager.v1.SecretManagerServiceClient
                .create()) {

            for (String secretName : GCP_SECRETS) {
                loadSecretFromGcp(client, secretName);
            }

        } catch (Exception e) {
            System.err.println("Warning: Failed to connect to Secret Manager: " + e.getMessage());
            System.err.println("Using environment variables or default values for secrets.");
        }
    }

    private static void loadSecretFromGcp(
            com.google.cloud.secretmanager.v1.SecretManagerServiceClient client,
            String secretName) {
        // Skip if already present in environment
        if (System.getenv(secretName) != null) {
            return;
        }

        try {
            com.google.cloud.secretmanager.v1.SecretVersionName secretVersionName = com.google.cloud.secretmanager.v1.SecretVersionName
                    .of("toastlabplus", secretName, "latest");

            com.google.cloud.secretmanager.v1.AccessSecretVersionResponse response = client
                    .accessSecretVersion(secretVersionName);

            String payload = response.getPayload().getData().toStringUtf8();
            System.setProperty(secretName, payload);
            System.out.println("Successfully loaded " + secretName + " from Secret Manager");

        } catch (Exception e) {
            System.err.println("Warning: Failed to load " + secretName + " from Secret Manager: " + e.getMessage());
        }
    }
}
