package com.toastlabplus.repository;

import com.toastlabplus.entity.Club;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ClubRepository extends JpaRepository<Club, Long> {
    List<Club> findByIsActiveTrue();
    List<Club> findByNameContainingIgnoreCase(String name);
}
