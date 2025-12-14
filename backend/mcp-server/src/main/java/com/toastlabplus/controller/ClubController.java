package com.toastlabplus.controller;

import com.toastlabplus.entity.Club;
import com.toastlabplus.repository.ClubAdminRepository;
import com.toastlabplus.repository.ClubMembershipRepository;
import com.toastlabplus.repository.ClubRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/clubs")
@PreAuthorize("isAuthenticated()")
public class ClubController {

    @Autowired
    private ClubRepository clubRepository;

    @Autowired
    private ClubAdminRepository clubAdminRepository;

    @Autowired
    private ClubMembershipRepository clubMembershipRepository;

    @GetMapping
    public List<Club> getAllClubs() {
        return clubRepository.findByIsActiveTrue();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Club> getClubById(@PathVariable Long id) {
        return clubRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{id}/admins")
    public ResponseEntity<?> getClubAdmins(@PathVariable Long id) {
        List<Map<String, Object>> admins = clubAdminRepository.findByClubId(id).stream()
                .map(ca -> Map.<String, Object>of(
                        "memberId", ca.getMember().getId(),
                        "memberName", ca.getMember().getName(),
                        "memberEmail", ca.getMember().getEmail(),
                        "assignedAt", ca.getAssignedAt().toString()))
                .collect(Collectors.toList());
        return ResponseEntity.ok(admins);
    }

    @PostMapping
    @PreAuthorize("hasRole('PLATFORM_ADMIN')")
    public Club createClub(@RequestBody Club club) {
        return clubRepository.save(club);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('PLATFORM_ADMIN') or hasRole('CLUB_ADMIN')")
    public ResponseEntity<Club> updateClub(@PathVariable Long id, @RequestBody Club clubDetails) {
        return clubRepository.findById(id)
                .map(club -> {
                    club.setName(clubDetails.getName());
                    club.setDescription(clubDetails.getDescription());
                    club.setLocation(clubDetails.getLocation());
                    club.setMeetingDay(clubDetails.getMeetingDay());
                    club.setMeetingTime(clubDetails.getMeetingTime());
                    club.setContactEmail(clubDetails.getContactEmail());
                    club.setContactPhone(clubDetails.getContactPhone());
                    club.setContactPerson(clubDetails.getContactPerson());
                    club.setMeetingEndTime(clubDetails.getMeetingEndTime());
                    club.setUpdatedAt(java.time.LocalDateTime.now());
                    return ResponseEntity.ok(clubRepository.save(club));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('PLATFORM_ADMIN')")
    @Transactional
    public ResponseEntity<?> deleteClub(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {

        return clubRepository.findById(id)
                .map(club -> {
                    // Verify the club name matches for safety
                    String confirmName = body.get("confirmName");
                    if (confirmName == null || !confirmName.equals(club.getName())) {
                        return ResponseEntity.badRequest().body(Map.of(
                                "error",
                                "Club name does not match. Please enter the exact club name to confirm deletion."));
                    }

                    String clubName = club.getName();

                    // Delete all related data
                    clubMembershipRepository.deleteByClubId(id);
                    clubAdminRepository.deleteByClubId(id);
                    clubRepository.delete(club);

                    return ResponseEntity.ok(Map.of(
                            "message", "Club '" + clubName + "' and all related data deleted successfully"));
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
