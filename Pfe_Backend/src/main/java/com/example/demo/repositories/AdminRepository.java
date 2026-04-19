package com.example.demo.repositories;

import java.util.Optional;

import org.springframework.data.mongodb.repository.MongoRepository;

import com.example.demo.entities.Admin;

public interface AdminRepository extends MongoRepository<Admin, String> {
	Optional<Admin> findByUserId(String userId); 
}
