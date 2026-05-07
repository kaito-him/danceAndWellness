package com.example.demo.repositories;

import com.example.demo.entities.Course;
import com.example.demo.entities.CourseStatus;
import com.example.demo.entities.Instructor;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CourseRepository extends MongoRepository<Course, String> {
    List<Course> findByStatus(CourseStatus status);
    List<Course> findByInstructorAndStatus(Instructor instructor, CourseStatus status);
    List<Course> findByInstructor_Id(String instructorId);
    List<Course> findByInstructor_IdAndStatus(String instructorId, CourseStatus status);
    List<Course> findByInstructor_UserId(String userId);
    List<Course> findByInstructor_UserIdAndStatus(String userId, CourseStatus status);
    Optional<Course> findByCourseId(String courseId);
    List<Course> findByArchivedByAdmin(Boolean archivedByAdmin);
}