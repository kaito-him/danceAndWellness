package com.example.demo.Controllers;

import com.example.demo.dto.StudentDTO;
import com.example.demo.entities.Course;
import com.example.demo.repositories.StudentRepository;
import com.example.demo.repositories.UserProfileRepository;
import com.example.demo.services.StudentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/students")
@RequiredArgsConstructor
public class StudentController {

    private final StudentService studentService;
    private final StudentRepository studentRepository;
    private final UserProfileRepository userProfileRepository;

    @GetMapping("/{id}/courses/free")
    public ResponseEntity<List<Course>> getStudentFreeCourses(@PathVariable String id) {
        return ResponseEntity.ok(studentService.getStudentFreeCourses(id));
    }

    @GetMapping("/{id}/courses/paid")
    public ResponseEntity<List<Course>> getStudentPaidCourses(@PathVariable String id) {
        return ResponseEntity.ok(studentService.getStudentPaidCourses(id));
    }
    @GetMapping
    public ResponseEntity<List<StudentDTO>> getAllStudents() {
        return ResponseEntity.ok(studentService.getAllStudents());
    }

    @GetMapping("/{id}/courses")
    public ResponseEntity<List<com.example.demo.entities.Course>> getStudentCourses(@PathVariable String id) {
        return ResponseEntity.ok(studentService.getStudentCourses(id));
    }

    @GetMapping("/by-user/{userId}")
    public ResponseEntity<?> getStudentByUserId(@PathVariable String userId) {
        return studentRepository.findByUserId(userId)
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping("/stats/{userId}")
    public ResponseEntity<?> getStudentStats(@PathVariable String userId) {
        try {
            return ResponseEntity.ok(studentService.getStudentStats(userId));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Returns the student's skill level from their UserProfile.
     * GET /api/students/skill-level/{userId}
     */
    @GetMapping("/skill-level/{userId}")
    public ResponseEntity<?> getSkillLevel(@PathVariable String userId) {
        return userProfileRepository.findByStudentId(userId)
                .<ResponseEntity<?>>map(profile -> ResponseEntity.ok(
                        Map.of("skillLevel",
                               profile.getSkillLevel() != null
                                   ? profile.getSkillLevel().name()
                                   : "Not set")
                ))
                .orElseGet(() -> ResponseEntity.ok(Map.of("skillLevel", "Not set")));
    }

    /**
     * Returns the student's UserProfile stats (totalWatchTime, completionRate).
     * GET /api/students/profile-stats/{userId}
     */
    @GetMapping("/profile-stats/{userId}")
    public ResponseEntity<?> getProfileStats(@PathVariable String userId) {
        return userProfileRepository.findByStudentId(userId)
                .<ResponseEntity<?>>map(profile -> ResponseEntity.ok(
                        Map.of(
                            "totalWatchTime", profile.getTotalWatchTime() != null ? profile.getTotalWatchTime() : 0,
                            "completionRate", profile.getCompletionRate() != null ? profile.getCompletionRate() : 0.0
                        )
                ))
                .orElseGet(() -> ResponseEntity.ok(Map.of("totalWatchTime", 0, "completionRate", 0.0)));
    }
}
