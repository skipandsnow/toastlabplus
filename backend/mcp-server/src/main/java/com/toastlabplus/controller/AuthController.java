package com.toastlabplus.controller;

import com.toastlabplus.dto.*;
import com.toastlabplus.entity.Member;
import com.toastlabplus.service.AuthService;
import com.toastlabplus.service.JwtService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final JwtService jwtService;

    public AuthController(AuthService authService, JwtService jwtService) {
        this.authService = authService;
        this.jwtService = jwtService;
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

            AuthResponse response = new AuthResponse(
                    token,
                    jwtService.getExpiration(),
                    MemberDto.fromEntity(member));
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
            return ResponseEntity.ok(MemberDto.fromEntity(member));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).body(Map.of("error", e.getMessage()));
        }
    }
}
