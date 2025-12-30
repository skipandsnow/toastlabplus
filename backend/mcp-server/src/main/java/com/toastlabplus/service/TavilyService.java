package com.toastlabplus.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Service for Tavily Web Search API integration.
 * Provides AI-optimized web search capabilities for the MCP tools.
 */
@Service
public class TavilyService {

    @Value("${tavily.api.key:}")
    private String apiKey;

    @Value("${tavily.api.url:https://api.tavily.com}")
    private String apiUrl;

    private final RestClient restClient;

    public TavilyService() {
        this.restClient = RestClient.create();
    }

    /**
     * Check if Tavily API is properly configured.
     */
    public boolean isConfigured() {
        return apiKey != null && !apiKey.isEmpty() && !apiKey.startsWith("${");
    }

    /**
     * Perform a web search using Tavily API.
     *
     * @param query      The search query
     * @param maxResults Maximum number of results (1-10, default 5)
     * @param topic      Search topic: "general" or "news"
     * @return Search results including answer and source URLs
     */
    @SuppressWarnings("unchecked")
    public Map<String, Object> search(String query, Integer maxResults, String topic) {
        Map<String, Object> result = new HashMap<>();

        if (!isConfigured()) {
            result.put("success", false);
            result.put("error", "Tavily API key not configured");
            return result;
        }

        try {
            // Build request body
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("query", query);
            requestBody.put("max_results", maxResults != null ? Math.min(maxResults, 10) : 5);
            requestBody.put("topic", topic != null ? topic : "general");
            requestBody.put("include_answer", true);
            requestBody.put("search_depth", "basic"); // Use basic to save credits

            // Make API call using RestClient
            Map<String, Object> response = restClient.post()
                    .uri(apiUrl + "/search")
                    .contentType(MediaType.APPLICATION_JSON)
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + apiKey)
                    .body(requestBody)
                    .retrieve()
                    .body(Map.class);

            if (response != null) {
                result.put("success", true);
                result.put("query", response.get("query"));
                result.put("answer", response.get("answer"));

                // Extract and format results
                List<Map<String, Object>> results = (List<Map<String, Object>>) response.get("results");
                if (results != null) {
                    result.put("results", results.stream()
                            .map(r -> Map.of(
                                    "title", r.getOrDefault("title", ""),
                                    "url", r.getOrDefault("url", ""),
                                    "content", r.getOrDefault("content", ""),
                                    "score", r.getOrDefault("score", 0.0)))
                            .toList());
                    result.put("resultCount", results.size());
                }

                result.put("responseTime", response.get("response_time"));
            } else {
                result.put("success", false);
                result.put("error", "Empty response from Tavily API");
            }

        } catch (Exception e) {
            result.put("success", false);
            result.put("error", "Search failed: " + e.getMessage());
        }

        return result;
    }
}
