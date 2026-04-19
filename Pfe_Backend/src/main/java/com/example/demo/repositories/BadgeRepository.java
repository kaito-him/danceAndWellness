package com.example.demo.repositories;

import com.example.demo.entities.Badge;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BadgeRepository  extends MongoRepository<Badge, String> {
    // MongoRepository gives us save, findById, findAll, deleteById for free.
}