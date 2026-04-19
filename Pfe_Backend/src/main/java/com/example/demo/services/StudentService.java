package com.example.demo.services;

import com.example.demo.dto.StudentDTO;
import com.example.demo.entities.Student;
import com.example.demo.entities.User;
import com.example.demo.repositories.StudentRepository;
import com.example.demo.repositories.UserRepository;
import com.example.demo.repositories.EnrollmentRepository;
import com.example.demo.repositories.CourseRepository;
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

    public List<StudentDTO> getAllStudents() {
        return studentRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<com.example.demo.entities.Course> getStudentCourses(String studentId) {
        List<com.example.demo.entities.Enrollment> enrollments = enrollmentRepository.findByStudentId(studentId);
        List<String> courseIds = enrollments.stream().map(com.example.demo.entities.Enrollment::getCourseId).collect(Collectors.toList());
        return courseRepository.findAllById(courseIds);
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
                .photo(student.getPhoto())
                .createdAt(user.getCreatedAt())
                .lastLoginDate(user.getLastLoginDate())
                .build();
    }
}
