package com.toastlabplus.controller;

import com.toastlabplus.dto.*;
import com.toastlabplus.entity.Member;
import com.toastlabplus.repository.ClubAdminRepository;
import com.toastlabplus.repository.ClubMembershipRepository;
import com.toastlabplus.service.AuthService;
import com.toastlabplus.service.JwtService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final JwtService jwtService;
    private final ClubAdminRepository clubAdminRepository;
    private final ClubMembershipRepository clubMembershipRepository;

    public AuthController(AuthService authService, JwtService jwtService,
            ClubAdminRepository clubAdminRepository, ClubMembershipRepository clubMembershipRepository) {
        this.authService = authService;
        this.jwtService = jwtService;
        this.clubAdminRepository = clubAdminRepository;
        this.clubMembershipRepository = clubMembershipRepository;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        try {
            Member member = authService.register(
                    request.getName(),
                    request.getEmail(),
                    request.getPassword());
            return ResponseEntity.ok(Map.of(
                    "message", "Registration successful",
                    "memberId", member.getId()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        try {
            String token = authService.login(request.getEmail(), request.getPassword());
            Member member = authService.getMemberByEmail(request.getEmail());

            List<Long> adminClubIds = getAdminClubIds(member.getId());
            List<Long> memberClubIds = getMemberClubIds(member.getId());
            List<Long> pendingClubIds = getPendingClubIds(member.getId());

            AuthResponse response = new AuthResponse(
                    token,
                    jwtService.getExpiration(),
                    MemberDto.fromEntity(member, adminClubIds, memberClubIds, pendingClubIds));
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(@AuthenticationPrincipal UserDetails userDetails) {
        if (userDetails == null) {
            return ResponseEntity.status(401).body(Map.of("error", "Not authenticated"));
        }

        try {
            Member member = authService.getMemberByEmail(userDetails.getUsername());
            List<Long> adminClubIds = getAdminClubIds(member.getId());
            List<Long> memberClubIds = getMemberClubIds(member.getId());
            List<Long> pendingClubIds = getPendingClubIds(member.getId());
            return ResponseEntity.ok(MemberDto.fromEntity(member, adminClubIds, memberClubIds, pendingClubIds));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/change-password")
    public ResponseEntity<?> changePassword(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody ChangePasswordRequest request) {
        if (userDetails == null) {
            return ResponseEntity.status(401).body(Map.of("error", "Not authenticated"));
        }

        try {
            authService.changePassword(
                    userDetails.getUsername(),
                    request.currentPassword(),
                    request.newPassword());
            return ResponseEntity.ok(Map.of("message", "Password changed successfully"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
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

    // Request DTO
    public record ChangePasswordRequest(
            @jakarta.validation.constraints.NotBlank(message = "Current password is required") String currentPassword,
            @jakarta.validation.constraints.NotBlank(message = "New password is required") @jakarta.validation.constraints.Size(min = 6, message = "Password must be at least 6 characters") String newPassword) {
    }
}
