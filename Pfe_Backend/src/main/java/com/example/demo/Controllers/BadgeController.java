package com.example.demo.Controllers;

import com.example.demo.entities.Badge;
import com.example.demo.services.BadgeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/badges")
@CrossOrigin(origins = "*")
public class BadgeController {

    @Autowired
    private BadgeService badgeService;

    // ── GET /api/badges ─────────────────────────────────────────────────────
    // Returns every badge in the collection.
    @GetMapping
    public ResponseEntity<List<Badge>> getAllBadges() {
        return ResponseEntity.ok(badgeService.getAllBadges());
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