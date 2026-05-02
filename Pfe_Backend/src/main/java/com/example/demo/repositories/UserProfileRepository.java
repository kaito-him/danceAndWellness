package com.example.demo.repositories;

import com.example.demo.entities.UserProfile;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.Optional;

public interface UserProfileRepository extends MongoRepository<UserProfile, String> {
    Optional<UserProfile> findByStudentId(String studentId);
}