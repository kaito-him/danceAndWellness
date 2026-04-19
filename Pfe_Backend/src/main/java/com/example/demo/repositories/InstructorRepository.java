package com.example.demo.repositories;

import java.util.List;
import java.util.Optional;

import org.springframework.data.mongodb.repository.MongoRepository;

import com.example.demo.entities.Instructor;

public interface InstructorRepository extends MongoRepository<Instructor, String> {
	Optional<Instructor> findByUserId(String userId); 
	List<Instructor> findByUserIdIn(List<String> userIds);
    List<Instructor> findByFeaturedTrue();

	List<Instructor> findByUserIdInAndSpecialization(List<String> userIds, String specialization);

	List<Instructor> findByUserIdInAndYearsOfExperience(List<String> userIds, String yearsOfExperience);
}