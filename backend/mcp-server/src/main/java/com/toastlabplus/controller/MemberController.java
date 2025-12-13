package com.toastlabplus.controller;

import com.toastlabplus.dto.MemberDto;
import com.toastlabplus.entity.Member;
import com.toastlabplus.repository.MemberRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/members")
public class MemberController {

    private final MemberRepository memberRepository;

    public MemberController(MemberRepository memberRepository) {
        this.memberRepository = memberRepository;
    }

    /**
     * Get members of the current user's club only.
     * Platform Admin can see all members.
     */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getMembers(@AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        List<MemberDto> members;

        // Platform Admin can see all members
        if ("PLATFORM_ADMIN".equals(currentMember.getRole())) {
            members = memberRepository.findAll().stream()
                    .map(MemberDto::fromEntity)
                    .collect(Collectors.toList());
        } else if (currentMember.getClub() != null) {
            // Other users can only see members of their own club
            members = memberRepository.findByClubId(currentMember.getClub().getId()).stream()
                    .map(MemberDto::fromEntity)
                    .collect(Collectors.toList());
        } else {
            return ResponseEntity.ok(List.of());
        }

        return ResponseEntity.ok(members);
    }

    /**
     * Get a specific member by ID.
     * Can only view members of your own club.
     */
    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getMemberById(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        Member targetMember = memberRepository.findById(id).orElse(null);
        if (targetMember == null) {
            return ResponseEntity.notFound().build();
        }

        // Platform Admin can view any member
        if ("PLATFORM_ADMIN".equals(currentMember.getRole())) {
            return ResponseEntity.ok(MemberDto.fromEntity(targetMember));
        }

        // Check if target member is in the same club
        if (currentMember.getClub() != null && targetMember.getClub() != null &&
                currentMember.getClub().getId().equals(targetMember.getClub().getId())) {
            return ResponseEntity.ok(MemberDto.fromEntity(targetMember));
        }

        // Cannot view members from other clubs
        return ResponseEntity.status(403).body("Cannot view members from other clubs");
    }

    /**
     * Get members by club ID.
     * Only Club Admin/Platform Admin can access.
     */
    @GetMapping("/club/{clubId}")
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> getMembersByClub(
            @PathVariable Long clubId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        // Club Admin can only see their own club's members
        if ("CLUB_ADMIN".equals(currentMember.getRole())) {
            if (currentMember.getClub() == null || !currentMember.getClub().getId().equals(clubId)) {
                return ResponseEntity.status(403).body("Cannot view members from other clubs");
            }
        }

        List<MemberDto> members = memberRepository.findByClubId(clubId).stream()
                .map(MemberDto::fromEntity)
                .collect(Collectors.toList());

        return ResponseEntity.ok(members);
    }

    /**
     * Get pending members waiting for approval.
     * Only Club Admin/Platform Admin can access.
     */
    @GetMapping("/club/{clubId}/pending")
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> getPendingMembers(
            @PathVariable Long clubId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        // Club Admin can only see their own club's pending members
        if ("CLUB_ADMIN".equals(currentMember.getRole())) {
            if (currentMember.getClub() == null || !currentMember.getClub().getId().equals(clubId)) {
                return ResponseEntity.status(403).body("Cannot view members from other clubs");
            }
        }

        List<MemberDto> members = memberRepository.findByClubIdAndStatus(clubId, "PENDING").stream()
                .map(MemberDto::fromEntity)
                .collect(Collectors.toList());

        return ResponseEntity.ok(members);
    }
}
