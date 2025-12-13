package com.toastlabplus.controller;

import com.toastlabplus.dto.*;
import com.toastlabplus.entity.ClubAdmin;
import com.toastlabplus.entity.Member;
import com.toastlabplus.repository.ClubAdminRepository;
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

    public AuthController(AuthService authService, JwtService jwtService, ClubAdminRepository clubAdminRepository) {
        this.authService = authService;
        this.jwtService = jwtService;
        this.clubAdminRepository = clubAdminRepository;
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

            // Get admin club IDs
            List<Long> adminClubIds = getAdminClubIds(member.getId());

            AuthResponse response = new AuthResponse(
                    token,
                    jwtService.getExpiration(),
                    MemberDto.fromEntity(member, adminClubIds));
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
            return ResponseEntity.ok(MemberDto.fromEntity(member, adminClubIds));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).body(Map.of("error", e.getMessage()));
        }
    }

    private List<Long> getAdminClubIds(Long memberId) {
        return clubAdminRepository.findByMemberId(memberId).stream()
                .map(ca -> ca.getClub().getId())
                .collect(Collectors.toList());
    }
}
