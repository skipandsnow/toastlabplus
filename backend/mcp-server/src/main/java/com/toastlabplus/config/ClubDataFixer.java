package com.toastlabplus.config;

import com.toastlabplus.entity.Club;
import com.toastlabplus.repository.ClubRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Fixes garbled club names from terminal encoding issues.
 * This runs after DataInitializer.
 */
@Component
@Order(2)
public class ClubDataFixer implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(ClubDataFixer.class);

    private final ClubRepository clubRepository;

    // Map of club IDs to correct names/descriptions
    private static final Map<Long, String[]> CLUB_FIXES = Map.of(
            3L, new String[] { "台北中央分會", "台北市最大的國際演講會分會" },
            4L, new String[] { "新竹科學園區分會", "科技人的演講舞台" });

    public ClubDataFixer(ClubRepository clubRepository) {
        this.clubRepository = clubRepository;
    }

    @Override
    @Transactional
    public void run(String... args) {
        logger.info("Running ClubDataFixer...");

        for (Map.Entry<Long, String[]> entry : CLUB_FIXES.entrySet()) {
            Long clubId = entry.getKey();
            String correctName = entry.getValue()[0];
            String correctDesc = entry.getValue()[1];

            clubRepository.findById(clubId).ifPresent(club -> {
                // Only fix if the name looks garbled (contains ? or is not the correct name)
                if (!correctName.equals(club.getName())) {
                    logger.info("Fixing club {}: {} -> {}", clubId, club.getName(), correctName);
                    club.setName(correctName);
                    club.setDescription(correctDesc);
                    club.setUpdatedAt(LocalDateTime.now());
                    clubRepository.save(club);
                }
            });
        }

        logger.info("ClubDataFixer completed.");
    }
}
