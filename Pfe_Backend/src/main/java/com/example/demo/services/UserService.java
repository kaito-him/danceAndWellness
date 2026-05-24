package com.example.demo.services;

import com.example.demo.dto.InstructorSignupRequest;
import com.example.demo.dto.LoginRequest;
import com.example.demo.dto.LoginResponse;
import com.example.demo.dto.SignupRequest;
import com.example.demo.entities.AccountStatus;
import com.example.demo.entities.Category;
import com.example.demo.entities.Instructor;
import com.example.demo.entities.Student;
import com.example.demo.entities.User;
import com.example.demo.entities.UserProfile;
import com.example.demo.exceptions.AccountStatusException;
import com.example.demo.repositories.CategoryRepository;
import com.example.demo.repositories.InstructorRepository;
import com.example.demo.repositories.StudentRepository;
import com.example.demo.repositories.UserProfileRepository;
import com.example.demo.repositories.UserRepository;
import com.example.demo.security.JwtUtil;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class UserService {

    @Autowired
    private StudentRepository studentRepository;
    @Autowired
    private JwtUtil jwtUtil;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private InstructorRepository instructorRepository;
    @Autowired
    private EmailService emailService;
    @Autowired
    private PasswordEncoder passwordEncoder;
    @Autowired
    private FileStorageService fileStorageService;
    
    @Autowired private UserProfileRepository  userProfileRepository;
    @Autowired private CategoryRepository  categoryRepository;
    @Autowired private BadgeEvaluationService badgeEvaluationService;
    @Autowired private NotificationService notificationService;

    // registerInstructor
    public void registerInstructor(InstructorSignupRequest req, MultipartFile certFile)
            throws Exception {
        if (userRepository.findByUsername(req.getUsername()).isPresent()) {
            throw new IllegalArgumentException("Username already taken.");
        }
        if (userRepository.findByEmail(req.getEmail()).isPresent()) {
            throw new IllegalArgumentException("Email already registered.");
        }
        // Persist User
        User user = new User(req.getUsername(), req.getEmail(),
                passwordEncoder.encode(req.getPassword()));
        user.setRole("INSTRUCTOR");
        user.setStatus(AccountStatus.PENDING);
        userRepository.save(user);
        // Store certification file in GridFS
        String certFileId = fileStorageService.store(certFile);
        // Persist Instructor profile
        Instructor instructor = Instructor.builder()
                .userId(user.getUserId())
                .yearsOfExperience(req.getYearsOfExperience())
                .specialization(req.getSpecialization())
                .studioName(req.getStudioName())
                .bio(req.getBio())
                .linkedIn(req.getLinkedIn())
                .website(req.getWebsite())
                .certificationFileName(certFile.getOriginalFilename())
                .certificationFileType(certFile.getContentType())
                .certificationFileId(certFileId)
                .featured(false)
                .build();
        instructorRepository.save(instructor);
        emailService.sendInstructorWelcomeEmail(user.getEmail(), user.getUsername());
        // Notify all admins about the new instructor application
        notificationService.notifyAllAdmins(
            "New instructor application from \"" + user.getUsername() + "\" is awaiting review.",
            "NEW_INSTRUCTOR_APPLICATION",
            null,
            false
        );
    }

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    public LoginResponse login(LoginRequest req) {
        User user = userRepository.findByUsername(req.getUsername())
                .orElse(null);
        if (user == null || !encoder.matches(req.getPassword(), user.getPasswordHash()))
            return new LoginResponse(false, null, null, "Incorrect username or password", null);
        if (user.getStatus() == AccountStatus.INACTIVE) {
            throw new AccountStatusException("INACTIVE");
        }
        if (user.getStatus() == AccountStatus.PENDING) {
            throw new AccountStatusException("PENDING");
        }
        user.setLastLoginDate(LocalDateTime.now());
        userRepository.save(user);
        if ("STUDENT".equals(user.getRole())) {
            studentRepository.findByUserId(user.getUserId()).ifPresent(student -> {
                if (student.getLoginDates() == null) {
                    student.setLoginDates(new java.util.HashSet<>());
                }
                student.getLoginDates().add(java.time.LocalDate.now());
                studentRepository.save(student);
                badgeEvaluationService.evaluate(user.getUserId());
            });
        }
        String token = jwtUtil.generateToken(user.getUsername(), user.getRole());
        return new LoginResponse(true, user.getRole(), token, "Login successful", user.getUserId());
    }

    public void registerStudent(SignupRequest req) {

        // ── Validation ────────────────────────────────────────────────────────
        if (userRepository.findByUsername(req.getUsername()).isPresent())
            throw new IllegalArgumentException("Username already taken.");

        if (userRepository.findByEmail(req.getEmail()).isPresent())
            throw new IllegalArgumentException("Email already in use.");

        if (req.getCategoryIds() == null || req.getCategoryIds().size() < 3)
            throw new IllegalArgumentException("Please select at least 3 categories.");

        if (req.getSkillLevel() == null)
            throw new IllegalArgumentException("Please select your skill level.");

        // ── Resolve category IDs → Category objects ───────────────────────────
        List<Category> categories = categoryRepository.findAllById(req.getCategoryIds());
        if (categories.size() < 3)
            throw new IllegalArgumentException("One or more selected categories are invalid.");

        // ── Persist User ──────────────────────────────────────────────────────
        User user = new User(req.getUsername(), req.getEmail(),
                passwordEncoder.encode(req.getPassword()));
        user.setRole("STUDENT");
        user.setStatus(AccountStatus.ACTIVE);
        User saved = userRepository.save(user);

        // ── Persist Student ───────────────────────────────────────────────────
        studentRepository.save(new Student(saved.getUserId()));

        // ── Persist UserProfile with onboarding data ──────────────────────────
        UserProfile profile = new UserProfile();
        profile.setStudentId(saved.getUserId());
        profile.setPreferences(categories);
        profile.setSkillLevel(req.getSkillLevel());
        profile.setTotalWatchTime(0);
        profile.setCompletionRate(0.0);
        userProfileRepository.save(profile);
    }
}