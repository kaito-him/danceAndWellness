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

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired private UserService userService;
    @Autowired private UserRepository userRepository;
    
    
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
}