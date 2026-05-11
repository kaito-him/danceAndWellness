package com.example.demo.services;

import com.example.demo.dto.StudentDTO;
import com.example.demo.entities.Course;
import com.example.demo.entities.Enrollment;
import com.example.demo.entities.Student;
import com.example.demo.entities.User;
import com.example.demo.repositories.StudentRepository;
import com.example.demo.repositories.UserRepository;
import com.example.demo.repositories.EnrollmentRepository;
import com.example.demo.repositories.CourseRepository;
import com.example.demo.repositories.LessonProgressRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StudentService {

    private final StudentRepository studentRepository;
    private final UserRepository userRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final CourseRepository courseRepository;
    private final LessonProgressRepository lessonProgressRepository;

    public List<StudentDTO> getAllStudents() {
        return studentRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<Course> getStudentCourses(String studentId) {
        List<com.example.demo.entities.Enrollment> enrollments = enrollmentRepository.findByStudentId(studentId);
        List<String> courseIds = enrollments.stream().map(com.example.demo.entities.Enrollment::getCourseId).collect(Collectors.toList());
        return courseRepository.findAllById(courseIds);
    }
    
    
    public List<Course> getStudentFreeCourses(String studentId) {
        return enrollmentRepository.findByStudentIdAndType(studentId, Enrollment.EnrollmentType.FREE)
                .stream()
                .map(enrollment -> courseRepository.findById(enrollment.getCourseId()).orElse(null))
                .filter(course -> course != null && course.getStatus() == com.example.demo.entities.CourseStatus.PUBLISHED)
                .map(this::enrichInstructorUsername)
                .collect(Collectors.toList());
    }

    public List<Course> getStudentPaidCourses(String studentId) {
        return enrollmentRepository.findByStudentIdAndType(studentId, Enrollment.EnrollmentType.PAID)
                .stream()
                .map(enrollment -> courseRepository.findById(enrollment.getCourseId()).orElse(null))
                .filter(course -> course != null && course.getStatus() == com.example.demo.entities.CourseStatus.PUBLISHED)
                .map(this::enrichInstructorUsername)
                .collect(Collectors.toList());
    }

    private Course enrichInstructorUsername(Course course) {
        if (course.getInstructor() != null && course.getInstructor().getUserId() != null) {
            userRepository.findById(course.getInstructor().getUserId())
                .ifPresent(u -> course.getInstructor().setUsername(u.getUsername()));
        }
        return course;
    }

    public java.util.Map<String, Object> getStudentStats(String userId) {
        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Student not found"));

        String studentId = userId; // or student.getUserId()

        long enrollmentsCount = enrollmentRepository.countByStudentId(studentId);
        long paymentsCount = enrollmentRepository.findByStudentIdAndType(studentId, Enrollment.EnrollmentType.PAID).size();
        
        // Calculate streak
        int streak = calculateStreak(student.getLoginDates());

        // Calculate unique categories watched
        List<com.example.demo.entities.LessonProgress> progressList = lessonProgressRepository.findByStudentId(studentId);
        java.util.Set<String> watchedCategoryIds = new java.util.HashSet<>();
        for (com.example.demo.entities.LessonProgress lp : progressList) {
            courseRepository.findById(lp.getCourseId()).ifPresent(c -> {
                if (c.getCategoryId() != null) watchedCategoryIds.add(c.getCategoryId());
            });
        }

        java.util.Map<String, Object> stats = new java.util.HashMap<>();
        stats.put("enrollmentsCount", enrollmentsCount);
        stats.put("paymentsCount", paymentsCount);
        stats.put("loginStreak", streak);
        stats.put("categoriesWatched", watchedCategoryIds.size());
        return stats;
    }

    private int calculateStreak(java.util.Set<java.time.LocalDate> loginDates) {
        if (loginDates == null || loginDates.isEmpty()) return 0;
        
        List<java.time.LocalDate> sorted = new java.util.ArrayList<>(loginDates);
        java.util.Collections.sort(sorted, java.util.Collections.reverseOrder());

        java.time.LocalDate today = java.time.LocalDate.now();
        java.time.LocalDate yesterday = today.minusDays(1);

        // If no login today and no login yesterday, streak is 0
        if (!loginDates.contains(today) && !loginDates.contains(yesterday)) {
            return 0;
        }

        int streak = 0;
        java.time.LocalDate current = loginDates.contains(today) ? today : yesterday;

        while (loginDates.contains(current)) {
            streak++;
            current = current.minusDays(1);
        }
        return streak;
    }

    private StudentDTO mapToDTO(Student student) {
        User user = userRepository.findById(student.getUserId()).orElse(null);
        if (user == null) {
            return StudentDTO.builder()
                    .id(student.getId())
                    .userId(student.getUserId())
                    .build();
        }

        return StudentDTO.builder()
                .id(student.getId())
                .userId(student.getUserId())
                .username(user.getUsername())
                .email(user.getEmail())
                .accountStatus(user.getStatus())
                // Prefer Student.photo; fall back to User.photo for existing accounts
                .photo(student.getPhoto() != null ? student.getPhoto() : user.getPhoto())
                .createdAt(user.getCreatedAt())
                .lastLoginDate(user.getLastLoginDate())
                .badgeIds(student.getBadgeIds())
                .build();
    }
}
