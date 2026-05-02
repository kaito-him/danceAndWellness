package com.example.demo.entities;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Document(collection = "user_profiles")
@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserProfile {

    @Id
    private String id;
    
    private String studentId; 

    private List<Category> preferences;

    private DifficultyLevel skillLevel;

    // ── Auto-computed from progress ───────────────────────────────────────
    private Integer totalWatchTime;   // total seconds watched across ALL courses
    private Double  completionRate;   // avg course completion % across ALL courses
}
