package com.toastlabplus.repository;

import com.toastlabplus.entity.Meeting;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface MeetingRepository extends JpaRepository<Meeting, Long> {
    List<Meeting> findByClubId(Long clubId);

    List<Meeting> findByClubIdAndStatus(Long clubId, String status);

    List<Meeting> findByClubIdAndMeetingDateAfter(Long clubId, LocalDate date);

    List<Meeting> findByClubIdOrderByMeetingDateDesc(Long clubId);

    List<Meeting> findByClubIdIn(List<Long> clubIds);
}
