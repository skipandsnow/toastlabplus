package com.toastlabplus.controller;

import com.toastlabplus.entity.Meeting;
import com.toastlabplus.entity.Member;
import com.toastlabplus.entity.RoleSlot;
import com.toastlabplus.repository.ClubAdminRepository;
import com.toastlabplus.repository.ClubMembershipRepository;
import com.toastlabplus.repository.MeetingRepository;
import com.toastlabplus.repository.MemberRepository;
import com.toastlabplus.repository.RoleSlotRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/meetings/{meetingId}/roles")
public class RoleSlotController {

    private final RoleSlotRepository roleSlotRepository;
    private final MeetingRepository meetingRepository;
    private final MemberRepository memberRepository;
    private final ClubAdminRepository clubAdminRepository;
    private final ClubMembershipRepository clubMembershipRepository;

    public RoleSlotController(RoleSlotRepository roleSlotRepository,
            MeetingRepository meetingRepository,
            MemberRepository memberRepository,
            ClubAdminRepository clubAdminRepository,
            ClubMembershipRepository clubMembershipRepository) {
        this.roleSlotRepository = roleSlotRepository;
        this.meetingRepository = meetingRepository;
        this.memberRepository = memberRepository;
        this.clubAdminRepository = clubAdminRepository;
        this.clubMembershipRepository = clubMembershipRepository;
    }

    /**
     * Get all role slots for a meeting.
     */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getRoleSlots(@PathVariable Long meetingId) {
        Meeting meeting = meetingRepository.findById(meetingId).orElse(null);
        if (meeting == null) {
            return ResponseEntity.notFound().build();
        }

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
            map.put("projectName", slot.getProjectName());

            if (slot.getAssignedMember() != null) {
                Member m = slot.getAssignedMember();
                map.put("memberId", m.getId());
                map.put("memberName", m.getName());
                map.put("memberEmail", m.getEmail());
                map.put("memberAvatarUrl", m.getAvatarUrl());
            }

            result.add(map);
        }

        return ResponseEntity.ok(result);
    }

    /**
     * Sign up for a role (self sign-up).
     */
    @PostMapping("/{roleSlotId}/signup")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> signUpForRole(
            @PathVariable Long meetingId,
            @PathVariable Long roleSlotId,
            @AuthenticationPrincipal UserDetails userDetails) {

        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        Meeting meeting = meetingRepository.findById(meetingId).orElse(null);
        if (meeting == null) {
            return ResponseEntity.notFound().build();
        }

        // Check if meeting is open for sign-up
        if (!"OPEN".equals(meeting.getStatus()) && !"DRAFT".equals(meeting.getStatus())) {
            return ResponseEntity.badRequest().body(Map.of("error", "Meeting is not open for sign-up"));
        }

        // Check if user is a member of the club
        boolean isMember = clubMembershipRepository.existsByMemberIdAndClubIdAndStatus(
                currentMember.getId(), meeting.getClub().getId(), "APPROVED");
        if (!isMember && !"PLATFORM_ADMIN".equals(currentMember.getRole())) {
            return ResponseEntity.status(403).body(Map.of("error", "You are not a member of this club"));
        }

        RoleSlot slot = roleSlotRepository.findById(roleSlotId).orElse(null);
        if (slot == null || !slot.getMeeting().getId().equals(meetingId)) {
            return ResponseEntity.notFound().build();
        }

        if (slot.isAssigned()) {
            return ResponseEntity.badRequest().body(Map.of("error", "This role is already assigned"));
        }

        slot.setAssignedMember(currentMember);
        slot.setAssignedAt(LocalDateTime.now());
        roleSlotRepository.save(slot);

        return ResponseEntity.ok(Map.of(
                "message", "Successfully signed up for " + slot.getDisplayName(),
                "roleSlotId", slot.getId()));
    }

    /**
     * Cancel sign-up for a role.
     */
    @DeleteMapping("/{roleSlotId}/signup")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> cancelSignUp(
            @PathVariable Long meetingId,
            @PathVariable Long roleSlotId,
            @AuthenticationPrincipal UserDetails userDetails) {

        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        RoleSlot slot = roleSlotRepository.findById(roleSlotId).orElse(null);
        if (slot == null || !slot.getMeeting().getId().equals(meetingId)) {
            return ResponseEntity.notFound().build();
        }

        // Only the assigned member or admin can cancel
        boolean isAssignee = slot.getAssignedMember() != null &&
                slot.getAssignedMember().getId().equals(currentMember.getId());
        boolean isAdmin = "PLATFORM_ADMIN".equals(currentMember.getRole()) ||
                clubAdminRepository.existsByMemberIdAndClubId(
                        currentMember.getId(), slot.getMeeting().getClub().getId());

        if (!isAssignee && !isAdmin) {
            return ResponseEntity.status(403).body(Map.of("error", "You can only cancel your own sign-up"));
        }

        slot.setAssignedMember(null);
        slot.setAssignedAt(null);
        roleSlotRepository.save(slot);

        return ResponseEntity.ok(Map.of("message", "Sign-up cancelled"));
    }

    /**
     * Assign a member to a role (VPE/Admin action).
     */
    @PostMapping("/{roleSlotId}/assign")
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> assignRole(
            @PathVariable Long meetingId,
            @PathVariable Long roleSlotId,
            @RequestBody AssignRoleRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        Meeting meeting = meetingRepository.findById(meetingId).orElse(null);
        if (meeting == null) {
            return ResponseEntity.notFound().build();
        }

        // Check if user can admin this club
        boolean isAdmin = "PLATFORM_ADMIN".equals(currentMember.getRole()) ||
                clubAdminRepository.existsByMemberIdAndClubId(
                        currentMember.getId(), meeting.getClub().getId());
        if (!isAdmin) {
            return ResponseEntity.status(403).body(Map.of("error", "You are not an admin of this club"));
        }

        RoleSlot slot = roleSlotRepository.findById(roleSlotId).orElse(null);
        if (slot == null || !slot.getMeeting().getId().equals(meetingId)) {
            return ResponseEntity.notFound().build();
        }

        Member targetMember = memberRepository.findById(request.memberId()).orElse(null);
        if (targetMember == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Member not found"));
        }

        slot.setAssignedMember(targetMember);
        slot.setAssignedBy(currentMember);
        slot.setAssignedAt(LocalDateTime.now());

        if (request.speechTitle() != null) {
            slot.setSpeechTitle(request.speechTitle());
        }
        if (request.projectName() != null) {
            slot.setProjectName(request.projectName());
        }

        roleSlotRepository.save(slot);

        return ResponseEntity.ok(Map.of(
                "message", "Role assigned successfully",
                "roleSlotId", slot.getId(),
                "memberName", targetMember.getName()));
    }

    /**
     * Update role slot (speech title, project name).
     */
    @PutMapping("/{roleSlotId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> updateRoleSlot(
            @PathVariable Long meetingId,
            @PathVariable Long roleSlotId,
            @RequestBody UpdateRoleSlotRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        RoleSlot slot = roleSlotRepository.findById(roleSlotId).orElse(null);
        if (slot == null || !slot.getMeeting().getId().equals(meetingId)) {
            return ResponseEntity.notFound().build();
        }

        // Check if user can edit (assignee or admin)
        boolean isAssignee = slot.getAssignedMember() != null &&
                slot.getAssignedMember().getId().equals(currentMember.getId());
        boolean isAdmin = "PLATFORM_ADMIN".equals(currentMember.getRole()) ||
                clubAdminRepository.existsByMemberIdAndClubId(
                        currentMember.getId(), slot.getMeeting().getClub().getId());

        if (!isAssignee && !isAdmin) {
            return ResponseEntity.status(403).body(Map.of("error", "You cannot edit this role"));
        }

        if (request.speechTitle() != null) {
            slot.setSpeechTitle(request.speechTitle());
        }
        if (request.projectName() != null) {
            slot.setProjectName(request.projectName());
        }

        roleSlotRepository.save(slot);

        return ResponseEntity.ok(Map.of("message", "Role updated"));
    }

    // ==================== Request DTOs ====================

    public record AssignRoleRequest(
            Long memberId,
            String speechTitle,
            String projectName) {
    }

    public record UpdateRoleSlotRequest(
            String speechTitle,
            String projectName) {
    }
}
