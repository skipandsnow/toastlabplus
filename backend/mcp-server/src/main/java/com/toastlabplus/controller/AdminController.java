package com.toastlabplus.controller;

import com.toastlabplus.dto.MemberDto;
import com.toastlabplus.entity.Club;
import com.toastlabplus.entity.Member;
import com.toastlabplus.repository.ClubRepository;
import com.toastlabplus.repository.MemberRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class AdminController {

        private final ClubRepository clubRepository;
        private final MemberRepository memberRepository;

        public AdminController(ClubRepository clubRepository, MemberRepository memberRepository) {
                this.clubRepository = clubRepository;
                this.memberRepository = memberRepository;
        }

        // ==================== Club Management ====================

        @PostMapping("/clubs")
        public ResponseEntity<?> createClub(@Valid @RequestBody CreateClubRequest request) {
                Club club = new Club();
                club.setName(request.name());
                club.setDescription(request.description());
                club.setCreatedAt(LocalDateTime.now());
                club.setUpdatedAt(LocalDateTime.now());

                Club saved = clubRepository.save(club);
                return ResponseEntity.ok(Map.of(
                                "message", "Club created successfully",
                                "clubId", saved.getId(),
                                "name", saved.getName()));
        }

        @GetMapping("/clubs")
        public ResponseEntity<List<Club>> getAllClubs() {
                return ResponseEntity.ok(clubRepository.findAll());
        }

        @PatchMapping("/clubs/{id}")
        public ResponseEntity<?> updateClub(
                        @PathVariable Long id,
                        @RequestBody Map<String, String> updates) {
                Club club = clubRepository.findById(id)
                                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

                if (updates.containsKey("name")) {
                        club.setName(updates.get("name"));
                }
                if (updates.containsKey("description")) {
                        club.setDescription(updates.get("description"));
                }
                club.setUpdatedAt(LocalDateTime.now());

                Club saved = clubRepository.save(club);
                return ResponseEntity.ok(Map.of(
                                "message", "Club updated successfully",
                                "clubId", saved.getId(),
                                "name", saved.getName()));
        }

        // ==================== Member Management ====================

        @GetMapping("/members")
        public ResponseEntity<List<MemberDto>> getAllMembers() {
                List<MemberDto> members = memberRepository.findAll().stream()
                                .map(MemberDto::fromEntity)
                                .collect(Collectors.toList());
                return ResponseEntity.ok(members);
        }

        /**
         * Update member role. Only PLATFORM_ADMIN or MEMBER are valid.
         * CLUB_ADMIN is now assigned via /api/members/{id}/assign-club-admin
         */
        @PatchMapping("/members/{id}/role")
        public ResponseEntity<?> updateMemberRole(
                        @PathVariable Long id,
                        @Valid @RequestBody UpdateRoleRequest request) {
                Member member = memberRepository.findById(id)
                                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

                // Only PLATFORM_ADMIN and MEMBER are valid base roles
                // CLUB_ADMIN is determined by club_admin table
                List<String> validRoles = List.of("MEMBER", "PLATFORM_ADMIN");
                if (!validRoles.contains(request.role())) {
                        return ResponseEntity.badRequest().body(Map.of(
                                        "error", "Invalid role. Valid roles: " + validRoles,
                                        "hint", "To assign Club Admin, use PUT /api/members/{id}/assign-club-admin"));
                }

                member.setRole(request.role());
                member.setUpdatedAt(LocalDateTime.now());
                memberRepository.save(member);

                return ResponseEntity.ok(Map.of(
                                "message", "Role updated successfully",
                                "memberId", member.getId(),
                                "newRole", member.getRole()));
        }

        // ==================== Request DTOs ====================

        public record CreateClubRequest(
                        @NotBlank(message = "Club name is required") String name,
                        String description) {
        }

        public record UpdateRoleRequest(
                        @NotBlank(message = "Role is required") String role) {
        }
}
