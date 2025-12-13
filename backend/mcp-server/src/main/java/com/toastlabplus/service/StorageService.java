package com.toastlabplus.service;

import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;

/**
 * Storage service interface for file uploads
 */
public interface StorageService {
    /**
     * Upload a file to cloud storage
     * 
     * @param file   The file to upload
     * @param folder The folder/prefix to store the file under
     * @return The public URL of the uploaded file
     */
    String uploadFile(MultipartFile file, String folder) throws IOException;

    /**
     * Delete a file from cloud storage
     * 
     * @param fileUrl The URL of the file to delete
     */
    void deleteFile(String fileUrl);
}
