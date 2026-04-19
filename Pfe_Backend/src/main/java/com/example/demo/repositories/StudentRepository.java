package com.example.demo.repositories;

import java.util.Optional;

import org.springframework.data.mongodb.repository.MongoRepository;

import com.example.demo.entities.Student;

public interface StudentRepository extends MongoRepository<Student, String> {
	Optional<Student> findByUserId(String userId); 
}
