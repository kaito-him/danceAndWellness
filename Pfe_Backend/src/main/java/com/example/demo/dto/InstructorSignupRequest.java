package com.example.demo.dto;

import lombok.Data;

@Data
public class InstructorSignupRequest {
    private String username;
    private String email;
    private String password;
    private String yearsOfExperience;
    private String specialization;
    private String studioName;
    private String bio;
    private String linkedIn;
    private String website;
}