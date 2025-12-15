package com.toastlabplus.controller;

import com.toastlabplus.entity.AgendaTemplate;
import com.toastlabplus.entity.Club;
import com.toastlabplus.entity.Member;
import com.toastlabplus.repository.AgendaTemplateRepository;
import com.toastlabplus.repository.ClubAdminRepository;
import com.toastlabplus.repository.ClubRepository;
import com.toastlabplus.repository.MemberRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.google.cloud.storage.BlobId;
import com.google.cloud.storage.BlobInfo;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/clubs/{clubId}/templates")
public class AgendaTemplateController {

    private final AgendaTemplateRepository templateRepository;
    private final ClubRepository clubRepository;
    private final ClubAdminRepository clubAdminRepository;
    private final MemberRepository memberRepository;

    @Value("${gcs.bucket.templates:toastlabplus-templates}")
    private String templatesBucket;

    @Value("${chat.backend.url:http://localhost:8000}")
    private String chatBackendUrl;

    public AgendaTemplateController(
            AgendaTemplateRepository templateRepository,
            ClubRepository clubRepository,
            ClubAdminRepository clubAdminRepository,
            MemberRepository memberRepository) {
        this.templateRepository = templateRepository;
        this.clubRepository = clubRepository;
        this.clubAdminRepository = clubAdminRepository;
        this.memberRepository = memberRepository;
    }

    /**
     * Get all templates for a club.
     */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getTemplates(@PathVariable Long clubId) {
        List<AgendaTemplate> templates = templateRepository.findByClubIdAndIsActiveTrue(clubId);

        List<Map<String, Object>> result = new ArrayList<>();
        for (AgendaTemplate template : templates) {
            result.add(templateToMap(template));
        }

        return ResponseEntity.ok(result);
    }

    /**
     * Get a specific template.
     */
    @GetMapping("/{templateId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getTemplate(
            @PathVariable Long clubId,
            @PathVariable Long templateId) {

        AgendaTemplate template = templateRepository.findByIdAndClubId(templateId, clubId).orElse(null);
        if (template == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(templateToMap(template));
    }

    /**
     * Upload a new template.
     */
    @PostMapping("/upload")
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> uploadTemplate(
            @PathVariable Long clubId,
            @RequestParam("file") MultipartFile file,
            @RequestParam("name") String name,
            @RequestParam(value = "description", required = false) String description,
            @AuthenticationPrincipal UserDetails userDetails) {

        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        if (!isClubAdmin(currentMember, clubId)) {
            return ResponseEntity.status(403).body(Map.of("error", "You are not an admin of this club"));
        }

        // Validate file type
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null ||
                (!originalFilename.endsWith(".xlsx") && !originalFilename.endsWith(".xls"))) {
            return ResponseEntity.badRequest().body(Map.of("error", "Only Excel files (.xlsx, .xls) are allowed"));
        }

        Club club = clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        try {
            // Upload to GCS
            String gcsPath = uploadToGcs(clubId, file);

            // Create template record
            AgendaTemplate template = new AgendaTemplate(club, name);
            template.setDescription(description);
            template.setOriginalFilename(originalFilename);
            template.setGcsPath(gcsPath);
            template.setCreatedBy(currentMember);

            AgendaTemplate saved = templateRepository.save(template);

            return ResponseEntity.ok(Map.of(
                    "message", "Template uploaded successfully",
                    "templateId", saved.getId(),
                    "gcsPath", gcsPath));

        } catch (IOException e) {
            return ResponseEntity.status(500).body(Map.of("error", "Failed to upload file: " + e.getMessage()));
        }
    }

    /**
     * Trigger LLM parsing for a template.
     */
    @PostMapping("/{templateId}/parse")
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> parseTemplate(
            @PathVariable Long clubId,
            @PathVariable Long templateId,
            @AuthenticationPrincipal UserDetails userDetails) {

        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        if (!isClubAdmin(currentMember, clubId)) {
            return ResponseEntity.status(403).body(Map.of("error", "You are not an admin of this club"));
        }

        AgendaTemplate template = templateRepository.findByIdAndClubId(templateId, clubId).orElse(null);
        if (template == null) {
            return ResponseEntity.notFound().build();
        }

        if (template.getGcsPath() == null || template.getGcsPath().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Template has no uploaded file"));
        }

        try {
            // 1. Download Excel from GCS
            byte[] excelBytes = downloadFromGcs(template.getGcsPath());

            // 2. Extract text content using Apache POI
            String excelContent = extractExcelContent(excelBytes);

            // 3. Call chat-backend /parse-template endpoint
            String parsedJson = callChatBackendParse(excelContent, template.getOriginalFilename());

            // 4. Save parsed structure
            template.setParsedStructure(parsedJson);
            template.setUpdatedAt(LocalDateTime.now());
            templateRepository.save(template);

            return ResponseEntity.ok(Map.of(
                    "message", "Template parsed successfully",
                    "templateId", templateId,
                    "parsedStructure", parsedJson));

        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of(
                    "error", "Failed to parse template: " + e.getMessage()));
        }
    }

    /**
     * Delete a template.
     */
    @DeleteMapping("/{templateId}")
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> deleteTemplate(
            @PathVariable Long clubId,
            @PathVariable Long templateId,
            @AuthenticationPrincipal UserDetails userDetails) {

        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        if (!isClubAdmin(currentMember, clubId)) {
            return ResponseEntity.status(403).body(Map.of("error", "You are not an admin of this club"));
        }

        AgendaTemplate template = templateRepository.findByIdAndClubId(templateId, clubId).orElse(null);
        if (template == null) {
            return ResponseEntity.notFound().build();
        }

        // Soft delete
        template.setIsActive(false);
        template.setUpdatedAt(LocalDateTime.now());
        templateRepository.save(template);

        return ResponseEntity.ok(Map.of("message", "Template deleted"));
    }

    // ==================== Helper Methods ====================

    private boolean isClubAdmin(Member member, Long clubId) {
        return "PLATFORM_ADMIN".equals(member.getRole()) ||
                clubAdminRepository.existsByMemberIdAndClubId(member.getId(), clubId);
    }

    private Map<String, Object> templateToMap(AgendaTemplate template) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", template.getId());
        map.put("name", template.getName());
        map.put("description", template.getDescription());
        map.put("originalFilename", template.getOriginalFilename());
        map.put("version", template.getVersion());
        map.put("isActive", template.getIsActive());
        map.put("createdAt", template.getCreatedAt());
        map.put("hasParsedStructure", template.getParsedStructure() != null);
        map.put("parsedStructure", template.getParsedStructure());
        return map;
    }

    private String uploadToGcs(Long clubId, MultipartFile file) throws IOException {
        Storage storage = StorageOptions.getDefaultInstance().getService();

        String filename = UUID.randomUUID().toString() + "_" + file.getOriginalFilename();
        String objectName = "clubs/" + clubId + "/templates/" + filename;

        BlobId blobId = BlobId.of(templatesBucket, objectName);
        BlobInfo blobInfo = BlobInfo.newBuilder(blobId)
                .setContentType(file.getContentType())
                .build();

        storage.create(blobInfo, file.getBytes());

        return "gs://" + templatesBucket + "/" + objectName;
    }

    private byte[] downloadFromGcs(String gcsPath) throws IOException {
        Storage storage = StorageOptions.getDefaultInstance().getService();

        // Parse gs://bucket/path format
        String path = gcsPath.replace("gs://", "");
        int slashIndex = path.indexOf('/');
        String bucket = path.substring(0, slashIndex);
        String objectName = path.substring(slashIndex + 1);

        BlobId blobId = BlobId.of(bucket, objectName);
        return storage.readAllBytes(blobId);
    }

    private String extractExcelContent(byte[] excelBytes) throws IOException {
        StringBuilder content = new StringBuilder();

        try (org.apache.poi.xssf.usermodel.XSSFWorkbook workbook = new org.apache.poi.xssf.usermodel.XSSFWorkbook(
                new java.io.ByteArrayInputStream(excelBytes))) {

            // Only read the first sheet (Agenda)
            if (workbook.getNumberOfSheets() > 0) {
                org.apache.poi.ss.usermodel.Sheet sheet = workbook.getSheetAt(0);
                content.append("=== Sheet: ").append(sheet.getSheetName()).append(" ===\n");
                content.append("Format: [Row,Column] Content\n\n");

                for (org.apache.poi.ss.usermodel.Row row : sheet) {
                    int rowNum = row.getRowNum() + 1; // 1-indexed for user-friendliness
                    for (org.apache.poi.ss.usermodel.Cell cell : row) {
                        String cellValue = getCellValueAsString(cell);
                        if (!cellValue.isEmpty()) {
                            int colNum = cell.getColumnIndex() + 1; // 1-indexed
                            // Format: [R行,C列] 內容
                            content.append("[R").append(rowNum).append(",C").append(colNum).append("] ")
                                    .append(cellValue).append("\n");
                        }
                    }
                }
                content.append("\n");
            }
        }

        return content.toString();
    }

    private String getCellValueAsString(org.apache.poi.ss.usermodel.Cell cell) {
        if (cell == null)
            return "";

        switch (cell.getCellType()) {
            case STRING:
                return cell.getStringCellValue().trim();
            case NUMERIC:
                if (org.apache.poi.ss.usermodel.DateUtil.isCellDateFormatted(cell)) {
                    return cell.getLocalDateTimeCellValue().toString();
                }
                double num = cell.getNumericCellValue();
                if (num == Math.floor(num)) {
                    return String.valueOf((long) num);
                }
                return String.valueOf(num);
            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());
            case FORMULA:
                try {
                    return cell.getStringCellValue().trim();
                } catch (Exception e) {
                    try {
                        return String.valueOf(cell.getNumericCellValue());
                    } catch (Exception e2) {
                        return "";
                    }
                }
            default:
                return "";
        }
    }

    private String callChatBackendParse(String templateContent, String filename) throws IOException {
        java.net.URL url = new java.net.URL(chatBackendUrl + "/parse-template");
        java.net.HttpURLConnection conn = (java.net.HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setDoOutput(true);

        // Build request body
        com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
        String requestBody = String.format(
                "{\"template_content\": %s, \"filename\": \"%s\"}",
                mapper.writeValueAsString(templateContent),
                filename != null ? filename : "");

        try (java.io.OutputStream os = conn.getOutputStream()) {
            os.write(requestBody.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        }

        int responseCode = conn.getResponseCode();
        if (responseCode != 200) {
            throw new IOException("Chat backend returned status: " + responseCode);
        }

        try (java.io.BufferedReader reader = new java.io.BufferedReader(
                new java.io.InputStreamReader(conn.getInputStream(), java.nio.charset.StandardCharsets.UTF_8))) {
            StringBuilder response = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                response.append(line);
            }
            return response.toString();
        }
    }
}
