package com.toastlabplus.controller;

import com.toastlabplus.entity.Club;
import com.toastlabplus.entity.Meeting;
import com.toastlabplus.entity.Member;
import com.toastlabplus.entity.MeetingSchedule;
import com.toastlabplus.entity.RoleSlot;
import com.toastlabplus.entity.AgendaTemplate;
import com.toastlabplus.repository.ClubAdminRepository;
import com.toastlabplus.repository.ClubRepository;
import com.toastlabplus.repository.MeetingRepository;
import com.toastlabplus.repository.MeetingScheduleRepository;
import com.toastlabplus.repository.MemberRepository;
import com.toastlabplus.repository.RoleSlotRepository;
import com.toastlabplus.repository.AgendaTemplateRepository;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/clubs/{clubId}/meeting-schedules")
public class MeetingScheduleController {

    private final MeetingScheduleRepository meetingScheduleRepository;
    private final MeetingRepository meetingRepository;
    private final RoleSlotRepository roleSlotRepository;
    private final ClubRepository clubRepository;
    private final ClubAdminRepository clubAdminRepository;
    private final MemberRepository memberRepository;
    private final AgendaTemplateRepository agendaTemplateRepository;

    public MeetingScheduleController(MeetingScheduleRepository meetingScheduleRepository,
            MeetingRepository meetingRepository,
            RoleSlotRepository roleSlotRepository,
            ClubRepository clubRepository,
            ClubAdminRepository clubAdminRepository,
            MemberRepository memberRepository,
            AgendaTemplateRepository agendaTemplateRepository) {
        this.meetingScheduleRepository = meetingScheduleRepository;
        this.meetingRepository = meetingRepository;
        this.roleSlotRepository = roleSlotRepository;
        this.clubRepository = clubRepository;
        this.clubAdminRepository = clubAdminRepository;
        this.memberRepository = memberRepository;
        this.agendaTemplateRepository = agendaTemplateRepository;
    }

    /**
     * Get all meeting schedules for a club.
     */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getSchedules(@PathVariable Long clubId) {
        List<MeetingSchedule> schedules = meetingScheduleRepository.findByClubIdAndIsActiveTrue(clubId);

        List<Map<String, Object>> result = new ArrayList<>();
        for (MeetingSchedule schedule : schedules) {
            result.add(scheduleToMap(schedule));
        }

        return ResponseEntity.ok(result);
    }

    /**
     * Create a new meeting schedule.
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> createSchedule(
            @PathVariable Long clubId,
            @Valid @RequestBody CreateScheduleRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        // Check admin permission
        if (!isClubAdmin(currentMember, clubId)) {
            return ResponseEntity.status(403).body(Map.of("error", "You are not an admin of this club"));
        }

        Club club = clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        MeetingSchedule schedule = new MeetingSchedule();
        schedule.setClub(club);
        schedule.setName(request.name());
        schedule.setFrequency(request.frequency());
        schedule.setDayOfWeek(request.dayOfWeek());
        schedule.setWeekOfMonth(request.weekOfMonth());
        schedule.setStartTime(request.startTime());
        schedule.setEndTime(request.endTime());
        schedule.setDefaultSpeakerCount(request.defaultSpeakerCount() != null ? request.defaultSpeakerCount() : 3);
        schedule.setDefaultLocation(request.defaultLocation());
        schedule.setAutoGenerateMonths(request.autoGenerateMonths() != null ? request.autoGenerateMonths() : 3);
        schedule.setCreatedBy(currentMember);

        MeetingSchedule saved = meetingScheduleRepository.save(schedule);

        return ResponseEntity.ok(Map.of(
                "message", "Schedule created successfully",
                "scheduleId", saved.getId()));
    }

    /**
     * Update a meeting schedule.
     */
    @PutMapping("/{scheduleId}")
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> updateSchedule(
            @PathVariable Long clubId,
            @PathVariable Long scheduleId,
            @Valid @RequestBody CreateScheduleRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        if (!isClubAdmin(currentMember, clubId)) {
            return ResponseEntity.status(403).body(Map.of("error", "You are not an admin of this club"));
        }

        MeetingSchedule schedule = meetingScheduleRepository.findByIdAndClubId(scheduleId, clubId).orElse(null);
        if (schedule == null) {
            return ResponseEntity.notFound().build();
        }

        schedule.setName(request.name());
        schedule.setFrequency(request.frequency());
        schedule.setDayOfWeek(request.dayOfWeek());
        schedule.setWeekOfMonth(request.weekOfMonth());
        schedule.setStartTime(request.startTime());
        schedule.setEndTime(request.endTime());
        schedule.setDefaultSpeakerCount(request.defaultSpeakerCount());
        schedule.setDefaultLocation(request.defaultLocation());
        schedule.setAutoGenerateMonths(request.autoGenerateMonths());
        schedule.setUpdatedAt(LocalDateTime.now());

        meetingScheduleRepository.save(schedule);

        return ResponseEntity.ok(Map.of("message", "Schedule updated"));
    }

    /**
     * Delete (deactivate) a meeting schedule.
     */
    @DeleteMapping("/{scheduleId}")
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> deleteSchedule(
            @PathVariable Long clubId,
            @PathVariable Long scheduleId,
            @AuthenticationPrincipal UserDetails userDetails) {

        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        if (!isClubAdmin(currentMember, clubId)) {
            return ResponseEntity.status(403).body(Map.of("error", "You are not an admin of this club"));
        }

        MeetingSchedule schedule = meetingScheduleRepository.findByIdAndClubId(scheduleId, clubId).orElse(null);
        if (schedule == null) {
            return ResponseEntity.notFound().build();
        }

        schedule.setIsActive(false);
        schedule.setUpdatedAt(LocalDateTime.now());
        meetingScheduleRepository.save(schedule);

        return ResponseEntity.ok(Map.of("message", "Schedule deleted"));
    }

    /**
     * Generate meetings for a schedule.
     */
    @PostMapping("/{scheduleId}/generate")
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> generateMeetings(
            @PathVariable Long clubId,
            @PathVariable Long scheduleId,
            @RequestParam(required = false) Integer months,
            @AuthenticationPrincipal UserDetails userDetails) {

        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        if (!isClubAdmin(currentMember, clubId)) {
            return ResponseEntity.status(403).body(Map.of("error", "You are not an admin of this club"));
        }

        MeetingSchedule schedule = meetingScheduleRepository.findByIdAndClubId(scheduleId, clubId).orElse(null);
        if (schedule == null) {
            return ResponseEntity.notFound().build();
        }

        // Use provided months or fall back to schedule's default
        int generateMonths = (months != null && months > 0) ? months : schedule.getAutoGenerateMonths();
        List<LocalDate> dates = calculateMeetingDates(schedule, generateMonths);
        int created = 0;

        for (LocalDate date : dates) {
            // Skip if meeting already exists for this date
            if (meetingRepository.existsByClubIdAndMeetingDate(clubId, date)) {
                continue;
            }

            // Get next meeting number
            Integer maxNumber = meetingRepository.findMaxMeetingNumberByClubId(clubId).orElse(0);

            Meeting meeting = new Meeting();
            meeting.setClub(schedule.getClub());
            meeting.setMeetingNumber(maxNumber + 1);
            meeting.setMeetingDate(date);
            meeting.setStartTime(schedule.getStartTime());
            meeting.setEndTime(schedule.getEndTime());
            meeting.setLocation(schedule.getDefaultLocation());
            meeting.setSpeakerCount(schedule.getDefaultSpeakerCount());
            meeting.setTemplateId(schedule.getTemplateId());
            meeting.setSchedule(schedule);
            meeting.setStatus(Meeting.STATUS_DRAFT);
            meeting.setCreatedBy(currentMember);

            Meeting saved = meetingRepository.save(meeting);

            // Create default role slots
            createDefaultRoleSlots(saved);

            created++;
        }

        return ResponseEntity.ok(Map.of(
                "message", "Generated " + created + " meetings",
                "count", created));
    }

    // ==================== Helper Methods ====================

    private boolean isClubAdmin(Member member, Long clubId) {
        return "PLATFORM_ADMIN".equals(member.getRole()) ||
                clubAdminRepository.existsByMemberIdAndClubId(member.getId(), clubId);
    }

    private Map<String, Object> scheduleToMap(MeetingSchedule schedule) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", schedule.getId());
        map.put("name", schedule.getName());
        map.put("frequency", schedule.getFrequency());
        map.put("dayOfWeek", schedule.getDayOfWeek());
        map.put("weekOfMonth", schedule.getWeekOfMonth());
        map.put("startTime", schedule.getStartTime());
        map.put("endTime", schedule.getEndTime());
        map.put("defaultSpeakerCount", schedule.getDefaultSpeakerCount());
        map.put("defaultLocation", schedule.getDefaultLocation());
        map.put("autoGenerateMonths", schedule.getAutoGenerateMonths());
        return map;
    }

    private List<LocalDate> calculateMeetingDates(MeetingSchedule schedule, int months) {
        List<LocalDate> dates = new ArrayList<>();
        LocalDate today = LocalDate.now();
        LocalDate endDate = today.plusMonths(months);

        if (MeetingSchedule.FREQ_MONTHLY.equals(schedule.getFrequency())) {
            int[] weeks = schedule.getWeekOfMonth();
            DayOfWeek dayOfWeek = DayOfWeek.of(schedule.getDayOfWeek());

            LocalDate current = today.withDayOfMonth(1);
            while (current.isBefore(endDate)) {
                for (int week : weeks) {
                    LocalDate date = current.with(TemporalAdjusters.dayOfWeekInMonth(week, dayOfWeek));
                    if (!date.isBefore(today) && date.isBefore(endDate)) {
                        dates.add(date);
                    }
                }
                current = current.plusMonths(1);
            }
        }
        // Add WEEKLY and BIWEEKLY logic as needed

        return dates;
    }

    @SuppressWarnings("unchecked")
    private void createDefaultRoleSlots(Meeting meeting) {
        // Try to get roles from template's variable_mappings
        Set<String> templateRoles = new HashSet<>();
        Map<String, Integer> roleMaxIndex = new HashMap<>();

        if (meeting.getTemplateId() != null) {
            AgendaTemplate template = agendaTemplateRepository.findById(meeting.getTemplateId()).orElse(null);
            if (template != null && template.getParsedStructure() != null) {
                try {
                    com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                    Map<String, Object> parsed = mapper.readValue(template.getParsedStructure(), Map.class);
                    List<Map<String, Object>> variableMappings = (List<Map<String, Object>>) parsed
                            .get("variable_mappings");

                    if (variableMappings != null) {
                        for (Map<String, Object> mapping : variableMappings) {
                            String role = (String) mapping.get("role");
                            if (role != null) {
                                // Parse role name to get base role and index
                                // e.g., SPEAKER_1 -> SPEAKER, 1
                                // e.g., TME -> TME, 1
                                String baseRole = extractBaseRole(role);
                                int index = extractRoleIndex(role);

                                if (baseRole != null) {
                                    templateRoles.add(baseRole);
                                    roleMaxIndex.merge(baseRole, index, Math::max);
                                }
                            }
                        }
                    }
                } catch (Exception e) {
                    System.err.println("Failed to parse template roles: " + e.getMessage());
                }
            }
        }

        // Fallback to default roles if no template or parsing failed
        if (templateRoles.isEmpty()) {
            String[] staticRoles = { RoleSlot.TME, RoleSlot.TIMER, RoleSlot.AH_COUNTER,
                    RoleSlot.VOTE_COUNTER, RoleSlot.GRAMMARIAN, RoleSlot.GE, RoleSlot.LE,
                    RoleSlot.TT_MASTER, RoleSlot.SESSION_MASTER, RoleSlot.PHOTOGRAPHER };

            for (String role : staticRoles) {
                roleSlotRepository.save(new RoleSlot(meeting, role, 1));
            }

            int speakerCount = meeting.getSpeakerCount() != null ? meeting.getSpeakerCount() : 3;
            for (int i = 1; i <= speakerCount; i++) {
                roleSlotRepository.save(new RoleSlot(meeting, RoleSlot.SPEAKER, i));
                roleSlotRepository.save(new RoleSlot(meeting, RoleSlot.EVALUATOR, i));
            }
        } else {
            // Create role slots based on template
            for (String baseRole : templateRoles) {
                int maxIndex = roleMaxIndex.getOrDefault(baseRole, 1);

                // For SPEAKER and EVALUATOR, create multiple slots
                if (RoleSlot.SPEAKER.equals(baseRole) || RoleSlot.EVALUATOR.equals(baseRole)) {
                    for (int i = 1; i <= maxIndex; i++) {
                        roleSlotRepository.save(new RoleSlot(meeting, baseRole, i));
                    }
                } else {
                    // For other roles, create single slot
                    roleSlotRepository.save(new RoleSlot(meeting, baseRole, 1));
                }
            }
        }
    }

    /**
     * Extract base role name from role string (e.g., SPEAKER_1 -> SPEAKER)
     */
    private String extractBaseRole(String role) {
        if (role == null)
            return null;
        role = role.toUpperCase();

        // Handle title/project suffixes - skip these
        if (role.endsWith("_TITLE") || role.endsWith("_PROJECT") || role.contains("MEETING_INFO")
                || role.contains("THEME") || role.contains("MEETING_DATE")) {
            return null;
        }

        // Handle indexed roles - remove the index first
        String baseRole = role;
        if (role.matches(".*_\\d+$")) {
            baseRole = role.replaceAll("_\\d+$", "");
        }

        // Map common role names
        switch (baseRole) {
            case "TME":
            case "TOASTMASTER":
                return RoleSlot.TME;
            case "TIMER":
                return RoleSlot.TIMER;
            case "AH_COUNTER":
            case "AHCOUNTER":
                return RoleSlot.AH_COUNTER;
            case "VOTE_COUNTER":
            case "VOTECOUNTER":
                return RoleSlot.VOTE_COUNTER;
            case "GE":
            case "GENERAL_EVALUATOR":
                return RoleSlot.GE;
            case "LE":
            case "LANGUAGE_EVALUATOR":
                return RoleSlot.LE;
            case "TT_MASTER":
            case "TABLE_TOPICS_MASTER":
                return RoleSlot.TT_MASTER;
            case "SESSION_MASTER":
            case "VARIETY_MASTER":
                return RoleSlot.SESSION_MASTER;
            case "PHOTOGRAPHER":
                return RoleSlot.PHOTOGRAPHER;
            case "GRAMMARIAN":
                return RoleSlot.GRAMMARIAN;
            case "SPEAKER":
                return RoleSlot.SPEAKER;
            case "EVALUATOR":
            case "INDIVIDUAL_EVALUATOR":
                return RoleSlot.EVALUATOR;
            default:
                // Skip unknown roles
                return null;
        }
    }

    /**
     * Extract index from role string (e.g., SPEAKER_1 -> 1)
     */
    private int extractRoleIndex(String role) {
        if (role == null)
            return 1;
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("_(\\d+)$");
        java.util.regex.Matcher matcher = pattern.matcher(role.toUpperCase());
        if (matcher.find()) {
            return Integer.parseInt(matcher.group(1));
        }
        return 1;
    }

    // ==================== Request DTOs ====================

    public record CreateScheduleRequest(
            String name,
            String frequency,
            Integer dayOfWeek,
            int[] weekOfMonth,
            LocalTime startTime,
            LocalTime endTime,
            Integer defaultSpeakerCount,
            String defaultLocation,
            Integer autoGenerateMonths) {
    }
}
