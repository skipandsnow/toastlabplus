package com.toastlabplus.controller;

import com.toastlabplus.dto.AuthResponse;
import com.toastlabplus.dto.MemberDto;
import com.toastlabplus.entity.Member;
import com.toastlabplus.repository.ClubAdminRepository;
import com.toastlabplus.repository.ClubMembershipRepository;
import com.toastlabplus.repository.MemberRepository;
import com.toastlabplus.service.JwtService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Controller for Firebase Authentication.
 * Handles login/registration via Firebase ID Token.
 */
@RestController
@RequestMapping("/api/auth/firebase")
public class FirebaseAuthController {

    private final MemberRepository memberRepository;
    private final JwtService jwtService;
    private final ClubAdminRepository clubAdminRepository;
    private final ClubMembershipRepository clubMembershipRepository;

    public FirebaseAuthController(MemberRepository memberRepository,
            JwtService jwtService,
            ClubAdminRepository clubAdminRepository,
            ClubMembershipRepository clubMembershipRepository) {
        this.memberRepository = memberRepository;
        this.jwtService = jwtService;
        this.clubAdminRepository = clubAdminRepository;
        this.clubMembershipRepository = clubMembershipRepository;
    }

    /**
     * Login or register using Firebase ID Token.
     * The frontend should verify the token with Firebase first,
     * then send the verified user info to this endpoint.
     */
    @PostMapping
    public ResponseEntity<?> firebaseAuth(@RequestBody FirebaseAuthRequest request) {
        if (request.firebaseUid() == null || request.firebaseUid().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "firebaseUid is required"));
        }
        if (request.email() == null || request.email().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "email is required"));
        }
        if (request.provider() == null || request.provider().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "provider is required"));
        }

        try {
            // Try to find existing member by Firebase UID
            Member member = memberRepository.findByFirebaseUid(request.firebaseUid()).orElse(null);

            if (member == null) {
                // Try to find by email (might be existing user linking social account)
                member = memberRepository.findByEmail(request.email()).orElse(null);

                if (member != null) {
                    // Existing user - update with Firebase info
                    member.setFirebaseUid(request.firebaseUid());
                    member.setAuthProvider(request.provider().toUpperCase());
                    if (request.name() != null && !request.name().isBlank()) {
                        member.setName(request.name());
                    }
                    member = memberRepository.save(member);
                } else {
                    // New user - create account
                    member = new Member();
                    member.setEmail(request.email());
                    member.setName(request.name() != null ? request.name() : "User");
                    member.setFirebaseUid(request.firebaseUid());
                    member.setAuthProvider(request.provider().toUpperCase());
                    member.setRole("MEMBER");
                    // Password is null for social login users
                    member = memberRepository.save(member);
                }
            } else {
                // Update name if provided and different
                if (request.name() != null && !request.name().isBlank()
                        && !request.name().equals(member.getName())) {
                    member.setName(request.name());
                    member = memberRepository.save(member);
                }
            }

            // Generate JWT token
            String token = jwtService.generateToken(member.getEmail(), member.getRole(), member.getId());

            // Get club info
            List<Long> adminClubIds = getAdminClubIds(member.getId());
            List<Long> memberClubIds = getMemberClubIds(member.getId());
            List<Long> pendingClubIds = getPendingClubIds(member.getId());

            AuthResponse response = new AuthResponse(
                    token,
                    jwtService.getExpiration(),
                    MemberDto.fromEntity(member, adminClubIds, memberClubIds, pendingClubIds));

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Authentication failed: " + e.getMessage()));
        }
    }

    private List<Long> getAdminClubIds(Long memberId) {
        return clubAdminRepository.findByMemberId(memberId).stream()
                .map(ca -> ca.getClub().getId())
                .collect(Collectors.toList());
    }

    private List<Long> getMemberClubIds(Long memberId) {
        return clubMembershipRepository.findByMemberId(memberId).stream()
                .filter(m -> "APPROVED".equals(m.getStatus()))
                .map(m -> m.getClub().getId())
                .collect(Collectors.toList());
    }

    private List<Long> getPendingClubIds(Long memberId) {
        return clubMembershipRepository.findByMemberId(memberId).stream()
                .filter(m -> "PENDING".equals(m.getStatus()))
                .map(m -> m.getClub().getId())
                .collect(Collectors.toList());
    }

    /**
     * Request DTO for Firebase authentication.
     */
    public record FirebaseAuthRequest(
            String firebaseUid,
            String email,
            String name,
            String provider // GOOGLE, FACEBOOK, etc.
    ) {
    }
}
