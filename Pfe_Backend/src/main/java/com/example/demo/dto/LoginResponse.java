// LoginResponse.java
package com.example.demo.dto;
import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class LoginResponse {
    private boolean success;
    private String role;
    private String token; 
    private String message;
    private String userId;
}