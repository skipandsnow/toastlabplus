package com.toastlabplus.repository;

import com.toastlabplus.entity.Meeting;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface MeetingRepository extends JpaRepository<Meeting, Long> {
    List<Meeting> findByClubId(Long clubId);

    List<Meeting> findByClubIdAndStatus(Long clubId, String status);

    List<Meeting> findByClubIdAndMeetingDateAfter(Long clubId, LocalDate date);

    List<Meeting> findByClubIdOrderByMeetingDateDesc(Long clubId);

    List<Meeting> findByClubIdIn(List<Long> clubIds);

    List<Meeting> findByClubIdAndMeetingDateBetween(Long clubId, LocalDate startDate, LocalDate endDate);

    Optional<Meeting> findByIdAndClubId(Long id, Long clubId);

    List<Meeting> findByScheduleId(Long scheduleId);

    boolean existsByClubIdAndMeetingDate(Long clubId, LocalDate meetingDate);

    @Query("SELECT MAX(m.meetingNumber) FROM Meeting m WHERE m.club.id = :clubId")
    Optional<Integer> findMaxMeetingNumberByClubId(@Param("clubId") Long clubId);
}
