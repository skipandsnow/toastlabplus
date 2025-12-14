package com.toastlabplus.config;

import com.toastlabplus.entity.Member;
import com.toastlabplus.repository.MemberRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class DataInitializer implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(DataInitializer.class);

    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;

    // 從環境變數或 application.yml 讀取，預設值僅用於開發環境
    @Value("${app.admin.email:admin@toastlabplus.com}")
    private String adminEmail;

    @Value("${app.admin.password:#{null}}")
    private String adminPassword;

    public DataInitializer(MemberRepository memberRepository, PasswordEncoder passwordEncoder) {
        this.memberRepository = memberRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        initializePlatformAdmin();
    }

    private void initializePlatformAdmin() {
        if (memberRepository.findByEmail(adminEmail).isPresent()) {
            logger.info("✅ Platform Admin already exists: {}", adminEmail);
            return;
        }

        // 生產環境必須設定 ADMIN_PASSWORD 環境變數
        if (adminPassword == null || adminPassword.isBlank()) {
            logger.warn("⚠️ No admin password configured. Set ADMIN_PASSWORD environment variable.");
            logger.warn("⚠️ Using default password for development only!");
            adminPassword = "Admin@123";
        }

        Member admin = new Member();
        admin.setName("Platform Admin");
        admin.setEmail(adminEmail);
        admin.setPasswordHash(passwordEncoder.encode(adminPassword)); // BCrypt hash 儲存到資料庫
        admin.setRole("PLATFORM_ADMIN");
        admin.setCreatedAt(LocalDateTime.now());
        admin.setUpdatedAt(LocalDateTime.now());

        memberRepository.save(admin); // 儲存到資料庫
        logger.info("✅ Created Platform Admin: {} (password hashed with BCrypt and stored in database)", adminEmail);
    }
}
