package com.example.demo.repositories;

import com.example.demo.entities.LessonProgress;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;
import java.util.Optional;

public interface LessonProgressRepository extends MongoRepository<LessonProgress, String> {

    Optional<LessonProgress> findByStudentIdAndCourseIdAndLessonId(
            String studentId, String courseId, String lessonId);

    List<LessonProgress> findByStudentIdAndCourseId(String studentId, String courseId);

    long countByStudentIdAndCourseIdAndCompletedTrue(String studentId, String courseId);
    
 // Add this method to your existing LessonProgressRepository
    List<LessonProgress> findByStudentId(String studentId);
}