package com.toastlabplus.controller;

import com.toastlabplus.dto.MemberDto;
import com.toastlabplus.entity.Club;
import com.toastlabplus.entity.ClubMembership;
import com.toastlabplus.entity.Member;
import com.toastlabplus.repository.ClubMembershipRepository;
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
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/club-memberships")
public class ClubMembershipController {

        private final ClubMembershipRepository clubMembershipRepository;
        private final ClubRepository clubRepository;
        private final MemberRepository memberRepository;

        public ClubMembershipController(
                        ClubMembershipRepository clubMembershipRepository,
                        ClubRepository clubRepository,
                        MemberRepository memberRepository) {
                this.clubMembershipRepository = clubMembershipRepository;
                this.clubRepository = clubRepository;
                this.memberRepository = memberRepository;
        }

        // ==================== 申請加入分會 ====================

        @PostMapping
        public ResponseEntity<?> applyForMembership(
                        @AuthenticationPrincipal UserDetails userDetails,
                        @Valid @RequestBody ApplyRequest request) {
                Member member = memberRepository.findByEmail(userDetails.getUsername())
                                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

                Club club = clubRepository.findById(request.clubId())
                                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

                if (clubMembershipRepository.existsByMemberIdAndClubId(member.getId(), club.getId())) {
                        return ResponseEntity.badRequest().body(Map.of(
                                        "error", "You have already applied to this club"));
                }

                ClubMembership membership = new ClubMembership();
                membership.setMember(member);
                membership.setClub(club);
                membership.setStatus("PENDING");
                membership.setCreatedAt(LocalDateTime.now());
                membership.setUpdatedAt(LocalDateTime.now());

                ClubMembership saved = clubMembershipRepository.save(membership);

                return ResponseEntity.ok(Map.of(
                                "message", "Application submitted successfully",
                                "membershipId", saved.getId(),
                                "clubName", club.getName(),
                                "status", saved.getStatus()));
        }

        // ==================== 查詢我的會員狀態 ====================

        @GetMapping("/my")
        public ResponseEntity<?> getMyMemberships(@AuthenticationPrincipal UserDetails userDetails) {
                Member member = memberRepository.findByEmail(userDetails.getUsername())
                                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

                List<Map<String, Object>> memberships = clubMembershipRepository.findByMemberId(member.getId())
                                .stream()
                                .map(m -> Map.<String, Object>of(
                                                "id", m.getId(),
                                                "clubId", m.getClub().getId(),
                                                "clubName", m.getClub().getName(),
                                                "status", m.getStatus(),
                                                "appliedAt", m.getCreatedAt().toString()))
                                .collect(Collectors.toList());

                return ResponseEntity.ok(memberships);
        }

        // ==================== 審核功能 (Club Admin) ====================

        @GetMapping("/club/{clubId}/pending")
        @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
        public ResponseEntity<?> getPendingMembers(@PathVariable Long clubId) {
                List<Map<String, Object>> pending = clubMembershipRepository.findByClubIdAndStatus(clubId, "PENDING")
                                .stream()
                                .map(m -> Map.<String, Object>of(
                                                "membershipId", m.getId(),
                                                "memberId", m.getMember().getId(),
                                                "memberName", m.getMember().getName(),
                                                "memberEmail", m.getMember().getEmail(),
                                                "appliedAt", m.getCreatedAt().toString()))
                                .collect(Collectors.toList());

                return ResponseEntity.ok(pending);
        }

        @GetMapping("/club/{clubId}")
        public ResponseEntity<?> getClubMemberships(
                        @PathVariable Long clubId,
                        @AuthenticationPrincipal UserDetails userDetails) {
                // Return all memberships for the club (frontend filters by status, but we could
                // filter here too)
                // Use MemberDto to avoid exposing sensitive info like password hash
                List<Map<String, Object>> memberships = clubMembershipRepository.findByClubId(clubId)
                                .stream()
                                .map(m -> Map.<String, Object>of(
                                                "id", m.getId(),
                                                "status", m.getStatus(),
                                                "joinedAt", m.getCreatedAt().toString(),
                                                "member", MemberDto.fromEntity(m.getMember())))
                                .collect(Collectors.toList());

                return ResponseEntity.ok(memberships);
        }

        @PatchMapping("/{id}/approve")
        @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
        public ResponseEntity<?> approveMembership(
                        @PathVariable Long id,
                        @AuthenticationPrincipal UserDetails userDetails) {
                ClubMembership membership = clubMembershipRepository.findById(id)
                                .orElseThrow(() -> new IllegalArgumentException("Membership not found"));

                Member approver = memberRepository.findByEmail(userDetails.getUsername())
                                .orElseThrow(() -> new IllegalArgumentException("Approver not found"));

                // Only update the club_membership record (not member table)
                membership.setStatus("APPROVED");
                membership.setApprovedBy(approver);
                membership.setApprovedAt(LocalDateTime.now());
                membership.setUpdatedAt(LocalDateTime.now());
                clubMembershipRepository.save(membership);

                return ResponseEntity.ok(Map.of(
                                "message", "Membership approved",
                                "membershipId", membership.getId(),
                                "memberName", membership.getMember().getName()));
        }

        @PatchMapping("/{id}/reject")
        @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
        public ResponseEntity<?> rejectMembership(
                        @PathVariable Long id,
                        @RequestBody(required = false) RejectRequest request) {
                ClubMembership membership = clubMembershipRepository.findById(id)
                                .orElseThrow(() -> new IllegalArgumentException("Membership not found"));

                membership.setStatus("REJECTED");
                membership.setRejectionReason(request != null ? request.reason() : null);
                membership.setUpdatedAt(LocalDateTime.now());

                clubMembershipRepository.save(membership);

                return ResponseEntity.ok(Map.of(
                                "message", "Membership rejected",
                                "membershipId", membership.getId()));
        }

        // ==================== 退出分會 ====================

        @DeleteMapping("/{id}")
        public ResponseEntity<?> leaveMembership(
                        @PathVariable Long id,
                        @AuthenticationPrincipal UserDetails userDetails) {
                Member member = memberRepository.findByEmail(userDetails.getUsername())
                                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

                ClubMembership membership = clubMembershipRepository.findById(id)
                                .orElseThrow(() -> new IllegalArgumentException("Membership not found"));

                // Only the member themselves can leave (or Platform Admin)
                if (!membership.getMember().getId().equals(member.getId()) &&
                                !"PLATFORM_ADMIN".equals(member.getRole())) {
                        return ResponseEntity.status(403).body(Map.of(
                                        "error", "You can only leave your own membership"));
                }

                clubMembershipRepository.delete(membership);

                return ResponseEntity.ok(Map.of(
                                "message", "Successfully left the club",
                                "clubName", membership.getClub().getName()));
        }

        // ==================== 取消申請 (by clubId) ====================

        @DeleteMapping("/club/{clubId}")
        public ResponseEntity<?> cancelApplication(
                        @PathVariable Long clubId,
                        @AuthenticationPrincipal UserDetails userDetails) {
                Member member = memberRepository.findByEmail(userDetails.getUsername())
                                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

                ClubMembership membership = clubMembershipRepository.findByMemberIdAndClubId(member.getId(), clubId)
                                .orElseThrow(() -> new IllegalArgumentException("Application not found"));

                // Only allow canceling PENDING applications
                if (!"PENDING".equals(membership.getStatus())) {
                        return ResponseEntity.badRequest().body(Map.of(
                                        "error", "Can only cancel pending applications"));
                }

                String clubName = membership.getClub().getName();
                clubMembershipRepository.delete(membership);

                return ResponseEntity.ok(Map.of(
                                "message", "Application cancelled",
                                "clubName", clubName));
        }

        // ==================== Request DTOs ====================

        public record ApplyRequest(@NotNull(message = "Club ID is required") Long clubId) {
        }

        public record RejectRequest(String reason) {
        }
}
