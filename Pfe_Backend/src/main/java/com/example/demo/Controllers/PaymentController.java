// PaymentController.java
package com.example.demo.Controllers;

import com.example.demo.dto.*;
import com.example.demo.services.PaymentService;
import com.stripe.exception.StripeException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/payment")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    /** Called by React to get the client_secret before showing the card form */
    @PostMapping("/create-intent")
    public ResponseEntity<PaymentIntentResponse> createIntent(
            @RequestBody PaymentIntentRequest req) throws StripeException {
        return ResponseEntity.ok(paymentService.createPaymentIntent(req));
    }

    /** Called by React after Stripe confirms the card charge */
    @PostMapping("/confirm-enrollment")
    public ResponseEntity<?> confirmEnrollment(
            @RequestBody EnrollmentConfirmRequest req) throws StripeException {
        return ResponseEntity.ok(paymentService.confirmEnrollment(req));
    }

    /** Quick check used by the course page to show "Go to Lessons" vs "Enroll" */
    @GetMapping("/is-enrolled")
    public ResponseEntity<Map<String, Boolean>> isEnrolled(
            @RequestParam String studentId,
            @RequestParam String courseId) {
        return ResponseEntity.ok(Map.of(
            "enrolled", paymentService.isEnrolled(studentId, courseId)
        ));
    }
}