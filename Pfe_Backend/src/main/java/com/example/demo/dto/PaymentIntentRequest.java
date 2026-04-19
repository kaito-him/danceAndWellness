package com.example.demo.dto;
import lombok.Data;

@Data
public class PaymentIntentRequest {
    private String courseId;
    private String studentId;   // userId of the student
}