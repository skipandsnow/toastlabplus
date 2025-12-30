package com.toastlabplus;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import com.google.cloud.spring.autoconfigure.core.GcpContextAutoConfiguration;
import com.google.cloud.spring.autoconfigure.storage.GcpStorageAutoConfiguration;

@SpringBootApplication(exclude = { GcpContextAutoConfiguration.class, GcpStorageAutoConfiguration.class })
public class McpServerApplication {

    public static void main(String[] args) {
        loadTavilyKey();
        SpringApplication.run(McpServerApplication.class, args);
    }

    private static void loadTavilyKey() {
        // Only load if not present in environment (e.g. Local Dev)
        if (System.getenv("TAVILY_API_KEY") != null) {
            return;
        }

        try (com.google.cloud.secretmanager.v1.SecretManagerServiceClient client = com.google.cloud.secretmanager.v1.SecretManagerServiceClient
                .create()) {

            com.google.cloud.secretmanager.v1.SecretVersionName secretVersionName = com.google.cloud.secretmanager.v1.SecretVersionName
                    .of("toastlabplus", "TAVILY_API_KEY", "latest");

            com.google.cloud.secretmanager.v1.AccessSecretVersionResponse response = client
                    .accessSecretVersion(secretVersionName);

            String payload = response.getPayload().getData().toStringUtf8();
            System.setProperty("TAVILY_API_KEY", payload);
            System.out.println("Successfully loaded TAVILY_API_KEY from Secret Manager (Native Client)");

        } catch (Exception e) {
            System.err.println("Warning: Failed to load TAVILY_API_KEY from Secret Manager: " + e.getMessage());
            System.err.println("Ignore this warning if you are not using features requiring TAVILY_API_KEY.");
        }
    }
}
