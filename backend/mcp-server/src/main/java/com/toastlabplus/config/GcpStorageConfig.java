package com.toastlabplus.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

import java.io.IOException;

/**
 * GCP Storage configuration - creates Storage bean for both local and cloud
 * environments.
 */
@Configuration
@ConditionalOnProperty(name = "gcp.storage.enabled", havingValue = "true", matchIfMissing = true)
public class GcpStorageConfig {

    private static final Logger log = LoggerFactory.getLogger(GcpStorageConfig.class);

    @Value("${spring.cloud.gcp.project-id}")
    private String projectId;

    @Value("${spring.cloud.gcp.credentials.location:}")
    private Resource credentialsLocation;

    @Bean
    public Storage storage() throws IOException {
        StorageOptions.Builder builder = StorageOptions.newBuilder()
                .setProjectId(projectId);

        if (credentialsLocation != null && credentialsLocation.exists()) {
            log.info("Loading GCP credentials from: {}", credentialsLocation.getDescription());
            GoogleCredentials credentials = GoogleCredentials.fromStream(credentialsLocation.getInputStream());
            builder.setCredentials(credentials);
        } else {
            log.info("Using default GCP credentials (Application Default Credentials)");
        }

        return builder.build().getService();
    }
}
