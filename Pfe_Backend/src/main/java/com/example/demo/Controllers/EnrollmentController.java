package com.example.demo.Controllers;

import com.example.demo.dto.*;
import com.example.demo.services.EnrollmentService;
import com.stripe.exception.StripeException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/enrollment")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class EnrollmentController {

    private final EnrollmentService enrollmentService;

    // ── FREE ──────────────────────────────────────────────────────────────
    @PostMapping("/free")
    public ResponseEntity<?> enrollFree(
            @RequestParam String studentId,
            @RequestParam String courseId) {
        enrollmentService.enrollFree(studentId, courseId);
        return ResponseEntity.ok(Map.of("enrolled", true));
    }

    // ── PAID step 1 ───────────────────────────────────────────────────────
    @PostMapping("/create-intent")
    public ResponseEntity<PaymentIntentResponse> createIntent(
            @RequestBody PaymentIntentRequest req) throws StripeException {
        return ResponseEntity.ok(enrollmentService.createPaymentIntent(req));
    }

    // ── PAID step 2 ───────────────────────────────────────────────────────
    @PostMapping("/confirm")
    public ResponseEntity<?> confirmPaid(
            @RequestBody EnrollmentConfirmRequest req) throws StripeException {
        return ResponseEntity.ok(enrollmentService.confirmPaidEnrollment(req));
    }

    // ── SHARED check ──────────────────────────────────────────────────────
    @GetMapping("/is-enrolled")
    public ResponseEntity<Map<String, Boolean>> isEnrolled(
            @RequestParam String studentId,
            @RequestParam String courseId) {
        return ResponseEntity.ok(Map.of(
            "enrolled", enrollmentService.isEnrolled(studentId, courseId)
        ));
    }

    // ── CANCEL free enrollment ────────────────────────────────────────────
    @DeleteMapping("/cancel-free")
    public ResponseEntity<?> cancelFree(
            @RequestParam String studentId,
            @RequestParam String courseId) {
        enrollmentService.cancelFreeEnrollment(studentId, courseId);
        return ResponseEntity.ok(Map.of("cancelled", true));
    }
}