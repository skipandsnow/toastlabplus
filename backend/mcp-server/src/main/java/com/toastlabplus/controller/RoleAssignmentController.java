package com.toastlabplus.controller;

import com.toastlabplus.entity.Meeting;
import com.toastlabplus.entity.Member;
import com.toastlabplus.entity.RoleAssignment;
import com.toastlabplus.repository.MeetingRepository;
import com.toastlabplus.repository.MemberRepository;
import com.toastlabplus.repository.RoleAssignmentRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/role-assignments")
public class RoleAssignmentController {

    private final RoleAssignmentRepository roleAssignmentRepository;
    private final MeetingRepository meetingRepository;
    private final MemberRepository memberRepository;

    public RoleAssignmentController(RoleAssignmentRepository roleAssignmentRepository,
            MeetingRepository meetingRepository,
            MemberRepository memberRepository) {
        this.roleAssignmentRepository = roleAssignmentRepository;
        this.meetingRepository = meetingRepository;
        this.memberRepository = memberRepository;
    }

    /**
     * Get role assignments for a meeting.
     * Can only view assignments for meetings in your club.
     */
    @GetMapping("/meeting/{meetingId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getRolesByMeeting(
            @PathVariable Long meetingId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        Meeting meeting = meetingRepository.findById(meetingId).orElse(null);
        if (meeting == null) {
            return ResponseEntity.notFound().build();
        }

        // Platform Admin can view any meeting's roles
        if (!"PLATFORM_ADMIN".equals(currentMember.getRole())) {
            // Check if meeting is in the same club
            if (currentMember.getClub() == null || meeting.getClub() == null ||
                    !currentMember.getClub().getId().equals(meeting.getClub().getId())) {
                return ResponseEntity.status(403).body("Cannot view roles from other clubs");
            }
        }

        List<RoleAssignment> assignments = roleAssignmentRepository.findByMeetingId(meetingId);
        return ResponseEntity.ok(assignments);
    }

    /**
     * Get role assignments for a member.
     * Can only view your own assignments or members in your club (if admin).
     */
    @GetMapping("/member/{memberId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getRolesByMember(
            @PathVariable Long memberId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        Member targetMember = memberRepository.findById(memberId).orElse(null);
        if (targetMember == null) {
            return ResponseEntity.notFound().build();
        }

        // Platform Admin can view any member's roles
        if (!"PLATFORM_ADMIN".equals(currentMember.getRole())) {
            // Members can view their own roles
            if (!currentMember.getId().equals(memberId)) {
                // Admin can view roles of members in their club
                if (!"CLUB_ADMIN".equals(currentMember.getRole()) ||
                        currentMember.getClub() == null || targetMember.getClub() == null ||
                        !currentMember.getClub().getId().equals(targetMember.getClub().getId())) {
                    return ResponseEntity.status(403).body("Cannot view roles from other members");
                }
            }
        }

        List<RoleAssignment> assignments = roleAssignmentRepository.findByMemberId(memberId);
        return ResponseEntity.ok(assignments);
    }

    /**
     * Create a role assignment.
     * Only Club Admin can assign roles for meetings in their club.
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> createRoleAssignment(
            @Valid @RequestBody CreateRoleAssignmentRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        Meeting meeting = meetingRepository.findById(request.meetingId())
                .orElseThrow(() -> new IllegalArgumentException("Meeting not found"));

        Member assignee = memberRepository.findById(request.memberId())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        // Club Admin can only assign roles for their club's meetings
        if ("CLUB_ADMIN".equals(currentMember.getRole())) {
            if (currentMember.getClub() == null || meeting.getClub() == null ||
                    !currentMember.getClub().getId().equals(meeting.getClub().getId())) {
                return ResponseEntity.status(403).body("Cannot assign roles for other clubs");
            }
        }

        RoleAssignment assignment = new RoleAssignment();
        assignment.setMeeting(meeting);
        assignment.setMember(assignee);
        assignment.setRoleName(request.roleName());
        assignment.setAssignedBy(currentMember);
        assignment.setAssignedAt(LocalDateTime.now());

        RoleAssignment saved = roleAssignmentRepository.save(assignment);

        return ResponseEntity.ok(Map.of(
                "message", "Role assigned successfully",
                "assignmentId", saved.getId(),
                "roleName", saved.getRoleName(),
                "memberName", assignee.getName()));
    }

    // ==================== Request DTOs ====================

    public record CreateRoleAssignmentRequest(
            @NotNull(message = "Meeting ID is required") Long meetingId,
            @NotNull(message = "Member ID is required") Long memberId,
            @NotBlank(message = "Role name is required") String roleName) {
    }
}
