package com.toastlabplus.repository;

import com.toastlabplus.entity.MeetingSchedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MeetingScheduleRepository extends JpaRepository<MeetingSchedule, Long> {

    List<MeetingSchedule> findByClubId(Long clubId);

    List<MeetingSchedule> findByClubIdAndIsActiveTrue(Long clubId);

    Optional<MeetingSchedule> findByIdAndClubId(Long id, Long clubId);

    List<MeetingSchedule> findByIsActiveTrue();
}
