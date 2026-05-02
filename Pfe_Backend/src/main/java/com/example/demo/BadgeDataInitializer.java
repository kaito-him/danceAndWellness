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
            Badge earlyBird = new Badge("69db82de3c14b6df68cfdeb7", "Early Bird", "Attend 5 lessons before : 8:00AM", "/api/files/69db82de3c14b6df68cfdeb4");
            Badge streakStarter = new Badge("69db8d9c3c14b6df68cfdebe", "Streak Starter", "Maintain a 7-day activity streak", "/api/files/69db8d9c3c14b6df68cfdebb");
            Badge monthlyMaster = new Badge("69db8dd83c14b6df68cfdec2", "Monthly Master", "Complete 20 course in a single month.", "/api/files/69db8dd83c14b6df68cfdebf");
            Badge styleExplorer = new Badge("69db8e183c14b6df68cfdec6", "Style Explorer", " Try 5 different dance styles", "/api/files/69db8e183c14b6df68cfdec3");

            badgeRepository.saveAll(List.of(earlyBird, streakStarter, monthlyMaster, styleExplorer));
            System.out.println("Badges seeded successfully.");
        }
    }
}
