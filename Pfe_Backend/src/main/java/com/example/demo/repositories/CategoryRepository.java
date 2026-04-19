package com.example.demo.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import com.example.demo.entities.Category;

public interface CategoryRepository extends MongoRepository<Category, String> {
}