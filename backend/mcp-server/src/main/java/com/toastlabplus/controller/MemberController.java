package com.toastlabplus.controller;

import com.toastlabplus.dto.MemberDto;
import com.toastlabplus.entity.ClubAdmin;
import com.toastlabplus.entity.ClubMembership;
import com.toastlabplus.entity.Member;
import com.toastlabplus.repository.ClubAdminRepository;
import com.toastlabplus.repository.ClubMembershipRepository;
import com.toastlabplus.repository.MemberRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/members")
public class MemberController {

    private final MemberRepository memberRepository;
    private final com.toastlabplus.repository.ClubRepository clubRepository;
    private final ClubAdminRepository clubAdminRepository;
    private final ClubMembershipRepository clubMembershipRepository;
    private com.toastlabplus.service.StorageService storageService;

    public MemberController(MemberRepository memberRepository,
            com.toastlabplus.repository.ClubRepository clubRepository,
            ClubAdminRepository clubAdminRepository,
            ClubMembershipRepository clubMembershipRepository) {
        this.memberRepository = memberRepository;
        this.clubRepository = clubRepository;
        this.clubAdminRepository = clubAdminRepository;
        this.clubMembershipRepository = clubMembershipRepository;
    }

    @org.springframework.beans.factory.annotation.Autowired(required = false)
    public void setStorageService(com.toastlabplus.service.StorageService storageService) {
        this.storageService = storageService;
    }

    /**
     * Upload avatar image for a member.
     */
    @PostMapping(value = "/{id}/avatar", consumes = org.springframework.http.MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> uploadAvatar(
            @PathVariable Long id,
            @RequestParam("file") org.springframework.web.multipart.MultipartFile file,
            @AuthenticationPrincipal UserDetails userDetails) {

        if (storageService == null) {
            return ResponseEntity.status(503).body(java.util.Map.of(
                    "error", "Avatar upload is not available",
                    "message", "GCP Storage is not configured."));
        }

        Member member = memberRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        if (!member.getEmail().equals(userDetails.getUsername())) {
            return ResponseEntity.status(403).body(java.util.Map.of("error", "Can only update your own avatar"));
        }

        try {
            if (member.getAvatarUrl() != null) {
                storageService.deleteFile(member.getAvatarUrl());
            }
            String avatarUrl = storageService.uploadFile(file, "avatars");
            member.setAvatarUrl(avatarUrl);
            memberRepository.save(member);
            return ResponseEntity.ok(java.util.Map.of("avatarUrl", avatarUrl));
        } catch (java.io.IOException e) {
            return ResponseEntity.internalServerError().body(java.util.Map.of(
                    "error", "Failed to upload avatar", "message", e.getMessage()));
        }
    }

    /**
     * Assign a member as Club Admin for a specific club.
     * Only Platform Admin can perform this.
     */
    @PutMapping("/{id}/assign-club-admin")
    @PreAuthorize("hasRole('PLATFORM_ADMIN')")
    @Transactional
    public ResponseEntity<?> assignClubAdmin(
            @PathVariable Long id,
            @RequestBody java.util.Map<String, Long> requestBody,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long clubId = requestBody.get("clubId");
        if (clubId == null) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", "clubId is required"));
        }

        Member member = memberRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        com.toastlabplus.entity.Club club = clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        if (clubAdminRepository.existsByMemberIdAndClubId(id, clubId)) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", "Already admin of this club"));
        }

        Member currentUser = memberRepository.findByEmail(userDetails.getUsername()).orElse(null);

        // Create ClubAdmin record (this is the only thing needed now)
        ClubAdmin clubAdmin = new ClubAdmin(member, club, currentUser);
        clubAdminRepository.save(clubAdmin);

        // Auto-create ClubMembership if not exists
        if (!clubMembershipRepository.existsByMemberIdAndClubId(id, clubId)) {
            ClubMembership membership = new ClubMembership();
            membership.setMember(member);
            membership.setClub(club);
            membership.setStatus("APPROVED");
            clubMembershipRepository.save(membership);
        }

        return ResponseEntity.ok(MemberDto.fromEntity(member, getAdminClubIds(id)));
    }

    /**
     * Remove Club Admin role from a member for a specific club.
     */
    @PutMapping("/{id}/remove-club-admin")
    @PreAuthorize("hasRole('PLATFORM_ADMIN')")
    @Transactional
    public ResponseEntity<?> removeClubAdmin(
            @PathVariable Long id,
            @RequestBody java.util.Map<String, Long> requestBody) {
        Long clubId = requestBody.get("clubId");
        if (clubId == null) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", "clubId is required"));
        }

        Member member = memberRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        if (!clubAdminRepository.existsByMemberIdAndClubId(id, clubId)) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", "Not admin of this club"));
        }

        clubAdminRepository.deleteByMemberIdAndClubId(id, clubId);
        return ResponseEntity.ok(MemberDto.fromEntity(member, getAdminClubIds(id)));
    }

    /**
     * Get all members (for Platform Admin).
     */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getMembers(@AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        if ("PLATFORM_ADMIN".equals(currentMember.getRole())) {
            List<MemberDto> members = memberRepository.findAll().stream()
                    .map(MemberDto::fromEntity)
                    .collect(Collectors.toList());
            return ResponseEntity.ok(members);
        }
        return ResponseEntity.ok(List.of());
    }

    /**
     * Get a specific member by ID.
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

        if ("PLATFORM_ADMIN".equals(currentMember.getRole())) {
            return ResponseEntity.ok(MemberDto.fromEntity(targetMember));
        }

        // Check if they share at least one club membership
        List<Long> currentMemberClubs = clubMembershipRepository.findByMemberId(currentMember.getId()).stream()
                .filter(m -> "APPROVED".equals(m.getStatus()))
                .map(m -> m.getClub().getId())
                .collect(Collectors.toList());
        List<Long> targetMemberClubs = clubMembershipRepository.findByMemberId(targetMember.getId()).stream()
                .filter(m -> "APPROVED".equals(m.getStatus()))
                .map(m -> m.getClub().getId())
                .collect(Collectors.toList());

        if (currentMemberClubs.stream().anyMatch(targetMemberClubs::contains)) {
            return ResponseEntity.ok(MemberDto.fromEntity(targetMember));
        }
        return ResponseEntity.status(403).body("Cannot view members from other clubs");
    }

    /**
     * Get members by club ID.
     */
    @GetMapping("/club/{clubId}")
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> getMembersByClub(
            @PathVariable Long clubId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        if (!"PLATFORM_ADMIN".equals(currentMember.getRole())) {
            if (!clubAdminRepository.existsByMemberIdAndClubId(currentMember.getId(), clubId)) {
                return ResponseEntity.status(403).body("Cannot view members from clubs you don't manage");
            }
        }

        List<MemberDto> members = clubMembershipRepository.findByClubId(clubId).stream()
                .filter(m -> "APPROVED".equals(m.getStatus()))
                .map(m -> MemberDto.fromEntity(m.getMember()))
                .collect(Collectors.toList());
        return ResponseEntity.ok(members);
    }

    /**
     * Get pending members waiting for approval.
     */
    @GetMapping("/club/{clubId}/pending")
    @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
    public ResponseEntity<?> getPendingMembers(
            @PathVariable Long clubId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Member currentMember = memberRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        if (!"PLATFORM_ADMIN".equals(currentMember.getRole())) {
            if (!clubAdminRepository.existsByMemberIdAndClubId(currentMember.getId(), clubId)) {
                return ResponseEntity.status(403).body("Cannot view members from clubs you don't manage");
            }
        }

        List<MemberDto> members = clubMembershipRepository.findByClubIdAndStatus(clubId, "PENDING").stream()
                .map(m -> MemberDto.fromEntity(m.getMember()))
                .collect(Collectors.toList());
        return ResponseEntity.ok(members);
    }

    private List<Long> getAdminClubIds(Long memberId) {
        return clubAdminRepository.findByMemberId(memberId).stream()
                .map(ca -> ca.getClub().getId())
                .collect(Collectors.toList());
    }
}
