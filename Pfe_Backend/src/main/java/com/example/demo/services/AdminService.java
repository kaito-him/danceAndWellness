package com.example.demo.services;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.demo.entities.AccountStatus;
import com.example.demo.entities.Instructor;
import com.example.demo.entities.User;
import com.example.demo.repositories.InstructorRepository;
import com.example.demo.repositories.UserRepository;
import com.example.demo.services.EmailService;

@Service
public class AdminService {

    @Autowired private UserRepository       userRepository;
    @Autowired private InstructorRepository instructorRepository;
    @Autowired private EmailService         emailService;

    // ── Fetch all PENDING instructor accounts ──────────────────────────────
    public List<Instructor> getPendingInstructorApplications() {

        // 1. All PENDING users with role INSTRUCTOR
        List<User> pendingUsers =
            userRepository.findByStatusAndRole(AccountStatus.PENDING, "INSTRUCTOR");

        // 2. Build a userId → User lookup for O(1) access
        Map<String, User> userMap = pendingUsers.stream()
            .collect(Collectors.toMap(User::getUserId, u -> u));

        // 3. Fetch matching Instructor documents in one query
        List<String> userIds = pendingUsers.stream()
            .map(User::getUserId)
            .collect(Collectors.toList());

        List<Instructor> instructors =
            instructorRepository.findByUserIdIn(userIds);

        // 4. Hydrate the @Transient fields from the User side
        instructors.forEach(ins -> {
            User user = userMap.get(ins.getUserId());
            if (user != null) {
                ins.setUsername(user.getUsername());
                ins.setEmail(user.getEmail());
            }
        });

        return instructors;
    }

    public List<Instructor> searchPendingApplications(
            String username,
            String specialization,
            String experience) {

        // 1. Get all pending instructor users
        List<User> users = userRepository
            .findByStatusAndRole(AccountStatus.PENDING, "INSTRUCTOR");

        // 2. Filter by username (if provided)
        if (username != null && !username.isEmpty()) {
            users = users.stream()
                .filter(u -> u.getUsername().toLowerCase()
                    .contains(username.toLowerCase()))
                .collect(Collectors.toList());
        }

        // 3. Build map + IDs
        Map<String, User> userMap = users.stream()
            .collect(Collectors.toMap(User::getUserId, u -> u));

        List<String> userIds = users.stream()
            .map(User::getUserId)
            .collect(Collectors.toList());

        // 4. Fetch instructors (single query)
        List<Instructor> instructors = instructorRepository.findByUserIdIn(userIds);

        // 5. Apply Instructor-side filters
        if (specialization != null && !specialization.isEmpty()) {
            instructors = instructors.stream()
                .filter(i -> i.getSpecialization() != null &&
                    i.getSpecialization().equalsIgnoreCase(specialization))
                .collect(Collectors.toList());
        }

        if (experience != null && !experience.isEmpty()) {
            instructors = instructors.stream()
                .filter(i -> i.getYearsOfExperience() != null &&
                    i.getYearsOfExperience().equalsIgnoreCase(experience))
                .collect(Collectors.toList());
        }

        instructors.forEach(ins -> {
            User user = userMap.get(ins.getUserId());
            if (user != null) {
                ins.setUsername(user.getUsername());
                ins.setEmail(user.getEmail());
            }
        });
        return instructors;
    }
    // ── Approve: set ACTIVE ────────────────────────────────────────────────
    public void approveInstructorApplication(String userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
        user.setStatus(AccountStatus.ACTIVE);
        userRepository.save(user);
    }

    // ── Decline: set INACTIVE ──────────────────────────────────────────────
    public void declineInstructorApplication(String userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
        user.setStatus(AccountStatus.INACTIVE);
        userRepository.save(user);
    }

    // ── Ban/Unban System ───────────────────────────────────────────────────
    public void banUser(String userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
        
        user.setStatus(AccountStatus.INACTIVE);
        userRepository.save(user);

        // Auto-unhighlight if this user is a featured instructor
        instructorRepository.findByUserId(userId).ifPresent(instructor -> {
            if (instructor.isFeatured()) {
                instructor.setFeatured(false);
                instructorRepository.save(instructor);
            }
        });
        
        try {
            emailService.sendAccountBannedEmail(user.getEmail(), user.getUsername());
        } catch (Exception e) {
            e.printStackTrace(); // Log email failure but don't disrupt the banning process
        }
    }

    public void unbanUser(String userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
        
        user.setStatus(AccountStatus.ACTIVE);
        userRepository.save(user);

        try {
            emailService.sendAccountUnbannedEmail(user.getEmail(), user.getUsername());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public List<User> getBannedUsers() {
        return userRepository.findByStatus(AccountStatus.INACTIVE).stream()
                .filter(u -> !"ADMIN".equalsIgnoreCase(u.getRole()))
                .collect(Collectors.toList());
    }
}