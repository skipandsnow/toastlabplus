package com.toastlabplus.controller;

import com.toastlabplus.entity.Club;
import com.toastlabplus.entity.Meeting;
import com.toastlabplus.entity.Member;
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

@RestController
@RequestMapping("/api/meetings")
public class MeetingController {

    private final MeetingRepository meetingRepository;
    private final MemberRepository memberRepository;
    private final ClubRepository clubRepository;

    public MeetingController(MeetingRepository meetingRepository,
            MemberRepository memberRepository,
            ClubRepository clubRepository) {
        this.meetingRepository = meetingRepository;
        this.memberRepository = memberRepository;
        this.clubRepository = clubRepository;
    }

    /**
     * Get meetings for the current user's club.
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
        } else if (currentMember.getClub() != null) {
            // Other users can only see meetings of their own club
            meetings = meetingRepository.findByClubIdOrderByMeetingDateDesc(currentMember.getClub().getId());
        } else {
            return ResponseEntity.ok(List.of());
        }

        return ResponseEntity.ok(meetings);
    }

    /**
     * Get a specific meeting by ID.
     * Can only view meetings of your own club.
     */
    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getMeetingById(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        Meeting meeting = meetingRepository.findById(id).orElse(null);
        if (meeting == null) {
            return ResponseEntity.notFound().build();
        }

        // Platform Admin can view any meeting
        if ("PLATFORM_ADMIN".equals(currentMember.getRole())) {
            return ResponseEntity.ok(meeting);
        }

        // Check if meeting is in the same club
        if (currentMember.getClub() != null && meeting.getClub() != null &&
                currentMember.getClub().getId().equals(meeting.getClub().getId())) {
            return ResponseEntity.ok(meeting);
        }

        return ResponseEntity.status(403).body("Cannot view meetings from other clubs");
    }

    /**
     * Get meetings by club ID.
     * Only Club Admin/Platform Admin can access other club's meetings.
     */
    @GetMapping("/club/{clubId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getMeetingsByClub(
            @PathVariable Long clubId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        // Members can only see their own club's meetings
        if (!"PLATFORM_ADMIN".equals(currentMember.getRole())) {
            if (currentMember.getClub() == null || !currentMember.getClub().getId().equals(clubId)) {
                return ResponseEntity.status(403).body("Cannot view meetings from other clubs");
            }
        }

        List<Meeting> meetings = meetingRepository.findByClubIdOrderByMeetingDateDesc(clubId);
        return ResponseEntity.ok(meetings);
    }

    /**
     * Create a new meeting.
     * Only Club Admin can create meetings for their club.
     * Platform Admin can create meetings for any club.
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> createMeeting(
            @Valid @RequestBody CreateMeetingRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        Long targetClubId = request.clubId();

        // Club Admin can only create meetings for their own club
        if ("CLUB_ADMIN".equals(currentMember.getRole())) {
            if (currentMember.getClub() == null) {
                return ResponseEntity.badRequest().body("You are not associated with a club");
            }
            targetClubId = currentMember.getClub().getId();
        }

        Club club = clubRepository.findById(targetClubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        Meeting meeting = new Meeting();
        meeting.setClub(club);
        meeting.setTitle(request.title());
        meeting.setDescription(request.description());
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

    // ==================== Request DTOs ====================

    public record CreateMeetingRequest(
            Long clubId,
            @NotNull(message = "Title is required") String title,
            String description,
            LocalDate meetingDate,
            String location) {
    }
}
