package com.toastlabplus.mcp;

import com.toastlabplus.entity.Club;
import com.toastlabplus.entity.Meeting;
import com.toastlabplus.entity.Member;
import com.toastlabplus.entity.RoleSlot;
import com.toastlabplus.repository.ClubMembershipRepository;
import com.toastlabplus.repository.ClubRepository;
import com.toastlabplus.repository.MeetingRepository;
import com.toastlabplus.repository.MemberRepository;
import com.toastlabplus.repository.RoleSlotRepository;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * MCP Tool Service - Exposes MCP tools for AI chat integration.
 * Each method annotated with @Tool will be registered as an MCP tool.
 */
@Component
public class McpToolService {

    private final ClubRepository clubRepository;
    private final MeetingRepository meetingRepository;
    private final MemberRepository memberRepository;
    private final RoleSlotRepository roleSlotRepository;
    private final ClubMembershipRepository clubMembershipRepository;

    public McpToolService(ClubRepository clubRepository,
            MeetingRepository meetingRepository,
            MemberRepository memberRepository,
            RoleSlotRepository roleSlotRepository,
            ClubMembershipRepository clubMembershipRepository) {
        this.clubRepository = clubRepository;
        this.meetingRepository = meetingRepository;
        this.memberRepository = memberRepository;
        this.roleSlotRepository = roleSlotRepository;
        this.clubMembershipRepository = clubMembershipRepository;
    }

    /**
     * Get all active Toastmasters clubs.
     */
    @Tool(name = "get_clubs", description = "[Get Clubs] List all available Toastmasters clubs, including name, location, and meeting time.")
    public List<Map<String, Object>> getClubs() {
        List<Club> clubs = clubRepository.findByIsActiveTrue();
        List<Map<String, Object>> result = new ArrayList<>();

        for (Club club : clubs) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", club.getId());
            map.put("name", club.getName());
            map.put("description", club.getDescription());
            map.put("location", club.getLocation());
            map.put("meetingDay", club.getMeetingDay());
            map.put("meetingTime", club.getMeetingTime() != null ? club.getMeetingTime().toString() : null);
            result.add(map);
        }

        return result;
    }

    /**
     * Get upcoming meetings for a club or all clubs.
     */
    @Tool(name = "get_meetings", description = "[Get Meetings] Retrieve upcoming meetings using a date range, including date, time, location, theme, and role availability.")
    public List<Map<String, Object>> getMeetings(
            @ToolParam(description = "Club ID. If not specified, returns meetings for all clubs.", required = false) Long clubId,
            @ToolParam(description = "Number of days to look ahead. Default is 30 days.", required = false) Integer daysAhead) {

        LocalDate startDate = LocalDate.now();
        LocalDate endDate = startDate.plusDays(daysAhead != null ? daysAhead : 30);

        List<Meeting> meetings;
        if (clubId != null) {
            meetings = meetingRepository.findByClubIdAndMeetingDateBetweenOrderByMeetingDateAsc(
                    clubId, startDate, endDate);
        } else {
            meetings = meetingRepository.findByMeetingDateBetweenOrderByMeetingDateAsc(
                    startDate, endDate);
        }

        List<Map<String, Object>> result = new ArrayList<>();

        for (Meeting meeting : meetings) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", meeting.getId());
            map.put("title", meeting.getTitle());
            map.put("theme", meeting.getTheme());
            map.put("meetingDate", meeting.getMeetingDate().toString());
            map.put("startTime", meeting.getStartTime() != null ? meeting.getStartTime().toString() : null);
            map.put("location", meeting.getLocation());
            map.put("status", meeting.getStatus());
            map.put("clubId", meeting.getClub().getId());
            map.put("clubName", meeting.getClub().getName());

            // Get role slot summary
            List<RoleSlot> slots = roleSlotRepository.findByMeetingId(meeting.getId());
            long totalSlots = slots.size();
            long filledSlots = slots.stream().filter(RoleSlot::isAssigned).count();
            map.put("totalRoleSlots", totalSlots);
            map.put("filledRoleSlots", filledSlots);
            map.put("availableRoleSlots", totalSlots - filledSlots);

            result.add(map);
        }

        return result;
    }

    /**
     * Get role slots for a specific meeting.
     */
    @Tool(name = "get_role_slots", description = "[Get Role Slots] Retrieve role slots availability for a specific meeting, showing assigned and vacant roles.")
    public List<Map<String, Object>> getRoleSlots(
            @ToolParam(description = "Meeting ID", required = true) Long meetingId) {

        List<RoleSlot> slots = roleSlotRepository.findByMeetingIdWithMember(meetingId);
        List<Map<String, Object>> result = new ArrayList<>();

        for (RoleSlot slot : slots) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", slot.getId());
            map.put("roleName", slot.getRoleName());
            map.put("displayName", slot.getDisplayName());
            map.put("slotIndex", slot.getSlotIndex());
            map.put("isAssigned", slot.isAssigned());
            map.put("speechTitle", slot.getSpeechTitle());

            if (slot.getAssignedMember() != null) {
                map.put("assignedMemberId", slot.getAssignedMember().getId());
                map.put("assignedMemberName", slot.getAssignedMember().getName());
            } else {
                map.put("assignedMemberId", null);
                map.put("assignedMemberName", null);
            }

            result.add(map);
        }

        return result;
    }

    /**
     * Sign up a member for a role in a meeting.
     */
    @Tool(name = "signup_role", description = "[Sign Up Role] Sign up a member for a specific role in a meeting.")
    public Map<String, Object> signupRole(
            @ToolParam(description = "會議ID", required = true) Long meetingId,
            @ToolParam(description = "角色位置ID (role slot ID)", required = true) Long roleSlotId,
            @ToolParam(description = "要報名的會員Email", required = true) String memberEmail) {

        Map<String, Object> result = new HashMap<>();

        // Find member by email
        Optional<Member> memberOpt = memberRepository.findByEmail(memberEmail);
        if (memberOpt.isEmpty()) {
            result.put("success", false);
            result.put("error", "找不到該會員: " + memberEmail);
            return result;
        }
        Member member = memberOpt.get();

        // Find role slot
        Optional<RoleSlot> slotOpt = roleSlotRepository.findById(roleSlotId);
        if (slotOpt.isEmpty()) {
            result.put("success", false);
            result.put("error", "找不到該角色位置: " + roleSlotId);
            return result;
        }
        RoleSlot slot = slotOpt.get();

        // Verify slot belongs to the meeting
        if (!slot.getMeeting().getId().equals(meetingId)) {
            result.put("success", false);
            result.put("error", "該角色不屬於指定的會議");
            return result;
        }

        // Check if slot is already assigned
        if (slot.isAssigned()) {
            result.put("success", false);
            result.put("error", "該角色已被 " + slot.getAssignedMember().getName() + " 報名");
            return result;
        }

        // Check if meeting is open for signup
        Meeting meeting = slot.getMeeting();
        if (!Meeting.STATUS_OPEN.equals(meeting.getStatus()) &&
                !Meeting.STATUS_DRAFT.equals(meeting.getStatus())) {
            result.put("success", false);
            result.put("error", "該會議尚未開放報名或已截止");
            return result;
        }

        // Check if member is part of the club
        boolean isMember = clubMembershipRepository.existsByMemberIdAndClubIdAndStatus(
                member.getId(), meeting.getClub().getId(), "APPROVED");
        if (!isMember && !"PLATFORM_ADMIN".equals(member.getRole())) {
            result.put("success", false);
            result.put("error", "您尚未加入該分會，無法報名");
            return result;
        }

        // Perform signup
        slot.setAssignedMember(member);
        slot.setAssignedAt(LocalDateTime.now());
        roleSlotRepository.save(slot);

        result.put("success", true);
        result.put("message", "成功報名 " + slot.getDisplayName() + " 角色");
        result.put("meetingId", meetingId);
        result.put("meetingDate", meeting.getMeetingDate().toString());
        result.put("roleName", slot.getDisplayName());
        result.put("memberName", member.getName());

        return result;
    }
}
