package com.toastlabplus.mcp;

import com.toastlabplus.entity.Club;
import com.toastlabplus.entity.ClubMembership;
import com.toastlabplus.entity.ClubOfficer;
import com.toastlabplus.entity.Meeting;
import com.toastlabplus.entity.Member;
import com.toastlabplus.entity.RoleSlot;
import com.toastlabplus.repository.ClubMembershipRepository;
import com.toastlabplus.repository.ClubOfficerRepository;
import com.toastlabplus.repository.ClubRepository;
import com.toastlabplus.repository.MeetingRepository;
import com.toastlabplus.repository.MemberRepository;
import com.toastlabplus.repository.RoleSlotRepository;
import com.toastlabplus.service.TavilyService;
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
    private final ClubOfficerRepository clubOfficerRepository;
    private final TavilyService tavilyService;

    public McpToolService(ClubRepository clubRepository,
            MeetingRepository meetingRepository,
            MemberRepository memberRepository,
            RoleSlotRepository roleSlotRepository,
            ClubMembershipRepository clubMembershipRepository,
            ClubOfficerRepository clubOfficerRepository,
            TavilyService tavilyService) {
        this.clubRepository = clubRepository;
        this.meetingRepository = meetingRepository;
        this.memberRepository = memberRepository;
        this.roleSlotRepository = roleSlotRepository;
        this.clubMembershipRepository = clubMembershipRepository;
        this.clubOfficerRepository = clubOfficerRepository;
        this.tavilyService = tavilyService;
    }

    // ==================== EXISTING TOOLS ====================

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
            @ToolParam(description = "Meeting ID", required = true) Long meetingId,
            @ToolParam(description = "Role slot ID", required = true) Long roleSlotId,
            @ToolParam(description = "Member email address to sign up", required = true) String memberEmail) {

        Map<String, Object> result = new HashMap<>();

        // Find member by email
        Optional<Member> memberOpt = memberRepository.findByEmail(memberEmail);
        if (memberOpt.isEmpty()) {
            result.put("success", false);
            result.put("error", "Member not found: " + memberEmail);
            return result;
        }
        Member member = memberOpt.get();

        // Find role slot
        Optional<RoleSlot> slotOpt = roleSlotRepository.findById(roleSlotId);
        if (slotOpt.isEmpty()) {
            result.put("success", false);
            result.put("error", "Role slot not found: " + roleSlotId);
            return result;
        }
        RoleSlot slot = slotOpt.get();

        // Verify slot belongs to the meeting
        if (!slot.getMeeting().getId().equals(meetingId)) {
            result.put("success", false);
            result.put("error", "This role does not belong to the specified meeting");
            return result;
        }

        // Check if slot is already assigned
        if (slot.isAssigned()) {
            result.put("success", false);
            result.put("error", "This role is already taken by " + slot.getAssignedMember().getName());
            return result;
        }

        // Check if meeting is open for signup
        Meeting meeting = slot.getMeeting();
        if (!Meeting.STATUS_OPEN.equals(meeting.getStatus()) &&
                !Meeting.STATUS_DRAFT.equals(meeting.getStatus())) {
            result.put("success", false);
            result.put("error", "Meeting is not open for signup or has already closed");
            return result;
        }

        // Check if member is part of the club
        boolean isMember = clubMembershipRepository.existsByMemberIdAndClubIdAndStatus(
                member.getId(), meeting.getClub().getId(), "APPROVED");
        if (!isMember && !"PLATFORM_ADMIN".equals(member.getRole())) {
            result.put("success", false);
            result.put("error", "You are not a member of this club");
            return result;
        }

        // Perform signup
        slot.setAssignedMember(member);
        slot.setAssignedAt(LocalDateTime.now());
        roleSlotRepository.save(slot);

        result.put("success", true);
        result.put("message", "Successfully signed up for " + slot.getDisplayName() + " role");
        result.put("meetingId", meetingId);
        result.put("meetingDate", meeting.getMeetingDate().toString());
        result.put("roleName", slot.getDisplayName());
        result.put("memberName", member.getName());

        return result;
    }

    // ==================== NEW MEMBER MANAGEMENT TOOLS ====================

    /**
     * Get member information by email.
     */
    @Tool(name = "get_member_info", description = "[Get Member Info] Get member profile information including name, email, and joined clubs.")
    public Map<String, Object> getMemberInfo(
            @ToolParam(description = "Member email address", required = true) String memberEmail) {

        Map<String, Object> result = new HashMap<>();

        Optional<Member> memberOpt = memberRepository.findByEmail(memberEmail);
        if (memberOpt.isEmpty()) {
            result.put("success", false);
            result.put("error", "Member not found: " + memberEmail);
            return result;
        }

        Member member = memberOpt.get();
        result.put("success", true);
        result.put("id", member.getId());
        result.put("name", member.getName());
        result.put("email", member.getEmail());
        result.put("phone", member.getPhone());
        result.put("role", member.getRole());
        result.put("avatarUrl", member.getAvatarUrl());
        result.put("createdAt", member.getCreatedAt() != null ? member.getCreatedAt().toString() : null);

        // Get clubs the member has joined
        List<ClubMembership> memberships = clubMembershipRepository.findByMemberIdAndStatus(member.getId(), "APPROVED");
        List<Map<String, Object>> clubs = new ArrayList<>();
        for (ClubMembership m : memberships) {
            Map<String, Object> clubMap = new HashMap<>();
            clubMap.put("clubId", m.getClub().getId());
            clubMap.put("clubName", m.getClub().getName());
            clubMap.put("joinedAt", m.getApprovedAt() != null ? m.getApprovedAt().toString() : null);
            clubs.add(clubMap);
        }
        result.put("clubs", clubs);
        result.put("clubCount", clubs.size());

        return result;
    }

    /**
     * Get roles a member has signed up for.
     */
    @Tool(name = "get_my_signups", description = "[Get My Signups] Get a list of roles a member has signed up for in upcoming meetings.")
    public List<Map<String, Object>> getMySignups(
            @ToolParam(description = "Member email address", required = true) String memberEmail,
            @ToolParam(description = "Number of days to look ahead. Default is 30 days.", required = false) Integer daysAhead) {

        List<Map<String, Object>> result = new ArrayList<>();

        Optional<Member> memberOpt = memberRepository.findByEmail(memberEmail);
        if (memberOpt.isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Member not found: " + memberEmail);
            result.add(error);
            return result;
        }

        Member member = memberOpt.get();
        LocalDate fromDate = LocalDate.now();
        List<RoleSlot> slots = roleSlotRepository.findUpcomingByMemberId(member.getId(), fromDate);

        // Filter by daysAhead if specified
        LocalDate endDate = fromDate.plusDays(daysAhead != null ? daysAhead : 30);

        for (RoleSlot slot : slots) {
            if (slot.getMeeting().getMeetingDate().isAfter(endDate)) {
                continue;
            }
            Map<String, Object> map = new HashMap<>();
            map.put("roleSlotId", slot.getId());
            map.put("roleName", slot.getDisplayName());
            map.put("meetingId", slot.getMeeting().getId());
            map.put("meetingDate", slot.getMeeting().getMeetingDate().toString());
            map.put("meetingTitle", slot.getMeeting().getTitle());
            map.put("clubId", slot.getMeeting().getClub().getId());
            map.put("clubName", slot.getMeeting().getClub().getName());
            map.put("speechTitle", slot.getSpeechTitle());
            result.add(map);
        }

        return result;
    }

    /**
     * Cancel a role signup.
     */
    @Tool(name = "cancel_role_signup", description = "[Cancel Role Signup] Cancel a member's role signup for a meeting.")
    public Map<String, Object> cancelRoleSignup(
            @ToolParam(description = "Role slot ID", required = true) Long roleSlotId,
            @ToolParam(description = "Member email address to cancel", required = true) String memberEmail) {

        Map<String, Object> result = new HashMap<>();

        // Find member
        Optional<Member> memberOpt = memberRepository.findByEmail(memberEmail);
        if (memberOpt.isEmpty()) {
            result.put("success", false);
            result.put("error", "Member not found: " + memberEmail);
            return result;
        }
        Member member = memberOpt.get();

        // Find role slot
        Optional<RoleSlot> slotOpt = roleSlotRepository.findById(roleSlotId);
        if (slotOpt.isEmpty()) {
            result.put("success", false);
            result.put("error", "Role slot not found: " + roleSlotId);
            return result;
        }
        RoleSlot slot = slotOpt.get();

        // Check if the slot is assigned to this member
        if (slot.getAssignedMember() == null || !slot.getAssignedMember().getId().equals(member.getId())) {
            result.put("success", false);
            result.put("error", "You are not signed up for this role");
            return result;
        }

        // Check if meeting date has passed
        if (slot.getMeeting().getMeetingDate().isBefore(LocalDate.now())) {
            result.put("success", false);
            result.put("error", "Meeting has already ended, cannot cancel signup");
            return result;
        }

        // Cancel signup
        String roleName = slot.getDisplayName();
        slot.setAssignedMember(null);
        slot.setAssignedAt(null);
        roleSlotRepository.save(slot);

        result.put("success", true);
        result.put("message", "Successfully cancelled " + roleName + " role signup");
        result.put("roleSlotId", roleSlotId);
        result.put("roleName", roleName);

        return result;
    }

    // ==================== NEW CLUB MANAGEMENT TOOLS ====================

    /**
     * Get club members list.
     */
    @Tool(name = "get_club_members", description = "[Get Club Members] Get a list of all members in a club.")
    public List<Map<String, Object>> getClubMembers(
            @ToolParam(description = "Club ID", required = true) Long clubId) {

        List<Map<String, Object>> result = new ArrayList<>();

        List<ClubMembership> memberships = clubMembershipRepository.findByClubIdAndStatusWithMember(clubId, "APPROVED");

        for (ClubMembership m : memberships) {
            Map<String, Object> map = new HashMap<>();
            map.put("memberId", m.getMember().getId());
            map.put("name", m.getMember().getName());
            map.put("email", m.getMember().getEmail());
            map.put("joinedAt", m.getApprovedAt() != null ? m.getApprovedAt().toString() : null);
            result.add(map);
        }

        return result;
    }

    /**
     * Get club officers list.
     */
    @Tool(name = "get_club_officers", description = "[Get Club Officers] Get a list of club officers (President, VPE, VPM, etc.).")
    public List<Map<String, Object>> getClubOfficers(
            @ToolParam(description = "Club ID", required = true) Long clubId) {

        List<Map<String, Object>> result = new ArrayList<>();

        List<ClubOfficer> officers = clubOfficerRepository.findByClubIdWithMember(clubId);

        for (ClubOfficer officer : officers) {
            Map<String, Object> map = new HashMap<>();
            map.put("position", officer.getPosition());
            map.put("positionName", getPositionDisplayName(officer.getPosition()));
            if (officer.getMember() != null) {
                map.put("memberId", officer.getMember().getId());
                map.put("memberName", officer.getMember().getName());
                map.put("memberEmail", officer.getMember().getEmail());
            } else {
                map.put("memberId", null);
                map.put("memberName", "(Vacant)");
                map.put("memberEmail", null);
            }
            map.put("termStart", officer.getTermStart() != null ? officer.getTermStart().toString() : null);
            map.put("termEnd", officer.getTermEnd() != null ? officer.getTermEnd().toString() : null);
            result.add(map);
        }

        return result;
    }

    private String getPositionDisplayName(String position) {
        return switch (position) {
            case "PRESIDENT" -> "President";
            case "VPE" -> "VP Education";
            case "VPM" -> "VP Membership";
            case "VPPR" -> "VP Public Relations";
            case "SECRETARY" -> "Secretary";
            case "TREASURER" -> "Treasurer";
            case "SAA" -> "Sergeant at Arms";
            default -> position;
        };
    }

    // ==================== NEW MEETING MANAGEMENT TOOLS ====================

    /**
     * Get detailed meeting information.
     */
    @Tool(name = "get_meeting_details", description = "[Get Meeting Details] Get complete meeting information including all role assignments.")
    public Map<String, Object> getMeetingDetails(
            @ToolParam(description = "Meeting ID", required = true) Long meetingId) {

        Map<String, Object> result = new HashMap<>();

        Optional<Meeting> meetingOpt = meetingRepository.findById(meetingId);
        if (meetingOpt.isEmpty()) {
            result.put("success", false);
            result.put("error", "Meeting not found: " + meetingId);
            return result;
        }

        Meeting meeting = meetingOpt.get();
        result.put("success", true);
        result.put("id", meeting.getId());
        result.put("title", meeting.getTitle());
        result.put("theme", meeting.getTheme());
        result.put("meetingNumber", meeting.getMeetingNumber());
        result.put("meetingDate", meeting.getMeetingDate().toString());
        result.put("startTime", meeting.getStartTime() != null ? meeting.getStartTime().toString() : null);
        result.put("endTime", meeting.getEndTime() != null ? meeting.getEndTime().toString() : null);
        result.put("location", meeting.getLocation());
        result.put("status", meeting.getStatus());
        result.put("speakerCount", meeting.getSpeakerCount());
        result.put("clubId", meeting.getClub().getId());
        result.put("clubName", meeting.getClub().getName());

        // Get all role slots with details
        List<RoleSlot> slots = roleSlotRepository.findByMeetingIdWithMember(meetingId);
        List<Map<String, Object>> roleSlots = new ArrayList<>();
        int assignedCount = 0;

        for (RoleSlot slot : slots) {
            Map<String, Object> slotMap = new HashMap<>();
            slotMap.put("id", slot.getId());
            slotMap.put("roleName", slot.getRoleName());
            slotMap.put("displayName", slot.getDisplayName());
            slotMap.put("slotIndex", slot.getSlotIndex());
            slotMap.put("isAssigned", slot.isAssigned());
            slotMap.put("speechTitle", slot.getSpeechTitle());

            if (slot.getAssignedMember() != null) {
                slotMap.put("assignedMemberName", slot.getAssignedMember().getName());
                assignedCount++;
            } else {
                slotMap.put("assignedMemberName", null);
            }
            roleSlots.add(slotMap);
        }

        result.put("roleSlots", roleSlots);
        result.put("totalRoleSlots", slots.size());
        result.put("assignedRoleSlots", assignedCount);
        result.put("availableRoleSlots", slots.size() - assignedCount);

        return result;
    }

    // ==================== NEW STATISTICS TOOLS ====================

    /**
     * Get member participation statistics.
     */
    @Tool(name = "get_member_stats", description = "[Get Member Stats] Get member participation statistics including total roles played.")
    public Map<String, Object> getMemberStats(
            @ToolParam(description = "Member email address", required = true) String memberEmail,
            @ToolParam(description = "Club ID. If not specified, returns stats for all clubs.", required = false) Long clubId) {

        Map<String, Object> result = new HashMap<>();

        Optional<Member> memberOpt = memberRepository.findByEmail(memberEmail);
        if (memberOpt.isEmpty()) {
            result.put("success", false);
            result.put("error", "Member not found: " + memberEmail);
            return result;
        }

        Member member = memberOpt.get();
        result.put("success", true);
        result.put("memberId", member.getId());
        result.put("memberName", member.getName());

        if (clubId != null) {
            // Stats for specific club
            long roleCount = roleSlotRepository.countByMemberIdAndClubId(member.getId(), clubId);
            result.put("clubId", clubId);
            result.put("totalRolesPlayed", roleCount);
        } else {
            // Stats for all clubs
            long roleCount = roleSlotRepository.countByAssignedMemberIdTotal(member.getId());
            result.put("totalRolesPlayed", roleCount);
        }

        // Get upcoming roles count
        List<RoleSlot> upcomingSlots = roleSlotRepository.findUpcomingByMemberId(member.getId(), LocalDate.now());
        result.put("upcomingRolesCount", upcomingSlots.size());

        // Get club count
        List<ClubMembership> memberships = clubMembershipRepository.findByMemberIdAndStatus(member.getId(), "APPROVED");
        result.put("clubsJoined", memberships.size());

        return result;
    }

    /**
     * Get upcoming roles for a member.
     */
    @Tool(name = "get_upcoming_roles", description = "[Get Upcoming Roles] Get a list of upcoming roles a member is assigned to.")
    public List<Map<String, Object>> getUpcomingRoles(
            @ToolParam(description = "Member email address", required = true) String memberEmail) {

        List<Map<String, Object>> result = new ArrayList<>();

        Optional<Member> memberOpt = memberRepository.findByEmail(memberEmail);
        if (memberOpt.isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Member not found: " + memberEmail);
            result.add(error);
            return result;
        }

        Member member = memberOpt.get();
        List<RoleSlot> slots = roleSlotRepository.findUpcomingByMemberId(member.getId(), LocalDate.now());

        for (RoleSlot slot : slots) {
            Map<String, Object> map = new HashMap<>();
            map.put("roleSlotId", slot.getId());
            map.put("roleName", slot.getDisplayName());
            map.put("meetingId", slot.getMeeting().getId());
            map.put("meetingDate", slot.getMeeting().getMeetingDate().toString());
            map.put("meetingTitle", slot.getMeeting().getTitle());
            map.put("clubId", slot.getMeeting().getClub().getId());
            map.put("clubName", slot.getMeeting().getClub().getName());
            map.put("location", slot.getMeeting().getLocation());
            map.put("speechTitle", slot.getSpeechTitle());

            // Calculate days until meeting
            long daysUntil = java.time.temporal.ChronoUnit.DAYS.between(LocalDate.now(),
                    slot.getMeeting().getMeetingDate());
            map.put("daysUntil", daysUntil);

            result.add(map);
        }

        return result;
    }

    // ==================== WEB SEARCH TOOL ====================

    /**
     * Search the web using Tavily API.
     */
    @Tool(name = "web_search", description = "[Web Search] Search the web using Tavily API. Useful for Toastmasters knowledge, speech tips, meeting rules, etc.")
    public Map<String, Object> webSearch(
            @ToolParam(description = "Search query keywords", required = true) String query,
            @ToolParam(description = "Number of results to return. Default is 5, max is 10.", required = false) Integer maxResults,
            @ToolParam(description = "Search topic: 'general' or 'news'", required = false) String topic) {

        System.out.println("=== MCP Web Search Request ===");
        System.out.println("Query: " + query);

        Map<String, Object> result = tavilyService.search(query, maxResults, topic);

        System.out.println("=== MCP Web Search Result ===");
        System.out.println(result);
        System.out.println("==============================");

        return result;
    }
}
