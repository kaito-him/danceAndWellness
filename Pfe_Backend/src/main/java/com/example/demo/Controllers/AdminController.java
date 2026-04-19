package com.example.demo.Controllers;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.example.demo.entities.Instructor;
import com.example.demo.entities.User;
import com.example.demo.repositories.InstructorRepository;
import com.example.demo.repositories.UserRepository;
import com.example.demo.services.AdminService;
import com.example.demo.services.EmailService;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class AdminController {

    @Autowired private AdminService adminService;
    @Autowired private EmailService         emailService;
    @Autowired private UserRepository        userRepository;
    @Autowired private InstructorRepository instructorRepository;

    // GET /api/admin/applications
    @GetMapping("/applications")
    public ResponseEntity<List<Instructor>> getPendingApplications() {
        return ResponseEntity.ok(adminService.getPendingInstructorApplications());
    }
    
 // GET /api/admin/applications/search
    @GetMapping("/applications/search")
    public ResponseEntity<List<Instructor>> searchApplications(
            @RequestParam(required = false) String username,
            @RequestParam(required = false) String specialization,
            @RequestParam(required = false) String experience) {

        return ResponseEntity.ok(
            adminService.searchPendingApplications(username, specialization, experience)
        );
    }

 // PATCH /api/admin/applications/{userId}/approve
    @PatchMapping("/applications/{userId}/approve")
    public ResponseEntity<?> approveApplication(@PathVariable String userId) {
        try {
            adminService.approveInstructorApplication(userId);
 
            User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
 
            emailService.sendInstructorApprovedEmail(user.getEmail(), user.getUsername());
 
            return ResponseEntity.ok("Instructor approved successfully.");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to approve application.");
        }
    }
 
    // PATCH /api/admin/applications/{userId}/decline
    @PatchMapping("/applications/{userId}/decline")
    public ResponseEntity<?> declineApplication(@PathVariable String userId) {
        try {
            adminService.declineInstructorApplication(userId);
 
            User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
 
            emailService.sendInstructorDeclinedEmail(user.getEmail(), user.getUsername());
 
            return ResponseEntity.ok("Application declined.");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to decline application.");
        }
    }
   

    // PATCH /api/admin/instructors/{id}/highlight
    @PatchMapping("/instructors/{id}/highlight")
    public ResponseEntity<?> highlightInstructor(@PathVariable String id) {
        return instructorRepository.findById(id).map(instructor -> {
            instructor.setFeatured(true);
            instructorRepository.save(instructor);
            return ResponseEntity.ok("Instructor highlighted.");
        }).orElse(ResponseEntity.notFound().build());
    }

    // PATCH /api/admin/instructors/{id}/unhighlight
    @PatchMapping("/instructors/{id}/unhighlight")
    public ResponseEntity<?> unhighlightInstructor(@PathVariable String id) {
        return instructorRepository.findById(id).map(instructor -> {
            instructor.setFeatured(false);
            instructorRepository.save(instructor);
            return ResponseEntity.ok("Instructor unhighlighted.");
        }).orElse(ResponseEntity.notFound().build());
    }

    // ── User Banning Endpoints ──────────────────────────────────────────────

    // PATCH /api/admin/users/{userId}/ban
    @PatchMapping("/users/{userId}/ban")
    public ResponseEntity<?> banUser(@PathVariable String userId) {
        try {
            adminService.banUser(userId);
            return ResponseEntity.ok("User has been banned.");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to ban user.");
        }
    }

    // PATCH /api/admin/users/{userId}/unban
    @PatchMapping("/users/{userId}/unban")
    public ResponseEntity<?> unbanUser(@PathVariable String userId) {
        try {
            adminService.unbanUser(userId);
            return ResponseEntity.ok("User has been unbanned.");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to unban user.");
        }
    }

    // GET /api/admin/users/banned
    @GetMapping("/users/banned")
    public ResponseEntity<List<User>> getBannedUsers() {
        return ResponseEntity.ok(adminService.getBannedUsers());
    }
}