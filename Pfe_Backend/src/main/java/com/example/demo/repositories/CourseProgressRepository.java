package com.example.demo.repositories;

import com.example.demo.entities.CourseProgress;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;
import java.util.Optional;

public interface CourseProgressRepository extends MongoRepository<CourseProgress, String> {

    Optional<CourseProgress> findByStudentIdAndCourseId(String studentId, String courseId);
 // Add this method to your existing CourseProgressRepository
    List<CourseProgress> findByStudentId(String studentId);
}