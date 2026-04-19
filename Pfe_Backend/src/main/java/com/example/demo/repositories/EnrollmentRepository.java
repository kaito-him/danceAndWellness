package com.example.demo.repositories;

import com.example.demo.entities.Enrollment;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface EnrollmentRepository extends MongoRepository<Enrollment, String> {
    boolean existsByStudentIdAndCourseId(String studentId, String courseId);
    Optional<Enrollment> findByStudentIdAndCourseId(String studentId, String courseId);
    Optional<Enrollment> findByPaymentIntentId(String paymentIntentId);
    
    List<Enrollment> findByCourseIdIn(Collection<String> courseIds);
    List<Enrollment> findByStudentId(String studentId);
}