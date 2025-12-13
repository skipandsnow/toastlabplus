package com.toastlabplus.controller;

import com.toastlabplus.entity.Club;
import com.toastlabplus.repository.ClubRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/clubs")
@PreAuthorize("isAuthenticated()")
public class ClubController {

    @Autowired
    private ClubRepository clubRepository;

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
                    club.setUpdatedAt(java.time.LocalDateTime.now());
                    return ResponseEntity.ok(clubRepository.save(club));
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
