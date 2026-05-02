package com.example.demo.dto;
import java.util.List;

import com.example.demo.entities.DifficultyLevel;

import lombok.Data;

@Data
public class SignupRequest {
    private String username;
    private String email;
    private String password;
    
 // ── Onboarding (required at signup) ──────────────────────────────────
    private List<String>    categoryIds;   // at least 3
    private DifficultyLevel skillLevel;
}