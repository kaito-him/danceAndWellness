package com.example.demo.services;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Service to integrate with Python recommendation system
 */
@Service
@Slf4j
public class RecommendationService {

    @Value("${recommendation.api.url:http://localhost:5000}")
    private String recommendationApiUrl;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public RecommendationService() {
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }

    /**
     * Get course recommendations for a student
     */
    public List<CourseRecommendation> getRecommendations(Long studentId, Integer topN) {
        try {
            String url = String.format("%s/recommend/%d?top_n=%d", 
                recommendationApiUrl, studentId, topN != null ? topN : 10);
            
            log.info("Fetching recommendations for student {} from {}", studentId, url);
            
            ResponseEntity<RecommendationResponse> response = restTemplate.getForEntity(
                url, RecommendationResponse.class);
            
            if (response.getBody() != null) {
                log.info("Received {} recommendations for student {}", 
                    response.getBody().getRecommendations().size(), studentId);
                return response.getBody().getRecommendations();
            }
            
            return new ArrayList<>();
            
        } catch (Exception e) {
            log.error("Error fetching recommendations for student {}: {}", studentId, e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * Get similar courses for a given course
     */
    public List<SimilarCourse> getSimilarCourses(Long courseId, Integer topN) {
        try {
            String url = String.format("%s/similar-courses/%d?top_n=%d", 
                recommendationApiUrl, courseId, topN != null ? topN : 5);
            
            log.info("Fetching similar courses for course {} from {}", courseId, url);
            
            ResponseEntity<SimilarCoursesResponse> response = restTemplate.getForEntity(
                url, SimilarCoursesResponse.class);
            
            if (response.getBody() != null) {
                return response.getBody().getSimilarCourses();
            }
            
            return new ArrayList<>();
            
        } catch (Exception e) {
            log.error("Error fetching similar courses for course {}: {}", courseId, e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * Refresh the recommendation system
     * Call this when:
     * - New course is published
     * - Course is archived
     * - Student enrolls/unenrolls
     * - Student completes lessons
     */
    @Async
    public void refreshRecommendations() {
        try {
            String url = recommendationApiUrl + "/refresh";
            
            log.info("Triggering recommendation system refresh at {}", url);
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            
            HttpEntity<String> request = new HttpEntity<>("{}", headers);
            
            ResponseEntity<Map> response = restTemplate.postForEntity(url, request, Map.class);
            
            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("Recommendation system refreshed successfully");
            } else {
                log.warn("Recommendation refresh returned status: {}", response.getStatusCode());
            }
            
        } catch (Exception e) {
            log.error("Error refreshing recommendations: {}", e.getMessage());
        }
    }

    /**
     * Get batch recommendations for multiple students
     */
    public Map<Long, List<CourseRecommendation>> getBatchRecommendations(List<Long> studentIds, Integer topN) {
        try {
            String url = recommendationApiUrl + "/batch-recommend";
            
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("student_ids", studentIds);
            requestBody.put("top_n", topN != null ? topN : 10);
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            
            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);
            
            ResponseEntity<BatchRecommendationResponse> response = restTemplate.postForEntity(
                url, request, BatchRecommendationResponse.class);
            
            if (response.getBody() != null) {
                return response.getBody().getResults();
            }
            
            return new HashMap<>();
            
        } catch (Exception e) {
            log.error("Error fetching batch recommendations: {}", e.getMessage());
            return new HashMap<>();
        }
    }

    /**
     * Check if recommendation service is healthy
     */
    public boolean isHealthy() {
        try {
            String url = recommendationApiUrl + "/health";
            ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            log.error("Recommendation service health check failed: {}", e.getMessage());
            return false;
        }
    }

    /**
     * Get recommendation system statistics
     */
    public RecommendationStats getStats() {
        try {
            String url = recommendationApiUrl + "/stats";
            ResponseEntity<RecommendationStats> response = restTemplate.getForEntity(
                url, RecommendationStats.class);
            return response.getBody();
        } catch (Exception e) {
            log.error("Error fetching recommendation stats: {}", e.getMessage());
            return null;
        }
    }

    // DTO Classes

    @Data
    public static class CourseRecommendation {
        @JsonProperty("course_id")
        private Long courseId;
        
        private String title;
        private String category;
        private String level;
        private Double price;
        
        @JsonProperty("is_free")
        private Boolean isFree;
        
        @JsonProperty("recommendation_score")
        private Double recommendationScore;
        
        @JsonProperty("popularity_score")
        private Double popularityScore;
        
        @JsonProperty("lesson_count")
        private Integer lessonCount;
    }

    @Data
    public static class RecommendationResponse {
        @JsonProperty("student_id")
        private Long studentId;
        
        private List<CourseRecommendation> recommendations;
        private Integer count;
    }

    @Data
    public static class SimilarCourse {
        @JsonProperty("course_id")
        private Long courseId;
        
        private String title;
        private String category;
        private String level;
        
        @JsonProperty("similarity_score")
        private Double similarityScore;
    }

    @Data
    public static class SimilarCoursesResponse {
        @JsonProperty("course_id")
        private Long courseId;
        
        @JsonProperty("similar_courses")
        private List<SimilarCourse> similarCourses;
        
        private Integer count;
    }

    @Data
    public static class BatchRecommendationResponse {
        private Map<Long, List<CourseRecommendation>> results;
        private Integer count;
    }

    @Data
    public static class RecommendationStats {
        @JsonProperty("total_students")
        private Integer totalStudents;
        
        @JsonProperty("total_courses")
        private Integer totalCourses;
        
        @JsonProperty("total_enrollments")
        private Integer totalEnrollments;
        
        @JsonProperty("last_update")
        private String lastUpdate;
        
        private List<String> categories;
        
        @JsonProperty("model_loaded")
        private Boolean modelLoaded;
    }
}
