package com.toastlabplus.controller;

import com.toastlabplus.entity.*;
import com.toastlabplus.repository.*;
import com.google.cloud.storage.BlobId;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.io.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/meetings/{meetingId}/agenda")
public class AgendaGenerationController {

    private final MeetingRepository meetingRepository;
    private final RoleSlotRepository roleSlotRepository;
    private final AgendaTemplateRepository templateRepository;
    private final ClubAdminRepository clubAdminRepository;
    private final MemberRepository memberRepository;
    private final ClubMembershipRepository clubMembershipRepository;

    @Value("${gcs.bucket.templates:toastlabplus-templates}")
    private String templatesBucket;

    public AgendaGenerationController(
            MeetingRepository meetingRepository,
            RoleSlotRepository roleSlotRepository,
            AgendaTemplateRepository templateRepository,
            ClubAdminRepository clubAdminRepository,
            MemberRepository memberRepository,
            ClubMembershipRepository clubMembershipRepository) {
        this.meetingRepository = meetingRepository;
        this.roleSlotRepository = roleSlotRepository;
        this.templateRepository = templateRepository;
        this.clubAdminRepository = clubAdminRepository;
        this.memberRepository = memberRepository;
        this.clubMembershipRepository = clubMembershipRepository;
    }

    /**
     * Generate agenda Excel file for a meeting.
     */
    @GetMapping("/generate")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> generateAgenda(
            @PathVariable Long meetingId,
            @RequestParam(required = false) Long templateId,
            @AuthenticationPrincipal UserDetails userDetails) {

        Meeting meeting = meetingRepository.findById(meetingId).orElse(null);
        if (meeting == null) {
            return ResponseEntity.notFound().build();
        }

        // Get template
        AgendaTemplate template = null;
        if (templateId != null) {
            template = templateRepository.findById(templateId).orElse(null);
        } else if (meeting.getTemplateId() != null) {
            template = templateRepository.findById(meeting.getTemplateId()).orElse(null);
        } else {
            // Find first active template for the club
            List<AgendaTemplate> templates = templateRepository.findByClubIdAndIsActiveTrue(meeting.getClub().getId());
            if (!templates.isEmpty()) {
                template = templates.get(0);
            }
        }

        if (template == null || template.getGcsPath() == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "No template available for this meeting"));
        }

        try {
            // Download template from GCS
            byte[] templateBytes = downloadFromGcs(template.getGcsPath());

            // Get variable mappings from parsed structure
            List<Map<String, Object>> variableMappings = parseVariableMappings(template.getParsedStructure());

            // Generate filled agenda
            byte[] generatedAgenda = generateFilledAgenda(templateBytes, meeting, variableMappings);

            // Return as downloadable file
            String filename = String.format("Agenda_%s_%s.xlsx",
                    meeting.getClub().getName().replaceAll("[^a-zA-Z0-9]", "_"),
                    meeting.getMeetingDate().format(DateTimeFormatter.ISO_DATE));

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(
                    MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"));
            headers.setContentDisposition(ContentDisposition.builder("attachment").filename(filename).build());
            headers.setContentLength(generatedAgenda.length);

            return new ResponseEntity<>(generatedAgenda, headers, HttpStatus.OK);

        } catch (Exception e) {
            System.err.println("=== GENERATE AGENDA ERROR ===");
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", "Failed to generate agenda: " + e.getMessage()));
        }
    }

    /**
     * Preview agenda data (JSON) without generating file.
     */
    @GetMapping("/preview")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> previewAgenda(@PathVariable Long meetingId) {
        Meeting meeting = meetingRepository.findById(meetingId).orElse(null);
        if (meeting == null) {
            return ResponseEntity.notFound().build();
        }

        Map<String, Object> agendaData = buildAgendaData(meeting);
        return ResponseEntity.ok(agendaData);
    }

    // ==================== Helper Methods ====================

    private byte[] downloadFromGcs(String gcsPath) throws IOException {
        Storage storage = StorageOptions.getDefaultInstance().getService();

        String path = gcsPath.replace("gs://", "");
        int slashIndex = path.indexOf('/');
        String bucket = path.substring(0, slashIndex);
        String objectName = path.substring(slashIndex + 1);

        BlobId blobId = BlobId.of(bucket, objectName);
        return storage.readAllBytes(blobId);
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> parseVariableMappings(String parsedStructure) {
        if (parsedStructure == null || parsedStructure.isEmpty()) {
            return new ArrayList<>();
        }

        try {
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            Map<String, Object> parsed = mapper.readValue(parsedStructure, Map.class);
            Object mappings = parsed.get("variable_mappings");
            if (mappings instanceof List) {
                return (List<Map<String, Object>>) mappings;
            }
        } catch (Exception e) {
            System.err.println("Failed to parse variable_mappings: " + e.getMessage());
        }

        return new ArrayList<>();
    }

    private Map<String, Object> buildAgendaData(Meeting meeting) {
        Map<String, Object> data = new HashMap<>();

        // Basic meeting info - match template variable names
        data.put("MEETING_DATE", meeting.getMeetingDate()
                .format(DateTimeFormatter.ofPattern("EEEE, MMM d, yyyy", java.util.Locale.ENGLISH)));
        data.put("MEETING_NUMBER", meeting.getMeetingNumber() != null ? "#" + meeting.getMeetingNumber() : "");
        data.put("THEME", meeting.getTheme() != null ? meeting.getTheme() : "");
        data.put("CLUB_NAME", meeting.getClub().getName());
        data.put("LOCATION", meeting.getLocation() != null ? meeting.getLocation() : "");
        data.put("START_TIME", meeting.getStartTime() != null ? meeting.getStartTime() : "");
        data.put("END_TIME", meeting.getEndTime() != null ? meeting.getEndTime() : "");

        // Get role slots
        List<RoleSlot> roleSlots = roleSlotRepository.findByMeetingIdWithMember(meeting.getId());

        // Fill role-based variables with _NAME suffix (matching template format)
        for (RoleSlot slot : roleSlots) {
            String roleName = slot.getRoleName().toUpperCase().replace(" ", "_");
            String memberName = slot.getAssignedMember() != null
                    ? slot.getAssignedMember().getName()
                    : "";

            // For indexed roles (SPEAKER, EVALUATOR) with index > 0
            if (slot.getSlotIndex() != null && slot.getSlotIndex() > 0
                    && ("SPEAKER".equals(roleName) || "EVALUATOR".equals(roleName))) {
                // Speaker 1, 2, 3 - use format like SPEAKER_1_NAME or just map by index
                if ("SPEAKER".equals(roleName)) {
                    data.put("SPEAKER_" + slot.getSlotIndex() + "_NAME", memberName);
                    data.put("SPEAKER_NAME_" + slot.getSlotIndex(), memberName);
                    data.put("SPEECH_TITLE_" + slot.getSlotIndex(),
                            slot.getSpeechTitle() != null ? slot.getSpeechTitle() : "");
                    data.put("SPEECH_PROJECT_" + slot.getSlotIndex(),
                            slot.getProjectName() != null ? slot.getProjectName() : "");
                } else { // EVALUATOR
                    data.put("EVALUATOR_" + slot.getSlotIndex() + "_NAME", memberName);
                    data.put("INDIVIDUAL_EVALUATOR_" + slot.getSlotIndex() + "_NAME", memberName);
                }
            } else {
                // For non-indexed roles (or roles other than SPEAKER/EVALUATOR) - add _NAME
                // suffix
                data.put(roleName + "_NAME", memberName);
                // Also add without suffix for flexibility
                data.put(roleName, memberName);

                // Handle special mappings
                if ("TT_MASTER".equals(roleName)) {
                    data.put("TABLE_TOPICS_MASTER_NAME", memberName);
                }
            }
        }

        // Speakers list for dynamic blocks
        List<Map<String, String>> speakers = roleSlots.stream()
                .filter(s -> "SPEAKER".equals(s.getRoleName()))
                .sorted(Comparator.comparingInt(s -> s.getSlotIndex() != null ? s.getSlotIndex() : 0))
                .map(s -> {
                    Map<String, String> speakerData = new HashMap<>();
                    speakerData.put("name", s.getAssignedMember() != null
                            ? s.getAssignedMember().getName()
                            : "");
                    speakerData.put("title", s.getSpeechTitle() != null ? s.getSpeechTitle() : "");
                    speakerData.put("project", s.getProjectName() != null ? s.getProjectName() : "");
                    return speakerData;
                })
                .collect(Collectors.toList());
        data.put("SPEAKERS", speakers);

        // Evaluators list for dynamic blocks
        List<Map<String, String>> evaluators = roleSlots.stream()
                .filter(s -> "EVALUATOR".equals(s.getRoleName()))
                .sorted(Comparator.comparingInt(s -> s.getSlotIndex() != null ? s.getSlotIndex() : 0))
                .map(s -> {
                    Map<String, String> evalData = new HashMap<>();
                    evalData.put("name", s.getAssignedMember() != null
                            ? s.getAssignedMember().getName()
                            : "");
                    return evalData;
                })
                .collect(Collectors.toList());
        data.put("EVALUATORS", evaluators);

        return data;
    }

    @SuppressWarnings("unchecked")
    private byte[] generateFilledAgenda(byte[] templateBytes, Meeting meeting,
            List<Map<String, Object>> variableMappings) throws IOException {
        Map<String, Object> agendaData = buildAgendaData(meeting);

        try (XSSFWorkbook workbook = new XSSFWorkbook(new ByteArrayInputStream(templateBytes))) {
            // Only process the first sheet (Agenda)
            if (workbook.getNumberOfSheets() > 0) {
                Sheet sheet = workbook.getSheetAt(0);

                // Handle dynamic speaker rows if needed
                if (variableMappings != null && !variableMappings.isEmpty()) {
                    variableMappings = handleDynamicSpeakerRows(sheet, agendaData, variableMappings);
                    fillByCoordinates(sheet, agendaData, variableMappings);
                } else {
                    // Fallback to label-based searching only when no coordinate mappings available
                    processSheetByLabels(sheet, agendaData);
                }
            }

            // Write to output
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            workbook.write(outputStream);
            return outputStream.toByteArray();
        }
    }

    /**
     * Handle dynamic speaker rows - if we have more speakers than template
     * positions,
     * insert additional rows by copying the last speaker row.
     */
    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> handleDynamicSpeakerRows(Sheet sheet, Map<String, Object> agendaData,
            List<Map<String, Object>> variableMappings) {

        // Find max speaker index in template
        int maxTemplateSpeaker = 0;
        int lastSpeakerRow = -1;

        for (Map<String, Object> mapping : variableMappings) {
            String role = (String) mapping.get("role");
            if (role != null && role.toUpperCase().startsWith("SPEAKER_") && !role.contains("TITLE")
                    && !role.contains("PROJECT")) {
                try {
                    int idx = Integer.parseInt(role.replaceAll("\\D", ""));
                    if (idx > maxTemplateSpeaker) {
                        maxTemplateSpeaker = idx;
                        Map<String, Object> valuePos = (Map<String, Object>) mapping.get("value_position");
                        if (valuePos != null) {
                            lastSpeakerRow = ((Number) valuePos.get("row")).intValue() - 1;
                        }
                    }
                } catch (NumberFormatException ignored) {
                }
            }
        }

        // Find actual speaker count from data
        List<Map<String, String>> speakers = (List<Map<String, String>>) agendaData.get("SPEAKERS");
        int actualSpeakerCount = speakers != null ? speakers.size() : 0;

        // If we have more speakers than template positions, insert rows
        if (actualSpeakerCount > maxTemplateSpeaker && lastSpeakerRow >= 0 && maxTemplateSpeaker > 0) {
            int rowsToInsert = actualSpeakerCount - maxTemplateSpeaker;
            int insertAfterRow = lastSpeakerRow;

            try {
                // Shift rows down to make space (this handles merged regions automatically in
                // newer POI)
                sheet.shiftRows(insertAfterRow + 1, sheet.getLastRowNum(), rowsToInsert);

                // Copy the last speaker row for each additional speaker
                Row sourceRow = sheet.getRow(insertAfterRow);
                if (sourceRow != null) {
                    for (int i = 0; i < rowsToInsert; i++) {
                        int newRowIdx = insertAfterRow + 1 + i;
                        Row newRow = sheet.createRow(newRowIdx);
                        copyRow(sourceRow, newRow);
                    }
                }
            } catch (Exception e) {
                // Log error but continue
            }

            // Create new mappings for additional speakers
            List<Map<String, Object>> newMappings = new ArrayList<>(variableMappings);

            // Find template mapping for last speaker to use as reference
            Map<String, Object> lastSpeakerMapping = null;
            Map<String, Object> lastSpeakerTitleMapping = null;
            Map<String, Object> lastSpeakerProjectMapping = null;

            for (Map<String, Object> mapping : variableMappings) {
                String role = (String) mapping.get("role");
                if (role != null) {
                    if (role.equals("SPEAKER_" + maxTemplateSpeaker)) {
                        lastSpeakerMapping = mapping;
                    } else if (role.equals("SPEAKER_" + maxTemplateSpeaker + "_TITLE")) {
                        lastSpeakerTitleMapping = mapping;
                    } else if (role.equals("SPEAKER_" + maxTemplateSpeaker + "_PROJECT")) {
                        lastSpeakerProjectMapping = mapping;
                    }
                }
            }

            // Add mappings for new speakers
            for (int i = 1; i <= rowsToInsert; i++) {
                int speakerIdx = maxTemplateSpeaker + i;
                int rowOffset = i;

                if (lastSpeakerMapping != null) {
                    newMappings.add(createOffsetMapping("SPEAKER_" + speakerIdx, lastSpeakerMapping, rowOffset));
                }
                if (lastSpeakerTitleMapping != null) {
                    newMappings.add(createOffsetMapping("SPEAKER_" + speakerIdx + "_TITLE", lastSpeakerTitleMapping,
                            rowOffset));
                }
                if (lastSpeakerProjectMapping != null) {
                    newMappings.add(createOffsetMapping("SPEAKER_" + speakerIdx + "_PROJECT", lastSpeakerProjectMapping,
                            rowOffset));
                }

                // Add data for additional speakers
                if (speakerIdx <= actualSpeakerCount) {
                    Map<String, String> speakerData = speakers.get(speakerIdx - 1);
                    agendaData.put("SPEAKER_" + speakerIdx + "_NAME", speakerData.get("name"));
                    agendaData.put("SPEECH_TITLE_" + speakerIdx, speakerData.get("title"));
                    agendaData.put("SPEECH_PROJECT_" + speakerIdx, speakerData.get("project"));
                }
            }

            // Update row positions for all mappings after the inserted rows
            for (Map<String, Object> mapping : newMappings) {
                Map<String, Object> valuePos = (Map<String, Object>) mapping.get("value_position");
                if (valuePos != null) {
                    int row = ((Number) valuePos.get("row")).intValue();
                    if (row > insertAfterRow + 1) { // 1-indexed, so +1
                        valuePos.put("row", row + rowsToInsert);
                    }
                }
            }

            return newMappings;
        }

        return variableMappings;
    }

    private Map<String, Object> createOffsetMapping(String role, Map<String, Object> sourceMapping, int rowOffset) {
        Map<String, Object> newMapping = new HashMap<>();
        newMapping.put("role", role);

        @SuppressWarnings("unchecked")
        Map<String, Object> sourcePos = (Map<String, Object>) sourceMapping.get("value_position");
        if (sourcePos != null) {
            Map<String, Object> newPos = new HashMap<>();
            newPos.put("row", ((Number) sourcePos.get("row")).intValue() + rowOffset);
            newPos.put("col", sourcePos.get("col"));
            newMapping.put("value_position", newPos);
        }

        return newMapping;
    }

    private void copyRow(Row sourceRow, Row targetRow) {
        targetRow.setHeight(sourceRow.getHeight());
        for (int i = 0; i < sourceRow.getLastCellNum(); i++) {
            Cell sourceCell = sourceRow.getCell(i);
            Cell targetCell = targetRow.createCell(i);
            if (sourceCell != null) {
                targetCell.setCellStyle(sourceCell.getCellStyle());
                switch (sourceCell.getCellType()) {
                    case STRING:
                        targetCell.setCellValue(sourceCell.getStringCellValue());
                        break;
                    case NUMERIC:
                        targetCell.setCellValue(sourceCell.getNumericCellValue());
                        break;
                    case BOOLEAN:
                        targetCell.setCellValue(sourceCell.getBooleanCellValue());
                        break;
                    case FORMULA:
                        targetCell.setCellFormula(sourceCell.getCellFormula());
                        break;
                    default:
                        break;
                }
            }
        }
    }

    @SuppressWarnings("unchecked")
    private void fillByCoordinates(Sheet sheet, Map<String, Object> agendaData,
            List<Map<String, Object>> variableMappings) {

        for (Map<String, Object> mapping : variableMappings) {
            String role = (String) mapping.get("role");
            Map<String, Object> valuePos = (Map<String, Object>) mapping.get("value_position");

            if (role == null || valuePos == null) {
                continue;
            }

            // Get row and col (1-indexed from LLM, convert to 0-indexed for POI)
            int targetRow = ((Number) valuePos.get("row")).intValue() - 1;
            int targetCol = ((Number) valuePos.get("col")).intValue() - 1;

            if (targetRow < 0 || targetCol < 0) {
                continue;
            }

            // Map role name to data key
            String dataKey = mapRoleToDataKey(role);
            Object value = agendaData.get(dataKey);

            if (value instanceof String && !((String) value).isEmpty()) {
                // Check if target cell is part of a merged region
                int actualRow = targetRow;
                int actualCol = targetCol;
                boolean isMerged = false;

                for (int i = 0; i < sheet.getNumMergedRegions(); i++) {
                    org.apache.poi.ss.util.CellRangeAddress region = sheet.getMergedRegion(i);
                    if (region.isInRange(targetRow, targetCol)) {
                        // Use the top-left cell of the merged region
                        actualRow = region.getFirstRow();
                        actualCol = region.getFirstColumn();
                        isMerged = true;
                        break;
                    }
                }

                Row sheetRow = sheet.getRow(actualRow);
                if (sheetRow == null) {
                    sheetRow = sheet.createRow(actualRow);
                }

                // Unhide the row if it was hidden (for dynamic speaker rows)
                if (sheetRow.getZeroHeight()) {
                    sheetRow.setZeroHeight(false);
                }

                Cell existingCell = sheetRow.getCell(actualCol);
                org.apache.poi.ss.usermodel.CellStyle existingStyle = null;

                if (existingCell != null) {
                    existingStyle = existingCell.getCellStyle();
                }

                // Remove the cell and create a fresh one
                if (existingCell != null) {
                    sheetRow.removeCell(existingCell);
                }

                // Create a new STRING cell
                Cell cell = sheetRow.createCell(actualCol, org.apache.poi.ss.usermodel.CellType.STRING);
                cell.setCellValue((String) value);

                // Re-apply style if it was set
                if (existingStyle != null) {
                    cell.setCellStyle(existingStyle);
                }
            }
        }
    }

    private String getCellValueAsString(Cell cell) {
        if (cell == null)
            return "";
        switch (cell.getCellType()) {
            case STRING:
                return cell.getStringCellValue();
            case NUMERIC:
                return String.valueOf(cell.getNumericCellValue());
            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());
            default:
                return "";
        }
    }

    private String mapRoleToDataKey(String role) {
        // Map LLM role names to our data keys
        Map<String, String> roleMapping = new HashMap<>();
        roleMapping.put("TME", "TME_NAME");
        roleMapping.put("TIMER", "TIMER_NAME");
        roleMapping.put("AH_COUNTER", "AH_COUNTER_NAME");
        roleMapping.put("VOTE_COUNTER", "VOTE_COUNTER_NAME");
        roleMapping.put("GRAMMARIAN", "GRAMMARIAN_NAME");
        roleMapping.put("GE", "GE_NAME");
        roleMapping.put("LE", "LE_NAME");
        roleMapping.put("PHOTOGRAPHER", "PHOTOGRAPHER_NAME");
        roleMapping.put("SAA", "SAA_NAME");
        roleMapping.put("SESSION_MASTER", "SESSION_MASTER_NAME");
        roleMapping.put("VARIETY_SESSION_MASTER", "VARIETY_SESSION_MASTER_NAME");
        roleMapping.put("VARIETY_MASTER", "VARIETY_SESSION_MASTER_NAME");
        roleMapping.put("TABLE_TOPICS_MASTER", "TABLE_TOPICS_MASTER_NAME");
        roleMapping.put("PRESIDENT", "PRESIDENT_NAME");
        // Speakers
        roleMapping.put("SPEAKER_1", "SPEAKER_1_NAME");
        roleMapping.put("SPEAKER_2", "SPEAKER_2_NAME");
        roleMapping.put("SPEAKER_3", "SPEAKER_3_NAME");
        roleMapping.put("SPEAKER_4", "SPEAKER_4_NAME");
        // Speaker titles/projects
        roleMapping.put("SPEAKER_1_TITLE", "SPEECH_TITLE_1");
        roleMapping.put("SPEAKER_2_TITLE", "SPEECH_TITLE_2");
        roleMapping.put("SPEAKER_3_TITLE", "SPEECH_TITLE_3");
        roleMapping.put("SPEAKER_1_PROJECT", "SPEECH_PROJECT_1");
        roleMapping.put("SPEAKER_2_PROJECT", "SPEECH_PROJECT_2");
        roleMapping.put("SPEAKER_3_PROJECT", "SPEECH_PROJECT_3");
        // Evaluators
        roleMapping.put("EVALUATOR_1", "EVALUATOR_1_NAME");
        roleMapping.put("EVALUATOR_2", "EVALUATOR_2_NAME");
        roleMapping.put("EVALUATOR_3", "EVALUATOR_3_NAME");
        roleMapping.put("INDIVIDUAL_EVALUATOR_1", "INDIVIDUAL_EVALUATOR_1_NAME");
        roleMapping.put("INDIVIDUAL_EVALUATOR_2", "INDIVIDUAL_EVALUATOR_2_NAME");
        roleMapping.put("INDIVIDUAL_EVALUATOR_3", "INDIVIDUAL_EVALUATOR_3_NAME");
        // Meeting info
        roleMapping.put("MEETING_DATE", "MEETING_DATE");
        roleMapping.put("MEETING_INFO", "MEETING_DATE");
        roleMapping.put("THEME", "THEME");
        roleMapping.put("MEETING_NUMBER", "MEETING_NUMBER");

        return roleMapping.getOrDefault(role.toUpperCase(), role + "_NAME");
    }

    private void processSheetByLabels(Sheet sheet, Map<String, Object> agendaData) {
        // Define role label mappings (what to search for -> data key)
        Map<String, String> roleLabelMappings = new LinkedHashMap<>();
        roleLabelMappings.put("TME", "TME_NAME");
        roleLabelMappings.put("Toastmaster of the Evening", "TME_NAME");
        roleLabelMappings.put("Timer", "TIMER_NAME");
        roleLabelMappings.put("計時", "TIMER_NAME");
        roleLabelMappings.put("Ah Counter", "AH_COUNTER_NAME");
        roleLabelMappings.put("Ah-Counter", "AH_COUNTER_NAME");
        roleLabelMappings.put("贅語", "AH_COUNTER_NAME");
        roleLabelMappings.put("Vote Counter", "VOTE_COUNTER_NAME");
        roleLabelMappings.put("計票", "VOTE_COUNTER_NAME");
        roleLabelMappings.put("Grammarian", "GRAMMARIAN_NAME");
        roleLabelMappings.put("文法", "GRAMMARIAN_NAME");
        roleLabelMappings.put("General Evaluator", "GE_NAME");
        roleLabelMappings.put("總講評", "GE_NAME");
        roleLabelMappings.put("GE", "GE_NAME");
        roleLabelMappings.put("Language Evaluator", "LE_NAME");
        roleLabelMappings.put("語言講評", "LE_NAME");
        roleLabelMappings.put("LE", "LE_NAME");
        roleLabelMappings.put("Session Master", "SESSION_MASTER_NAME");
        roleLabelMappings.put("Variety Session", "VARIETY_SESSION_MASTER_NAME");
        roleLabelMappings.put("Table Topics Master", "TABLE_TOPICS_MASTER_NAME");
        roleLabelMappings.put("即席問答", "TABLE_TOPICS_MASTER_NAME");
        roleLabelMappings.put("Photographer", "PHOTOGRAPHER_NAME");
        roleLabelMappings.put("攝影", "PHOTOGRAPHER_NAME");
        roleLabelMappings.put("SAA", "SAA_NAME");
        roleLabelMappings.put("事務長", "SAA_NAME");
        roleLabelMappings.put("President", "PRESIDENT_NAME");
        roleLabelMappings.put("會長", "PRESIDENT_NAME");

        // Create a copy of the entries to avoid ConcurrentModificationException
        List<Map.Entry<String, String>> mappingEntries = new ArrayList<>(roleLabelMappings.entrySet());

        // Scan all cells and find labels, then fill adjacent cells
        // Use index-based iteration to avoid ConcurrentModificationException
        int lastRowNum = sheet.getLastRowNum();
        for (int rowIdx = 0; rowIdx <= lastRowNum; rowIdx++) {
            Row row = sheet.getRow(rowIdx);
            if (row == null)
                continue;

            short lastCellNum = row.getLastCellNum();
            for (int colIdx = 0; colIdx < lastCellNum; colIdx++) {
                Cell cell = row.getCell(colIdx);
                if (cell == null)
                    continue;

                if (cell.getCellType() == CellType.STRING) {
                    String cellValue = cell.getStringCellValue().trim();

                    // Check for role labels
                    for (Map.Entry<String, String> mapping : mappingEntries) {
                        if (cellValue.toLowerCase().contains(mapping.getKey().toLowerCase())) {
                            String dataKey = mapping.getValue();
                            Object value = agendaData.get(dataKey);
                            if (value instanceof String && !((String) value).isEmpty()) {
                                // Try to fill the cell to the right
                                Cell rightCell = row.getCell(cell.getColumnIndex() + 1);
                                if (rightCell == null) {
                                    rightCell = row.createCell(cell.getColumnIndex() + 1);
                                }
                                if (rightCell.getCellType() == CellType.BLANK ||
                                        (rightCell.getCellType() == CellType.STRING &&
                                                rightCell.getStringCellValue().trim().isEmpty())) {
                                    rightCell.setCellValue((String) value);
                                }
                            }
                            break; // Found a match, don't check other mappings
                        }
                    }

                    // Handle Speaker 1, 2, 3 pattern
                    if (cellValue.matches("(?i).*speaker\\s*[1-3].*") ||
                            cellValue.matches("(?i).*講者\\s*[1-3].*")) {
                        for (int i = 1; i <= 3; i++) {
                            if (cellValue.contains(String.valueOf(i))) {
                                String speakerName = (String) agendaData.get("SPEAKER_" + i + "_NAME");
                                if (speakerName != null && !speakerName.isEmpty()) {
                                    Cell rightCell = row.getCell(cell.getColumnIndex() + 1);
                                    if (rightCell == null) {
                                        rightCell = row.createCell(cell.getColumnIndex() + 1);
                                    }
                                    if (rightCell.getCellType() == CellType.BLANK ||
                                            (rightCell.getCellType() == CellType.STRING &&
                                                    rightCell.getStringCellValue().trim().isEmpty())) {
                                        rightCell.setCellValue(speakerName);
                                    }
                                }
                                break;
                            }
                        }
                    }

                    // Handle Evaluator 1, 2, 3 pattern
                    if (cellValue.matches("(?i).*evaluator\\s*[1-3].*") ||
                            cellValue.matches("(?i).*講評.*[1-3].*")) {
                        for (int i = 1; i <= 3; i++) {
                            if (cellValue.contains(String.valueOf(i))) {
                                String evalName = (String) agendaData.get("EVALUATOR_" + i + "_NAME");
                                if (evalName != null && !evalName.isEmpty()) {
                                    Cell rightCell = row.getCell(cell.getColumnIndex() + 1);
                                    if (rightCell == null) {
                                        rightCell = row.createCell(cell.getColumnIndex() + 1);
                                    }
                                    if (rightCell.getCellType() == CellType.BLANK ||
                                            (rightCell.getCellType() == CellType.STRING &&
                                                    rightCell.getStringCellValue().trim().isEmpty())) {
                                        rightCell.setCellValue(evalName);
                                    }
                                }
                                break;
                            }
                        }
                    }

                    // Also replace {{VARIABLE}} placeholders if any exist
                    String newValue = replacePlaceholders(cellValue, agendaData);
                    if (!cellValue.equals(newValue)) {
                        cell.setCellValue(newValue);
                    }
                }
            }
        }
    }

    private String replacePlaceholders(String text, Map<String, Object> data) {
        if (text == null || !text.contains("{{")) {
            return text;
        }

        String result = text;

        // Replace {{VARIABLE}} patterns
        for (Map.Entry<String, Object> entry : data.entrySet()) {
            String placeholder = "{{" + entry.getKey() + "}}";
            if (result.contains(placeholder) && entry.getValue() instanceof String) {
                result = result.replace(placeholder, (String) entry.getValue());
            }
        }

        // Remove any remaining unreplaced placeholders
        result = result.replaceAll("\\{\\{[^}]+}}", "");

        return result;
    }
}
