package com.toastlabplus.controller;

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

                // Check if already applied
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

        @PatchMapping("/{id}/approve")
        @PreAuthorize("hasAnyRole('CLUB_ADMIN', 'PLATFORM_ADMIN')")
        public ResponseEntity<?> approveMembership(
                        @PathVariable Long id,
                        @AuthenticationPrincipal UserDetails userDetails) {
                ClubMembership membership = clubMembershipRepository.findById(id)
                                .orElseThrow(() -> new IllegalArgumentException("Membership not found"));

                Member approver = memberRepository.findByEmail(userDetails.getUsername())
                                .orElseThrow(() -> new IllegalArgumentException("Approver not found"));

                membership.setStatus("APPROVED");
                membership.setApprovedBy(approver);
                membership.setApprovedAt(LocalDateTime.now());
                membership.setUpdatedAt(LocalDateTime.now());

                // Also update the member's club association
                Member member = membership.getMember();
                member.setClub(membership.getClub());
                member.setStatus("APPROVED");
                member.setApprovedBy(approver);
                member.setApprovedAt(LocalDateTime.now());
                memberRepository.save(member);

                clubMembershipRepository.save(membership);

                return ResponseEntity.ok(Map.of(
                                "message", "Membership approved",
                                "membershipId", membership.getId(),
                                "memberName", member.getName()));
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

                // If this was the member's active club, clear it
                if (member.getClub() != null && member.getClub().getId().equals(membership.getClub().getId())) {
                        member.setClub(null);
                        member.setStatus("REGISTERED");
                        memberRepository.save(member);
                }

                clubMembershipRepository.delete(membership);

                return ResponseEntity.ok(Map.of(
                                "message", "Successfully left the club",
                                "clubName", membership.getClub().getName()));
        }

        // ==================== Request DTOs ====================

        public record ApplyRequest(@NotNull(message = "Club ID is required") Long clubId) {
        }

        public record RejectRequest(String reason) {
        }
}
