package com.toastlabplus;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import com.google.cloud.spring.autoconfigure.core.GcpContextAutoConfiguration;

@SpringBootApplication(exclude = { GcpContextAutoConfiguration.class })
public class McpServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(McpServerApplication.class, args);
    }
}
