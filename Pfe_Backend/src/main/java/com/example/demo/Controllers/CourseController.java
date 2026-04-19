package com.example.demo.Controllers;

import com.example.demo.entities.Course;
import com.example.demo.entities.Instructor;
import com.example.demo.entities.User;
import com.example.demo.repositories.InstructorRepository;
import com.example.demo.repositories.UserRepository;
import com.example.demo.services.CourseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/courses")
@CrossOrigin(origins = "*")
public class CourseController {

    @Autowired private CourseService        courseService;
    @Autowired private UserRepository       userRepository;
    @Autowired private InstructorRepository instructorRepository;

    // ── Helper ────────────────────────────────────────────────────
    private Instructor resolveInstructor() {
        String username = SecurityContextHolder.getContext()
                                               .getAuthentication()
                                               .getName();
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new IllegalArgumentException("User not found: " + username));
        return instructorRepository.findByUserId(user.getUserId())
            .orElseThrow(() -> new IllegalArgumentException("Instructor profile not found."));
    }
    
    @GetMapping("/my-published")
    public ResponseEntity<List<Course>> getMyPublishedCourses() {
        try {
            Instructor instructor = resolveInstructor();
            return ResponseEntity.ok(courseService.getPublishedCoursesByInstructor(instructor));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // ── Endpoints ─────────────────────────────────────────────────
    @GetMapping("/pending")
    public ResponseEntity<List<Course>> getPendingCourses() {
        return ResponseEntity.ok(courseService.getAllPendingCourses());
    }

    @GetMapping("/published")
    public ResponseEntity<List<Course>> getPublishedCourses() {
        return ResponseEntity.ok(courseService.getAllPublishedCourses());
    }

    @GetMapping("/my-pending")
    public ResponseEntity<List<Course>> getMyPendingCourses() {
        try {
            Instructor instructor = resolveInstructor();
            return ResponseEntity.ok(courseService.getPendingCoursesByInstructor(instructor));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @PostMapping
    public ResponseEntity<?> addCourse(@RequestBody Course course) {
        try {
            Instructor instructor = resolveInstructor();
            course.setInstructor(instructor);
            Course saved = courseService.addCourse(course);
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }
    
    @GetMapping("/{courseId}")
    public ResponseEntity<Course> getCourseById(@PathVariable String courseId) {
        try {
            return ResponseEntity.ok(courseService.getCourseDetail(courseId));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
     

    @PutMapping("/{courseId}")
    public ResponseEntity<?> updateCourse(
            @PathVariable String courseId,
            @RequestBody Course course) {
        try {
            Instructor instructor = resolveInstructor();
            Course updated = courseService.updateCourse(courseId, course, instructor);
            return ResponseEntity.ok(updated);
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }

    @DeleteMapping("/{courseId}")
    public ResponseEntity<?> deleteCourse(@PathVariable String courseId) {
        try {
            Instructor instructor = resolveInstructor();
            courseService.deleteCourse(courseId, instructor);
            return ResponseEntity.noContent().build();
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }
    
    
    @PatchMapping("/{courseId}/approve")
    public ResponseEntity<?> approveCourse(@PathVariable String courseId) {
        try {
            Course approved = courseService.approveCourse(courseId);
            return ResponseEntity.ok(approved);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }

    @PatchMapping("/{courseId}/archive")
    public ResponseEntity<?> archiveCourse(@PathVariable String courseId) {
        try {
            Course archived = courseService.archiveCourse(courseId);
            return ResponseEntity.ok(archived);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }
}