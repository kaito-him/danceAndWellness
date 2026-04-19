package com.example.demo.Controllers;

import com.example.demo.dto.InstructorDTO;
import com.example.demo.entities.Course;
import com.example.demo.entities.Instructor;
import com.example.demo.entities.User;
import com.example.demo.repositories.UserRepository;
import com.example.demo.security.JwtUtil;
import com.example.demo.services.InstructorService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/instructors")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class InstructorController {

    private final InstructorService instructorService;
    private final JwtUtil jwtUtil;
    private final UserRepository userRepository;

    /**
     * GET /api/instructors/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<Instructor> getById(@PathVariable String id) {
        return instructorService.getInstructorById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    
    @GetMapping
    public ResponseEntity<List<InstructorDTO>> getAll() {
        return ResponseEntity.ok(instructorService.getAllInstructors());
    }
    
    @GetMapping("/featured")
    public ResponseEntity<List<InstructorDTO>> getFeatured() {
        return ResponseEntity.ok(instructorService.getFeaturedInstructors());
    }
 
    /**
     * 
     * GET /api/instructors/{id}/courses
     * Returns all courses published by the given instructor.
     */
    @GetMapping("/{id}/courses")
    public ResponseEntity<List<Course>> getCourses(@PathVariable String id) {
        return ResponseEntity.ok(instructorService.getCoursesByInstructor(id));
    }
    @PatchMapping("/{id}/photo")
    public ResponseEntity<?> updatePhoto(
            @PathVariable String id,
            @RequestBody Map<String, Object> body) {

        String photoId = (String) body.get("photo");
        if (photoId == null || photoId.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "photo is required."));
        }

        Instructor instructor = instructorService.getInstructorById(id)
                .orElse(null);
        if (instructor == null) return ResponseEntity.notFound().build();

        instructor.setPhoto(photoId);	
        
        // Sync to User
        userRepository.findById(instructor.getUserId()).ifPresent(u -> {
            u.setPhoto(photoId);
            userRepository.save(u);
        });
 
        return ResponseEntity.ok(instructorService.saveInstructor(instructor));
    }
    
    @DeleteMapping("/{id}/photo")
    public ResponseEntity<?> removePhoto(@PathVariable String id) {
        Instructor instructor = instructorService.getInstructorById(id)
                .orElse(null);
        if (instructor == null) return ResponseEntity.notFound().build();

        instructor.setPhoto(null);
        
        // Sync to User
        userRepository.findById(instructor.getUserId()).ifPresent(u -> {
            u.setPhoto(null);
            userRepository.save(u);
        });
        
        return ResponseEntity.ok(instructorService.saveInstructor(instructor));
    }

    @GetMapping("/by-user/{userId}")
    public ResponseEntity<Instructor> getByUserId(@PathVariable String userId) {
        return instructorService.getInstructorByUserId(userId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * PATCH /api/instructors/{id}
     *
     * Body:
     * {
     *   "currentPassword": "secret123",
     *   "instructor": {
     *     "username":   "new_name",       // optional
     *     "email":      "new@email.com",  // optional
     *     "photo":      "<gridfs-id>",    // optional
     *     "studioName": "Dance Hub",      // optional
     *     "bio":        "...",            // optional
     *     "linkedIn":   "https://...",    // optional
     *     "website":    "https://..."     // optional
     *   }
     * }
     */
    @PatchMapping("/{id}")
    public ResponseEntity<?> update(
            @PathVariable String id,
            @RequestBody Map<String, Object> body) {

        String currentPassword = (String) body.get("currentPassword");
        if (currentPassword == null || currentPassword.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "currentPassword is required."));
        }

        // Re-use the Instructor entity as the updates carrier
        // (only the fields listed above are read by the service)
        @SuppressWarnings("unchecked")
        Map<String, Object> instructorMap =
                (Map<String, Object>) body.getOrDefault("instructor", Map.of());

        Instructor updates = new Instructor();
        updates.setUsername((String) instructorMap.get("username"));
        updates.setEmail((String) instructorMap.get("email"));
        updates.setPhoto((String) instructorMap.get("photo"));
        updates.setStudioName((String) instructorMap.get("studioName"));
        updates.setBio((String) instructorMap.get("bio"));
        updates.setLinkedIn((String) instructorMap.get("linkedIn"));
        updates.setWebsite((String) instructorMap.get("website"));

        try {
            Instructor oldInstructor = instructorService.getInstructorById(id).orElse(null);
            String oldUsername = null;
            if (oldInstructor != null) {
                User oldUser = userRepository.findById(oldInstructor.getUserId()).orElse(null);
                if (oldUser != null) oldUsername = oldUser.getUsername();
            }

            Instructor updated = instructorService.updateInstructor(id, currentPassword, updates);
            
            String newToken = null;
            User newUser = userRepository.findById(updated.getUserId()).orElse(null);
            if (newUser != null && oldUsername != null && !newUser.getUsername().equals(oldUsername)) {
                newToken = jwtUtil.generateToken(newUser.getUsername(), newUser.getRole());
            }

            if (newToken != null) {
                return ResponseEntity.ok(Map.of(
                    "instructor", updated,
                    "token", newToken
                ));
            }
            return ResponseEntity.ok(updated);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}