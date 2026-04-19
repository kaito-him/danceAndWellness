package com.example.demo.Controllers;

import com.example.demo.dto.StudentDTO;
import com.example.demo.services.StudentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/students")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StudentController {

    private final StudentService studentService;

    @GetMapping
    public ResponseEntity<List<StudentDTO>> getAllStudents() {
        return ResponseEntity.ok(studentService.getAllStudents());
    }

    @GetMapping("/{id}/courses")
    public ResponseEntity<List<com.example.demo.entities.Course>> getStudentCourses(@PathVariable String id) {
        return ResponseEntity.ok(studentService.getStudentCourses(id));
    }
}
