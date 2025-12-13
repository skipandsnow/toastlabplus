package com.toastlabplus.service.impl;

import com.google.cloud.storage.BlobId;
import com.google.cloud.storage.BlobInfo;
import com.google.cloud.storage.Storage;
import com.toastlabplus.service.StorageService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

/**
 * GCP Cloud Storage implementation of StorageService.
 * Only activated when gcp.storage.enabled=true
 */
@Service
@ConditionalOnProperty(name = "gcp.storage.enabled", havingValue = "true")
public class GcpStorageService implements StorageService {

    private static final Logger log = LoggerFactory.getLogger(GcpStorageService.class);

    private final Storage storage;

    @Value("${gcp.storage.bucket-name}")
    private String bucketName;

    public GcpStorageService(Storage storage) {
        this.storage = storage;
        log.info("GCP Storage Service initialized");
    }

    @Override
    public String uploadFile(MultipartFile file, String folder) throws IOException {
        String originalFilename = file.getOriginalFilename();
        String extension = (originalFilename != null && originalFilename.contains("."))
                ? originalFilename.substring(originalFilename.lastIndexOf("."))
                : "";
        String fileName = folder + "/" + UUID.randomUUID().toString() + extension;

        BlobId blobId = BlobId.of(bucketName, fileName);
        BlobInfo blobInfo = BlobInfo.newBuilder(blobId)
                .setContentType(file.getContentType())
                .build();

        storage.create(blobInfo, file.getBytes());

        String publicUrl = String.format("https://storage.googleapis.com/%s/%s", bucketName, fileName);
        log.info("Uploaded file to: {}", publicUrl);
        return publicUrl;
    }

    @Override
    public void deleteFile(String fileUrl) {
        try {
            String prefix = String.format("https://storage.googleapis.com/%s/", bucketName);
            if (fileUrl.startsWith(prefix)) {
                String blobName = fileUrl.substring(prefix.length());
                BlobId blobId = BlobId.of(bucketName, blobName);
                boolean deleted = storage.delete(blobId);
                if (deleted) {
                    log.info("Deleted file: {}", blobName);
                } else {
                    log.warn("File not found for deletion: {}", blobName);
                }
            }
        } catch (Exception e) {
            log.error("Error deleting file: {}", fileUrl, e);
        }
    }
}
