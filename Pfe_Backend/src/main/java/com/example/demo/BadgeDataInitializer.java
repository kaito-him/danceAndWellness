package com.example.demo;

import com.example.demo.entities.Badge;
import com.example.demo.repositories.BadgeRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;

@Component
public class BadgeDataInitializer implements CommandLineRunner {

    @Autowired
    private BadgeRepository badgeRepository;

    @Override
    public void run(String... args) throws Exception {
        seedBadges();
    }

    private void seedBadges() {
        if (badgeRepository.count() == 0) {
            Badge streakStarter = new Badge("69db8d9c3c14b6df68cfdebe", "Streak Starter", "Maintain a 7-day activity streak", "/api/files/69db8d9c3c14b6df68cfdebb");
            Badge styleExplorer = new Badge("69db8e183c14b6df68cfdec6", "Style Explorer", " Try 5 different dance styles", "/api/files/69db8e183c14b6df68cfdec3");

            badgeRepository.saveAll(List.of(streakStarter,styleExplorer));
            System.out.println("Badges seeded successfully.");
        }
    }
}
