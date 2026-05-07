package com.example.demo.repositories;

import com.example.demo.entities.QuizAttempt;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface QuizAttemptRepository extends MongoRepository<QuizAttempt, String> {

    Optional<QuizAttempt> findByStudentIdAndQuizId(String studentId, String quizId);

    List<QuizAttempt> findByStudentIdAndCourseId(String studentId, String courseId);

    List<QuizAttempt> findByCourseId(String courseId);
}
