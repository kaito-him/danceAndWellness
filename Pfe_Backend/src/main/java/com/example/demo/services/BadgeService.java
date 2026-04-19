package com.example.demo.services;

import com.example.demo.entities.Badge;
import com.example.demo.repositories.BadgeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class BadgeService {

    @Autowired
    private BadgeRepository badgeRepository;

    /** Return every badge in the collection. */
    public List<Badge> getAllBadges() {
        return badgeRepository.findAll();
    }

    /** Return a single badge by id (or empty). */
    public Optional<Badge> getBadgeById(String id) {
        return badgeRepository.findById(id);
    }

    /**
     * Create a new badge.
     * The {@code icon} field should be the relative URL returned by
     * {@code FileController.upload()}, e.g. {@code /api/files/<gridfs-id>}.
     */
    public Badge createBadge(Badge badge) {
        badge.setId(null); // let MongoDB generate the _id
        return badgeRepository.save(badge);
    }

    /** Full replacement update. */
    public Optional<Badge> updateBadge(String id, Badge updated) {
        return badgeRepository.findById(id).map(existing -> {
            existing.setName(updated.getName());
            existing.setAchievement(updated.getAchievement());
            if (updated.getIcon() != null && !updated.getIcon().isBlank()) {
                existing.setIcon(updated.getIcon());
            }
            return badgeRepository.save(existing);
        });
    }

    /** Delete a badge by id. Returns true if it existed. */
    public boolean deleteBadge(String id) {
        if (!badgeRepository.existsById(id)) return false;
        badgeRepository.deleteById(id);
        return true;
    }
}