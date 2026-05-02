package com.example.demo.Controllers;

import com.example.demo.entities.Badge;
import com.example.demo.entities.User;
import com.example.demo.repositories.UserRepository;
import com.example.demo.services.BadgeService;
import com.example.demo.services.BadgeEvaluationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/badges")
public class BadgeController {

    @Autowired private BadgeService badgeService;
    @Autowired private BadgeEvaluationService badgeEvaluationService;
    @Autowired private UserRepository userRepository;

    private String resolveUserId(Authentication auth) {
        return userRepository.findByUsername(auth.getName())
            .map(User::getUserId)
            .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }

    // ── GET /api/badges ─────────────────────────────────────────────────────
    @GetMapping
    public ResponseEntity<List<Badge>> getAllBadges() {
        return ResponseEntity.ok(badgeService.getAllBadges());
    }

    // ── GET /api/badges/my-status ───────────────────────────────────────────
    // Returns all badges with earned=true/false for the current student
    @GetMapping("/my-status")
    public ResponseEntity<List<Map<String, Object>>> getMyBadgeStatus(Authentication auth) {
        String userId = resolveUserId(auth);
        // Re-evaluate before returning so badges are fresh
        badgeEvaluationService.evaluate(userId);
        return ResponseEntity.ok(badgeEvaluationService.getBadgeStatusForUser(userId));
    }

    // ── GET /api/badges/{id} ────────────────────────────────────────────────
    @GetMapping("/{id}")
    public ResponseEntity<Badge> getBadge(@PathVariable String id) {
        return badgeService.getBadgeById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── POST /api/badges ────────────────────────────────────────────────────
    @PostMapping
    public ResponseEntity<?> createBadge(@RequestBody Badge badge) {
        if (badge.getName() == null || badge.getName().isBlank()) {
            return ResponseEntity.badRequest().body("Badge name is required.");
        }
        if (badge.getAchievement() == null || badge.getAchievement().isBlank()) {
            return ResponseEntity.badRequest().body("Achievement is required.");
        }
        Badge created = badgeService.createBadge(badge);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    // ── PUT /api/badges/{id} ─────────────────────────────────────────────────
    @PutMapping("/{id}")
    public ResponseEntity<?> updateBadge(@PathVariable String id,
                                          @RequestBody Badge updated) {
        return badgeService.updateBadge(id, updated)
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── DELETE /api/badges/{id} ──────────────────────────────────────────────
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteBadge(@PathVariable String id) {
        if (badgeService.deleteBadge(id)) {
            return ResponseEntity.ok("Badge deleted.");
        }
        return ResponseEntity.notFound().build();
    }
}