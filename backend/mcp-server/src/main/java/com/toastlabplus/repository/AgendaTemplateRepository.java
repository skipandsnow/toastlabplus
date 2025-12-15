package com.toastlabplus.repository;

import com.toastlabplus.entity.AgendaTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AgendaTemplateRepository extends JpaRepository<AgendaTemplate, Long> {

    List<AgendaTemplate> findByClubId(Long clubId);

    List<AgendaTemplate> findByClubIdAndIsActiveTrue(Long clubId);

    Optional<AgendaTemplate> findByIdAndClubId(Long id, Long clubId);

    boolean existsByClubIdAndName(Long clubId, String name);
}
