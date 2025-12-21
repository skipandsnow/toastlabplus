package com.toastlabplus.controller;

import com.toastlabplus.entity.Club;
import com.toastlabplus.entity.Meeting;
import com.toastlabplus.entity.Member;
import com.toastlabplus.repository.ClubAdminRepository;
import com.toastlabplus.repository.ClubMembershipRepository;
import com.toastlabplus.repository.ClubRepository;
import com.toastlabplus.repository.MeetingRepository;
import com.toastlabplus.repository.MemberRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/meetings")
public class MeetingController {

    private final MeetingRepository meetingRepository;
    private final MemberRepository memberRepository;
    private final ClubRepository clubRepository;
    private final ClubAdminRepository clubAdminRepository;
    private final ClubMembershipRepository clubMembershipRepository;

    public MeetingController(MeetingRepository meetingRepository,
            MemberRepository memberRepository,
            ClubRepository clubRepository,
            ClubAdminRepository clubAdminRepository,
            ClubMembershipRepository clubMembershipRepository) {
        this.meetingRepository = meetingRepository;
        this.memberRepository = memberRepository;
        this.clubRepository = clubRepository;
        this.clubAdminRepository = clubAdminRepository;
        this.clubMembershipRepository = clubMembershipRepository;
    }

    /**
     * Get meetings for the current user's clubs.
     * Platform Admin can see all meetings.
     */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getMeetings(@AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        List<Meeting> meetings;

        // Platform Admin can see all meetings
        if ("PLATFORM_ADMIN".equals(currentMember.getRole())) {
            meetings = meetingRepository.findAll();
        } else {
            // Get club IDs from memberships
            List<Long> clubIds = clubMembershipRepository.findByMemberId(currentMember.getId()).stream()
                    .filter(m -> "APPROVED".equals(m.getStatus()))
                    .map(m -> m.getClub().getId())
                    .collect(Collectors.toList());

            if (clubIds.isEmpty()) {
                return ResponseEntity.ok(List.of());
            }
            meetings = meetingRepository.findByClubIdIn(clubIds);
        }

        return ResponseEntity.ok(meetings);
    }

    /**
     * Get a specific meeting by ID.
     */
    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getMeetingById(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails) {
        Meeting meeting = meetingRepository.findById(id).orElse(null);
        if (meeting == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(meeting);
    }

    /**
     * Get meetings by club ID.
     */
    @GetMapping("/club/{clubId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getMeetingsByClub(
            @PathVariable Long clubId,
            @AuthenticationPrincipal UserDetails userDetails) {
        List<Meeting> meetings = meetingRepository.findByClubIdOrderByMeetingDateDesc(clubId);
        return ResponseEntity.ok(meetings);
    }

    /**
     * Create a new meeting.
     * Club Admin can only create meetings for clubs they manage.
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> createMeeting(
            @Valid @RequestBody CreateMeetingRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        Long targetClubId = request.clubId();

        // Club Admin must provide clubId and can only create for clubs they manage
        if (!"PLATFORM_ADMIN".equals(currentMember.getRole())) {
            if (targetClubId == null) {
                return ResponseEntity.badRequest().body("clubId is required");
            }
            if (!clubAdminRepository.existsByMemberIdAndClubId(currentMember.getId(), targetClubId)) {
                return ResponseEntity.status(403).body("You can only create meetings for clubs you manage");
            }
        }

        Club club = clubRepository.findById(targetClubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        Meeting meeting = new Meeting();
        meeting.setClub(club);
        meeting.setTitle(request.title());
        meeting.setTheme(request.description());
        meeting.setMeetingDate(request.meetingDate());
        meeting.setLocation(request.location());
        meeting.setStatus("SCHEDULED");
        meeting.setCreatedAt(LocalDateTime.now());
        meeting.setUpdatedAt(LocalDateTime.now());

        Meeting saved = meetingRepository.save(meeting);

        return ResponseEntity.ok(Map.of(
                "message", "Meeting created successfully",
                "meetingId", saved.getId(),
                "title", saved.getTitle()));
    }

    /**
     * Delete a meeting.
     * Only Club Admin of the meeting's club or Platform Admin can delete.
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> deleteMeeting(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        Meeting meeting = meetingRepository.findById(id).orElse(null);
        if (meeting == null) {
            return ResponseEntity.notFound().build();
        }

        // Check permission
        Long clubId = meeting.getClub().getId();
        if (!"PLATFORM_ADMIN".equals(currentMember.getRole())) {
            if (!clubAdminRepository.existsByMemberIdAndClubId(currentMember.getId(), clubId)) {
                return ResponseEntity.status(403)
                        .body(Map.of("error", "You can only delete meetings for clubs you manage"));
            }
        }

        // Delete the meeting (cascade will delete role slots)
        meetingRepository.delete(meeting);

        return ResponseEntity.ok(Map.of("message", "Meeting deleted successfully"));
    }

    /**
     * Update a meeting (theme, title, location).
     * Only Club Admin of the meeting's club or Platform Admin can update.
     */
    @PatchMapping("/{id}")
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> updateMeeting(
            @PathVariable Long id,
            @RequestBody Map<String, String> updates,
            @AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        Meeting meeting = meetingRepository.findById(id).orElse(null);
        if (meeting == null) {
            return ResponseEntity.notFound().build();
        }

        // Check permission
        Long clubId = meeting.getClub().getId();
        if (!"PLATFORM_ADMIN".equals(currentMember.getRole())) {
            if (!clubAdminRepository.existsByMemberIdAndClubId(currentMember.getId(), clubId)) {
                return ResponseEntity.status(403)
                        .body(Map.of("error", "You can only update meetings for clubs you manage"));
            }
        }

        // Apply updates
        if (updates.containsKey("theme")) {
            meeting.setTheme(updates.get("theme"));
        }
        if (updates.containsKey("title")) {
            meeting.setTitle(updates.get("title"));
        }
        if (updates.containsKey("location")) {
            meeting.setLocation(updates.get("location"));
        }

        meeting.setUpdatedAt(LocalDateTime.now());
        Meeting saved = meetingRepository.save(meeting);

        return ResponseEntity.ok(Map.of(
                "message", "Meeting updated successfully",
                "meetingId", saved.getId(),
                "theme", saved.getTheme() != null ? saved.getTheme() : ""));
    }

    // ==================== Request DTOs ====================

    public record CreateMeetingRequest(
            Long clubId,
            @NotNull(message = "Title is required") String title,
            String description,
            LocalDate meetingDate,
            String location) {
    }
}
