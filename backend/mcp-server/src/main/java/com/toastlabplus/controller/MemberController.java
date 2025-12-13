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
     * The image is stored in GCP Cloud Storage.
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
                    "message", "GCP Storage is not configured. Set GCP_STORAGE_ENABLED=true and provide credentials."));
        }

        Member member = memberRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        // Security check: only allow updating own avatar
        if (!member.getEmail().equals(userDetails.getUsername())) {
            return ResponseEntity.status(403).body(java.util.Map.of("error", "Can only update your own avatar"));
        }

        try {
            // Delete old avatar if exists
            if (member.getAvatarUrl() != null) {
                storageService.deleteFile(member.getAvatarUrl());
            }

            String avatarUrl = storageService.uploadFile(file, "avatars");
            member.setAvatarUrl(avatarUrl);
            memberRepository.save(member);

            return ResponseEntity.ok(java.util.Map.of("avatarUrl", avatarUrl));
        } catch (java.io.IOException e) {
            return ResponseEntity.internalServerError().body(java.util.Map.of(
                    "error", "Failed to upload avatar",
                    "message", e.getMessage()));
        }
    }

    /**
     * Assign a member as Club Admin for a specific club.
     * Only Platform Admin can perform this.
     * This also adds them as a member of the club if not already.
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

        // Check if already admin of this club
        if (clubAdminRepository.existsByMemberIdAndClubId(id, clubId)) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", "Already admin of this club"));
        }

        // Get current user for assigned_by
        Member currentUser = memberRepository.findByEmail(userDetails.getUsername())
                .orElse(null);

        // Create ClubAdmin record
        ClubAdmin clubAdmin = new ClubAdmin(member, club, currentUser);
        clubAdminRepository.save(clubAdmin);

        // Set member.role = CLUB_ADMIN for Spring Security @PreAuthorize compatibility
        // Also set member.club to this club (will be the "primary" club for this admin)
        if (!"PLATFORM_ADMIN".equals(member.getRole())) {
            member.setRole("CLUB_ADMIN");
            member.setClub(club);
            member.setStatus("APPROVED");
            memberRepository.save(member);
        }

        // Auto-create ClubMembership if not exists (APPROVED status)
        if (!clubMembershipRepository.existsByMemberIdAndClubId(id, clubId)) {
            ClubMembership membership = new ClubMembership();
            membership.setMember(member);
            membership.setClub(club);
            membership.setStatus("APPROVED");
            clubMembershipRepository.save(membership);
        }

        // Get updated admin club IDs
        List<Long> adminClubIds = clubAdminRepository.findByMemberId(id).stream()
                .map(ca -> ca.getClub().getId())
                .collect(Collectors.toList());

        return ResponseEntity.ok(MemberDto.fromEntity(member, adminClubIds));
    }

    /**
     * Remove Club Admin role from a member for a specific club.
     * Only Platform Admin can perform this.
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

        // Check if actually admin of this club
        if (!clubAdminRepository.existsByMemberIdAndClubId(id, clubId)) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", "Not admin of this club"));
        }

        // Remove ClubAdmin record
        clubAdminRepository.deleteByMemberIdAndClubId(id, clubId);

        // Get updated admin club IDs
        List<Long> adminClubIds = clubAdminRepository.findByMemberId(id).stream()
                .map(ca -> ca.getClub().getId())
                .collect(Collectors.toList());

        // If no more clubs to admin, reset role to MEMBER
        if (adminClubIds.isEmpty() && "CLUB_ADMIN".equals(member.getRole())) {
            member.setRole("MEMBER");
            member.setClub(null);
            memberRepository.save(member);
        }

        return ResponseEntity.ok(MemberDto.fromEntity(member, adminClubIds));
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
