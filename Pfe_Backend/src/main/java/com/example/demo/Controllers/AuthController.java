package com.example.demo.Controllers;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.example.demo.dto.InstructorSignupRequest;
import com.example.demo.dto.LoginRequest;
import com.example.demo.dto.LoginResponse;
import com.example.demo.dto.SignupRequest;
import com.example.demo.entities.User;
import com.example.demo.exceptions.AccountStatusException;
import com.example.demo.repositories.UserRepository;
import com.example.demo.services.UserService;
import com.example.demo.services.PasswordResetService;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired private UserService userService;
    @Autowired private UserRepository userRepository;
    @Autowired private PasswordResetService passwordResetService;
    
    
    @PostMapping(value = "/register/instructor", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> registerInstructor(
            @RequestPart("data")      InstructorSignupRequest req,
            @RequestPart("certFile")  MultipartFile certFile) {
     
        try {
            userService.registerInstructor(req, certFile);
            return ResponseEntity
                .status(HttpStatus.CREATED)
                .body("Application submitted. Check your e-mail for confirmation.");
        } catch (IllegalArgumentException e) {
            return ResponseEntity
                .status(HttpStatus.CONFLICT)
                .body(e.getMessage());
        } catch (Exception e) {	
            return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("An internal error occurred.");
        }
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest request) {

        if (request.getUsername() == null || request.getUsername().isBlank() ||
            request.getPassword() == null || request.getPassword().isBlank()) {
            return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(new LoginResponse(false, null, null, "Username and password are required", null));
        }

        try {
            LoginResponse response = userService.login(request);
            return response.isSuccess()
                ? ResponseEntity.ok(response)
                : ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);

        } catch (AccountStatusException e) {
 
            return ResponseEntity
                .status(HttpStatus.FORBIDDEN)
                .body(new LoginResponse(false, null, null, e.getMessage(), null));

        } catch (Exception e) {
            return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new LoginResponse(false, null, null, "An internal error occurred", null));
        }
    }
    
    
    @PostMapping("/register/student")
    public ResponseEntity<?> registerStudent(@RequestBody SignupRequest req) {
        try {
            userService.registerStudent(req);
            return ResponseEntity.status(HttpStatus.CREATED)
                                 .body("Account created successfully.");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }
    
    
    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new IllegalArgumentException("User not found."));
        return ResponseEntity.ok(Map.of(
            "username", user.getUsername(),
            "email",    user.getEmail(),
            "role",     user.getRole()
        ));
    }

    // ── Availability Checks ───────────────────────────────────────────────────

    @GetMapping("/check-username")
    public ResponseEntity<?> checkUsername(@RequestParam String username) {
        boolean taken = userRepository.findByUsername(username.trim()).isPresent();
        return ResponseEntity.ok(Map.of("available", !taken));
    }

    @GetMapping("/check-email")
    public ResponseEntity<?> checkEmail(@RequestParam String email) {
        boolean taken = userRepository.findByEmail(email.trim()).isPresent();
        return ResponseEntity.ok(Map.of("available", !taken));
    }

    // ── Forgot Password ───────────────────────────────────────────────────────

    @PostMapping("/forgot-password/request")
    public ResponseEntity<?> requestReset(@RequestBody Map<String, String> body) {
        String usernameOrEmail = body.get("usernameOrEmail");
        if (usernameOrEmail == null || usernameOrEmail.isBlank())
            return ResponseEntity.badRequest().body("Username or email is required.");
        try {
            passwordResetService.requestReset(usernameOrEmail.trim());
            return ResponseEntity.ok("Reset code sent to your registered email.");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to send reset code. Please try again.");
        }
    }

    @PostMapping("/forgot-password/verify")
    public ResponseEntity<?> verifyCode(@RequestBody Map<String, String> body) {
        String usernameOrEmail = body.get("usernameOrEmail");
        String code = body.get("code");
        if (usernameOrEmail == null || code == null)
            return ResponseEntity.badRequest().body("Username/email and code are required.");
        try {
            String userId = passwordResetService.verifyCode(usernameOrEmail.trim(), code.trim());
            return ResponseEntity.ok(Map.of("userId", userId));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.GONE).body(e.getMessage());
        }
    }

    @PostMapping("/forgot-password/reset")
    public ResponseEntity<?> resetPassword(@RequestBody Map<String, String> body) {
        String userId = body.get("userId");
        String newPassword = body.get("newPassword");
        String confirmPassword = body.get("confirmPassword");
        if (userId == null || newPassword == null || confirmPassword == null)
            return ResponseEntity.badRequest().body("All fields are required.");
        if (!newPassword.equals(confirmPassword))
            return ResponseEntity.badRequest().body("Passwords do not match.");
        try {
            passwordResetService.resetPassword(userId, newPassword);
            return ResponseEntity.ok("Password updated successfully.");
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }
}
