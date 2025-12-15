package com.toastlabplus.controller;

import com.toastlabplus.entity.Club;
import com.toastlabplus.entity.ClubOfficer;
import com.toastlabplus.entity.Member;
import com.toastlabplus.repository.ClubAdminRepository;
import com.toastlabplus.repository.ClubMembershipRepository;
import com.toastlabplus.repository.ClubOfficerRepository;
import com.toastlabplus.repository.ClubRepository;
import com.toastlabplus.repository.MemberRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/clubs/{clubId}/officers")
public class ClubOfficerController {

    private final ClubOfficerRepository clubOfficerRepository;
    private final ClubRepository clubRepository;
    private final MemberRepository memberRepository;
    private final ClubAdminRepository clubAdminRepository;
    private final ClubMembershipRepository clubMembershipRepository;

    public ClubOfficerController(
            ClubOfficerRepository clubOfficerRepository,
            ClubRepository clubRepository,
            MemberRepository memberRepository,
            ClubAdminRepository clubAdminRepository,
            ClubMembershipRepository clubMembershipRepository) {
        this.clubOfficerRepository = clubOfficerRepository;
        this.clubRepository = clubRepository;
        this.memberRepository = memberRepository;
        this.clubAdminRepository = clubAdminRepository;
        this.clubMembershipRepository = clubMembershipRepository;
    }

    /**
     * Get all officers for a club (including vacant positions)
     */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getOfficers(@PathVariable Long clubId) {
        // Build a map of all positions with their current holders
        List<ClubOfficer> officers = clubOfficerRepository.findByClubIdWithMember(clubId);
        Map<String, ClubOfficer> officerMap = officers.stream()
                .collect(Collectors.toMap(ClubOfficer::getPosition, o -> o));

        // Build response with all positions (filled or vacant)
        List<Map<String, Object>> result = new ArrayList<>();
        for (String position : ClubOfficer.ALL_POSITIONS) {
            Map<String, Object> positionInfo = new LinkedHashMap<>();
            positionInfo.put("position", position);
            positionInfo.put("positionDisplay", getPositionDisplay(position));

            ClubOfficer officer = officerMap.get(position);
            if (officer != null && officer.getMember() != null) {
                Member member = officer.getMember();
                positionInfo.put("officerId", officer.getId());
                positionInfo.put("memberId", member.getId());
                positionInfo.put("memberName", member.getName());
                positionInfo.put("memberEmail", member.getEmail());
                positionInfo.put("memberAvatarUrl", member.getAvatarUrl());
                positionInfo.put("termStart", officer.getTermStart());
                positionInfo.put("termEnd", officer.getTermEnd());
                positionInfo.put("isFilled", true);
            } else {
                positionInfo.put("isFilled", false);
            }
            result.add(positionInfo);
        }

        return ResponseEntity.ok(result);
    }

    /**
     * Assign a member to an officer position
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> assignOfficer(
            @PathVariable Long clubId,
            @Valid @RequestBody AssignOfficerRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        // Verify permission
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        if (!"PLATFORM_ADMIN".equals(currentMember.getRole())) {
            if (!clubAdminRepository.existsByMemberIdAndClubId(currentMember.getId(), clubId)) {
                return ResponseEntity.status(403)
                        .body(Map.of("error", "You can only manage officers for clubs you administer"));
            }
        }

        // Validate position
        if (!isValidPosition(request.position())) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid position: " + request.position()));
        }

        Club club = clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        Member member = memberRepository.findById(request.memberId())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        // Check if member belongs to this club
        boolean isMember = clubMembershipRepository.findByMemberId(member.getId()).stream()
                .anyMatch(m -> m.getClub().getId().equals(clubId) && "APPROVED".equals(m.getStatus()));
        if (!isMember) {
            return ResponseEntity.badRequest().body(Map.of("error", "Member is not part of this club"));
        }

        // Deactivate existing officer for this position if any
        clubOfficerRepository.findByClubIdAndPositionAndIsActiveTrue(clubId, request.position())
                .ifPresent(existing -> {
                    existing.setIsActive(false);
                    existing.setUpdatedAt(LocalDateTime.now());
                    clubOfficerRepository.save(existing);
                });

        // Create new assignment
        ClubOfficer officer = new ClubOfficer(club, request.position());
        officer.setMember(member);
        officer.setTermStart(request.termStart());
        officer.setTermEnd(request.termEnd());
        officer.setIsActive(true);
        officer.setCreatedAt(LocalDateTime.now());
        officer.setUpdatedAt(LocalDateTime.now());

        ClubOfficer saved = clubOfficerRepository.save(officer);

        return ResponseEntity.ok(Map.of(
                "message", "Officer assigned successfully",
                "officerId", saved.getId(),
                "position", saved.getPosition(),
                "memberName", member.getName()));
    }

    /**
     * Remove an officer from a position
     */
    @DeleteMapping("/{officerId}")
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> removeOfficer(
            @PathVariable Long clubId,
            @PathVariable Long officerId,
            @AuthenticationPrincipal UserDetails userDetails) {

        // Verify permission
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        if (!"PLATFORM_ADMIN".equals(currentMember.getRole())) {
            if (!clubAdminRepository.existsByMemberIdAndClubId(currentMember.getId(), clubId)) {
                return ResponseEntity.status(403)
                        .body(Map.of("error", "You can only manage officers for clubs you administer"));
            }
        }

        ClubOfficer officer = clubOfficerRepository.findById(officerId).orElse(null);
        if (officer == null || !officer.getClub().getId().equals(clubId)) {
            return ResponseEntity.notFound().build();
        }

        // Deactivate instead of delete (preserve history)
        officer.setIsActive(false);
        officer.setUpdatedAt(LocalDateTime.now());
        clubOfficerRepository.save(officer);

        return ResponseEntity.ok(Map.of("message", "Officer removed successfully"));
    }

    // ==================== Helper Methods ====================

    private boolean isValidPosition(String position) {
        for (String p : ClubOfficer.ALL_POSITIONS) {
            if (p.equals(position))
                return true;
        }
        return false;
    }

    private String getPositionDisplay(String position) {
        return switch (position) {
            case ClubOfficer.PRESIDENT -> "President (會長)";
            case ClubOfficer.VPE -> "VP Education (教育副會長)";
            case ClubOfficer.VPM -> "VP Membership (會籍副會長)";
            case ClubOfficer.VPPR -> "VP Public Relations (公關副會長)";
            case ClubOfficer.SECRETARY -> "Secretary (秘書)";
            case ClubOfficer.TREASURER -> "Treasurer (財務長)";
            case ClubOfficer.SAA -> "Sergeant at Arms (糾察)";
            default -> position;
        };
    }

    // ==================== Request DTOs ====================

    public record AssignOfficerRequest(
            @NotNull(message = "Position is required") String position,
            @NotNull(message = "Member ID is required") Long memberId,
            java.time.LocalDate termStart,
            java.time.LocalDate termEnd) {
    }
}
