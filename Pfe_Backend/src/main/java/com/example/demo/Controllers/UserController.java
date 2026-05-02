package com.example.demo.Controllers;

import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import com.example.demo.entities.User;
import com.example.demo.repositories.UserRepository;
import com.example.demo.security.JwtUtil;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired private UserRepository userRepository;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private JwtUtil jwtUtil;

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser() {
        String username = SecurityContextHolder.getContext()
                                               .getAuthentication()
                                               .getName();
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new IllegalArgumentException("User not found."));
        return ResponseEntity.ok(Map.of(
            "userId",   user.getUserId(),
            "username", user.getUsername(),
            "email",    user.getEmail(),
            "role",     user.getRole(),
            "photo",    user.getPhoto() != null ? user.getPhoto() : ""
        ));
    }

    @GetMapping("/{userId}")
    public ResponseEntity<?> getUserById(@PathVariable String userId) {
        return userRepository.findById(userId)
                .<ResponseEntity<?>>map(user -> ResponseEntity.ok(Map.of(
                        "userId", user.getUserId(),
                        "username", user.getUsername(),
                        "email", user.getEmail(),
                        "role", user.getRole(),
                        "photo", user.getPhoto() != null ? user.getPhoto() : ""
                )))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PutMapping("/me")
    public ResponseEntity<?> updateCurrentUser(@RequestBody Map<String, String> body) {
        String username = SecurityContextHolder.getContext()
                                               .getAuthentication()
                                               .getName();
        String originalUsername = username;
        System.out.println(">>> UserController.updateCurrentUser called by: " + username);
        
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> {
                System.out.println(">>> User not found in DB for username: " + username);
                return new IllegalArgumentException("User not found.");
            });

        String currentPassword = body.get("currentPassword");
        if (currentPassword == null || !passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("message", "Current password is incorrect."));
        }

        String newUsername = body.get("username");
        if (newUsername != null && !newUsername.isBlank() && !newUsername.equals(user.getUsername())) {
            if (userRepository.findByUsername(newUsername).isPresent()) {
                return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("message", "Username already taken."));
            }
            user.setUsername(newUsername);
        }

        // ← email: just set it directly, no duplicate fetch needed
        String newEmail = body.get("email");
        if (newEmail != null && !newEmail.isBlank() && !newEmail.equals(user.getEmail())) {
            user.setEmail(newEmail);
        }

        String newPassword = body.get("newPassword");
        if (newPassword != null && !newPassword.isBlank()) {
            if (newPassword.length() < 8) {
                return ResponseEntity.badRequest()
                    .body(Map.of("message", "New password must be at least 8 characters."));
            }
            user.setPasswordHash(passwordEncoder.encode(newPassword));
        }

        String newPhoto = body.get("photo");
        if (newPhoto != null) {
            user.setPhoto(newPhoto.isBlank() ? null : newPhoto);
        }

        userRepository.save(user);

        // If username changed, generate a new token
        String newToken = null;
        if (newUsername != null && !newUsername.isBlank() && !newUsername.equals(originalUsername)) {
            newToken = jwtUtil.generateToken(user.getUsername(), user.getRole());
        }

        return ResponseEntity.ok(Map.of(
            "message",  "Profile updated successfully.",
            "username", user.getUsername(),
            "email",    user.getEmail(),
            "photo",    user.getPhoto() != null ? user.getPhoto() : "",
            "token",    newToken != null ? newToken : ""
        ));
    }

    @PatchMapping("/me/photo")
    public ResponseEntity<?> updatePhoto(@RequestBody Map<String, String> body) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new IllegalArgumentException("User not found."));

        String photoId = body.get("photo");
        if (photoId == null || photoId.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("message", "photo is required."));
        }

        user.setPhoto(photoId);
        userRepository.save(user);

        return ResponseEntity.ok(Map.of(
            "message", "Photo updated.",
            "photo", photoId
        ));
    }

    @DeleteMapping("/me/photo")
    public ResponseEntity<?> deletePhoto() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new IllegalArgumentException("User not found."));

        user.setPhoto(null);
        userRepository.save(user);

        return ResponseEntity.ok(Map.of("message", "Photo removed."));
    }
}