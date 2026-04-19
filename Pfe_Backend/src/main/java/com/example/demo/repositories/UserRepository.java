package com.example.demo.repositories;

import java.util.List;
import java.util.Optional;
import org.springframework.data.mongodb.repository.MongoRepository;

import com.example.demo.entities.AccountStatus;
import com.example.demo.entities.User;

public interface UserRepository extends MongoRepository<User, String> {
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);   // ← add this
    List<User> findByStatusAndRole(AccountStatus status, String role);
    List<User> findByStatus(AccountStatus status);
}