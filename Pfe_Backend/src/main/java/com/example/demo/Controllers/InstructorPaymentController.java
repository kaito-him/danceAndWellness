package com.example.demo.Controllers;

import com.example.demo.dto.InstructorEnrollmentRow;
import com.example.demo.dto.StripeOnboardingResponse;
import com.example.demo.services.InstructorPaymentService;
import com.stripe.exception.StripeException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/instructor/payments")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class InstructorPaymentController {

    private final InstructorPaymentService paymentService;

    /**
     * POST /api/instructor/payments/{instructorId}/onboard
     * Creates (or refreshes) a Stripe Express onboarding link.
     */
    @PostMapping("/{instructorId}/onboard")
    public ResponseEntity<StripeOnboardingResponse> onboard(
            @PathVariable String instructorId) throws StripeException {
        return ResponseEntity.ok(paymentService.createOrGetOnboardingLink(instructorId));
    }

    /**
     * GET /api/instructor/payments/{instructorId}/status
     * Returns Stripe account status (hasAccount, chargesEnabled, etc.)
     */
    @GetMapping("/{instructorId}/status")
    public ResponseEntity<Map<String, Object>> status(
            @PathVariable String instructorId) throws StripeException {
        return ResponseEntity.ok(paymentService.getAccountStatus(instructorId));
    }

    /**
     * GET /api/instructor/payments/{instructorId}/enrollments
     * Returns all enrollments for the instructor's courses with student & course details.
     */
    @GetMapping("/{instructorId}/enrollments")
    public ResponseEntity<List<InstructorEnrollmentRow>> enrollments(
            @PathVariable String instructorId) {
        return ResponseEntity.ok(paymentService.getEnrollments(instructorId));
    }

    /**
     * GET /api/instructor/payments/course/{courseId}/enrollments
     * Returns all enrollments for a specific course (for admin use).
     */
    @GetMapping("/course/{courseId}/enrollments")
    public ResponseEntity<List<InstructorEnrollmentRow>> getCourseEnrollments(
            @PathVariable String courseId) {
        return ResponseEntity.ok(paymentService.getEnrollmentsByCourse(courseId));
    }
}