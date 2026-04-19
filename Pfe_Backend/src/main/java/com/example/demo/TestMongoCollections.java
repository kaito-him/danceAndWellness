package com.example.demo;

import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Autowired;

import com.example.demo.repositories.AdminRepository;
import com.example.demo.repositories.InstructorRepository;
import com.example.demo.repositories.StudentRepository;
import com.example.demo.repositories.UserRepository;
import com.example.demo.entities.AccountStatus;
import com.example.demo.entities.User;

@Component
public class TestMongoCollections implements CommandLineRunner {

    @Autowired
    private AdminRepository adminRepository;
    @Autowired
    private StudentRepository studentRepository;
    @Autowired
    private InstructorRepository instructorRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {

        // Create admin
        User adminUser = new User("mariam", "mariam@gmail.com", passwordEncoder.encode("1234"));
        adminUser.setRole("Instructor");
        adminUser.setStatus(AccountStatus.ACTIVE);
        // userRepository.save(adminUser);
        // instructorRepository.save(new Instructor(adminUser.getUserId()));

        // Print counts
        System.out.println("Users: " + userRepository.count());
        System.out.println("Admins: " + adminRepository.count());
        System.out.println("Students: " + studentRepository.count());
        System.out.println("Instructors: " + instructorRepository.count());
    }
}