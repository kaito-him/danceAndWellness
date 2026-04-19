package com.example.demo.services;

import com.example.demo.dto.InstructorDTO;
import com.example.demo.entities.Course;
import com.example.demo.entities.Instructor;
import com.example.demo.entities.User;
import com.example.demo.repositories.CourseRepository;
import com.example.demo.repositories.InstructorRepository;
import com.example.demo.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InstructorService {

    private final InstructorRepository instructorRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final CourseRepository courseRepository;

    public Optional<Instructor> getInstructorById(String instructorId) {
        return instructorRepository.findById(instructorId)
                .map(this::hydrateTransientFields);
    }

    public Instructor saveInstructor(Instructor instructor) {
        return hydrateTransientFields(instructorRepository.save(instructor));
    }
    public Optional<Instructor> getInstructorByUserId(String userId) {
        return instructorRepository.findByUserId(userId)
                .map(this::hydrateTransientFields);
    }

    
 // Inside InstructorService.java

    public List<InstructorDTO> getFeaturedInstructors() {
        List<Instructor> featured = instructorRepository.findByFeaturedTrue();

        List<String> userIds = featured.stream()
                .map(Instructor::getUserId)
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());

        Map<String, User> userMap = userRepository.findAllById(userIds)
                .stream()
                .collect(Collectors.toMap(User::getUserId, u -> u));

        Map<String, Long> courseCountMap = featured.stream()
                .collect(Collectors.toMap(
                        Instructor::getId,
                        i -> (long) courseRepository.findByInstructor_Id(i.getId()).size()
                ));

        return featured.stream()
                .map(i -> toDTO(i, userMap.get(i.getUserId()),
                                courseCountMap.getOrDefault(i.getId(), 0L)))
                .collect(Collectors.toList());
    }
    @Transactional
    public Instructor updateInstructor(String instructorId,
                                       String currentPassword,
                                       Instructor updates) {

        Instructor instructor = instructorRepository.findById(instructorId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Instructor not found: " + instructorId));

        User user = userRepository.findById(instructor.getUserId())
                .orElseThrow(() -> new IllegalStateException(
                        "Linked user not found: " + instructor.getUserId()));

        // ── Password verification ──────────────────────────────────────────
        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            throw new IllegalArgumentException("Current password is incorrect.");
        }

        // ── Update User fields ─────────────────────────────────────────────
        boolean userDirty = false;

        if (updates.getUsername() != null && !updates.getUsername().isBlank()) {
            user.setUsername(updates.getUsername());
            userDirty = true;
        }
        if (updates.getEmail() != null && !updates.getEmail().isBlank()) {
            user.setEmail(updates.getEmail());
            userDirty = true;
        }
        if (userDirty) {
            userRepository.save(user);
        }

        // ── Update Instructor fields ───────────────────────────────────────
        if (updates.getPhoto() != null && !updates.getPhoto().isBlank()) {
            instructor.setPhoto(updates.getPhoto());
            user.setPhoto(updates.getPhoto());
            userDirty = true;
        }
        if (updates.getStudioName() != null) {
            instructor.setStudioName(updates.getStudioName());
        }
        if (updates.getBio() != null && !updates.getBio().isBlank()) {
            instructor.setBio(updates.getBio());
        }
        if (updates.getLinkedIn() != null) {
            instructor.setLinkedIn(updates.getLinkedIn());
        }
        if (updates.getWebsite() != null) {
            instructor.setWebsite(updates.getWebsite());
        }

        return hydrateTransientFields(instructorRepository.save(instructor));
    }

    
    
    public List<InstructorDTO> getAllInstructors() {
        List<Instructor> instructors = instructorRepository.findAll();
 
        // Batch-load users in one query
        List<String> userIds = instructors.stream()
                .map(Instructor::getUserId)
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());
 
        Map<String, User> userMap = userRepository.findAllById(userIds)
                .stream()
                .collect(Collectors.toMap(User::getUserId, u -> u));
 
        // Batch-load course counts
        Map<String, Long> courseCountMap = instructors.stream()
                .collect(Collectors.toMap(
                        Instructor::getId,
                        i -> (long) courseRepository.findByInstructor_Id(i.getId()).size()
                ));
 
        return instructors.stream()
                .map(i -> toDTO(i, userMap.get(i.getUserId()),
                                courseCountMap.getOrDefault(i.getId(), 0L)))
                .collect(Collectors.toList());
    }
 
    /**
     * Returns all courses published by the given instructor id.
     */
    public List<Course> getCoursesByInstructor(String instructorId) {
        return courseRepository.findByInstructor_Id(instructorId);
    }
 
    // ── Private helper ────────────────────────────────────────────────────
 
    private InstructorDTO toDTO(Instructor i, User user, long courseCount) {
        return InstructorDTO.builder()
                .id(i.getId())
                .userId(i.getUserId())
                .username(user != null ? user.getUsername() : "Unknown")
                .email(user != null ? user.getEmail()    : "")
                .accountStatus(user != null ? user.getStatus() : null)
                .yearsOfExperience(i.getYearsOfExperience())
                .specialization(i.getSpecialization())
                .studioName(i.getStudioName())
                .bio(i.getBio())
                .linkedIn(i.getLinkedIn())
                .website(i.getWebsite())
                .photo(i.getPhoto())
                .featured(i.isFeatured())
                .certificationFileId(i.getCertificationFileId())
                .certificationFileName(i.getCertificationFileName())
                .certificationFileType(i.getCertificationFileType())
                .appliedAt(i.getAppliedAt())
                .points(0)
                .totalCourses((int) courseCount)
                .build();
    }
    // ── Helpers ────────────────────────────────────────────────────────────

    private Instructor hydrateTransientFields(Instructor instructor) {
        userRepository.findById(instructor.getUserId()).ifPresent(u -> {
            instructor.setUsername(u.getUsername());
            instructor.setEmail(u.getEmail());
        });
        return instructor;
    }
}