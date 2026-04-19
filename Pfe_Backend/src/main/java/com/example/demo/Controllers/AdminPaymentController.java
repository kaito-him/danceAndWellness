package com.example.demo.Controllers;

import com.example.demo.dto.AdminRevenueSummary;
import com.example.demo.dto.AdminTransactionRow;
import com.example.demo.services.AdminPaymentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/admin/payments")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminPaymentController {

    private final AdminPaymentService adminPaymentService;

    @GetMapping("/summary")
    public ResponseEntity<AdminRevenueSummary> getSummary() {
        return ResponseEntity.ok(adminPaymentService.getRevenueSummary());
    }

    @GetMapping("/transactions")
    public ResponseEntity<List<AdminTransactionRow>> getTransactions() {
        return ResponseEntity.ok(adminPaymentService.getAllTransactions());
    }
}
