package com.example.demo.controllers;

import com.example.demo.services.RecommendationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * REST controller for course recommendations
 */
@RestController
@RequestMapping("/api/recommendations")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class RecommendationController {

    private final RecommendationService recommendationService;

    /**
     * Get personalized course recommendations for a student
     * 
     * @param studentId Student ID
     * @param topN Number of recommendations (default: 10)
     * @return List of recommended courses
     */
    @GetMapping("/student/{studentId}")
    @PreAuthorize("hasRole('STUDENT') or hasRole('ADMIN')")
    public ResponseEntity<List<RecommendationService.CourseRecommendation>> getRecommendations(
            @PathVariable Long studentId,
            @RequestParam(required = false, defaultValue = "10") Integer topN) {
        
        log.info("Getting recommendations for student {} (top {})", studentId, topN);
        
        List<RecommendationService.CourseRecommendation> recommendations = 
            recommendationService.getRecommendations(studentId, topN);
        
        return ResponseEntity.ok(recommendations);
    }

    /**
     * Get courses similar to a given course
     * 
     * @param courseId Course ID
     * @param topN Number of similar courses (default: 5)
     * @return List of similar courses
     */
    @GetMapping("/similar/{courseId}")
    public ResponseEntity<List<RecommendationService.SimilarCourse>> getSimilarCourses(
            @PathVariable Long courseId,
            @RequestParam(required = false, defaultValue = "5") Integer topN) {
        
        log.info("Getting similar courses for course {} (top {})", courseId, topN);
        
        List<RecommendationService.SimilarCourse> similarCourses = 
            recommendationService.getSimilarCourses(courseId, topN);
        
        return ResponseEntity.ok(similarCourses);
    }

    /**
     * Trigger recommendation system refresh
     * Should be called when:
     * - New course is published
     * - Course is archived
     * - Student enrolls/unenrolls
     * - Student completes lessons
     */
    @PostMapping("/refresh")
    @PreAuthorize("hasRole('ADMIN') or hasRole('INSTRUCTOR')")
    public ResponseEntity<Map<String, String>> refreshRecommendations() {
        log.info("Triggering recommendation system refresh");
        
        recommendationService.refreshRecommendations();
        
        return ResponseEntity.ok(Map.of(
            "status", "success",
            "message", "Recommendation refresh triggered"
        ));
    }

    /**
     * Get batch recommendations for multiple students
     * 
     * @param studentIds List of student IDs
     * @param topN Number of recommendations per student
     * @return Map of student ID to recommendations
     */
    @PostMapping("/batch")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<Long, List<RecommendationService.CourseRecommendation>>> getBatchRecommendations(
            @RequestBody List<Long> studentIds,
            @RequestParam(required = false, defaultValue = "10") Integer topN) {
        
        log.info("Getting batch recommendations for {} students", studentIds.size());
        
        Map<Long, List<RecommendationService.CourseRecommendation>> recommendations = 
            recommendationService.getBatchRecommendations(studentIds, topN);
        
        return ResponseEntity.ok(recommendations);
    }

    /**
     * Check recommendation service health
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> checkHealth() {
        boolean healthy = recommendationService.isHealthy();
        
        return ResponseEntity.ok(Map.of(
            "status", healthy ? "healthy" : "unhealthy",
            "service", "recommendation-system"
        ));
    }

    /**
     * Get recommendation system statistics
     */
    @GetMapping("/stats")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<RecommendationService.RecommendationStats> getStats() {
        RecommendationService.RecommendationStats stats = recommendationService.getStats();
        
        if (stats != null) {
            return ResponseEntity.ok(stats);
        } else {
            return ResponseEntity.status(503).build();
        }
    }
}
