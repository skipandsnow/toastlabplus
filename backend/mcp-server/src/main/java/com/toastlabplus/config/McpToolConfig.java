package com.toastlabplus.config;

import com.toastlabplus.mcp.McpToolService;
import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.ai.tool.method.MethodToolCallbackProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration for MCP Server tools.
 * Registers the McpToolService with the MCP Server's tool system.
 */
@Configuration
public class McpToolConfig {

    @Bean
    public ToolCallbackProvider mcpToolCallbackProvider(McpToolService mcpToolService) {
        return MethodToolCallbackProvider.builder()
                .toolObjects(mcpToolService)
                .build();
    }
}
