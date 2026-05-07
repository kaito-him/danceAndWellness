package com.example.demo.Controllers;

import com.example.demo.dto.QuizSubmitRequest;
import com.example.demo.entities.QuizAttempt;
import com.example.demo.entities.User;
import com.example.demo.repositories.UserRepository;
import com.example.demo.services.QuizService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/quizzes")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class QuizController {

    private final QuizService quizService;
    private final UserRepository userRepository;

    private String resolveUserId(Authentication auth) {
        return userRepository.findByUsername(auth.getName())
                .map(User::getUserId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }

    /**
     * GET /api/quizzes/instructor/attempts?courseId=...
     * Returns all quiz attempts for all students on a course (instructor view).
     * Response: List<QuizAttempt> sorted by score descending.
     */
    @GetMapping("/instructor/attempts")
    public ResponseEntity<List<QuizAttempt>> getAttemptsForCourse(
            @RequestParam String courseId) {
        return ResponseEntity.ok(quizService.getAttemptsForCourseInstructor(courseId));
    }

    /**
     * GET /api/quizzes/attempts?courseId=...
     * Returns all quiz attempts for the authenticated student on a course.
     * Response: { quizId: QuizAttempt, ... }
     */
    @GetMapping("/attempts")
    public ResponseEntity<Map<String, QuizAttempt>> getAttempts(
            @RequestParam String courseId,
            Authentication auth) {
        String studentId = resolveUserId(auth);
        return ResponseEntity.ok(quizService.getAttemptsForCourse(studentId, courseId));
    }

    /**
     * POST /api/quizzes/submit
     * Submits a quiz attempt. Returns the saved attempt with score and results.
     */
    @PostMapping("/submit")
    public ResponseEntity<?> submit(
            @RequestBody QuizSubmitRequest req,
            Authentication auth) {
        try {
            String studentId = resolveUserId(auth);
            QuizAttempt attempt = quizService.submit(studentId, req);
            return ResponseEntity.ok(attempt);
        } catch (IllegalStateException e) {
            return ResponseEntity.status(409).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
