package com.example.demo.dto;
import lombok.Data;

@Data
public class EnrollmentConfirmRequest {
    private String paymentIntentId;
    private String courseId;
    private String studentId;
}