package com.example.demo.Controllers;

import com.example.demo.services.FileStorageService;
import com.mongodb.client.gridfs.model.GridFSFile;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@RestController
@RequestMapping("/api/files")
@CrossOrigin(origins = "*")
public class FileController {

    @Autowired
    private FileStorageService fileStorageService;

    // ── POST /api/files/upload ──────────────────────────────────────────────
    // Accepts any file (image or video), stores in GridFS, returns the
    // served URL so the frontend can save it in thumbnailUrl / mediaUrl.
    @PostMapping("/upload")
    public ResponseEntity<?> upload(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body("No file provided.");
        }

        String contentType = file.getContentType();
        if (contentType == null ||
            (!contentType.startsWith("image/") && !contentType.startsWith("video/"))) {
            return ResponseEntity.badRequest().body("Only image and video files are allowed.");
        }

        try {
            String fileId = fileStorageService.store(file);
            // Return the URL the frontend will store as thumbnailUrl / mediaUrl
            String url = "/api/files/" + fileId;
            return ResponseEntity.ok(Map.of("url", url, "id", fileId));
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Upload failed: " + e.getMessage());
        }
    }

    // ── GET /api/files/{id} ────────────────────────────────────────────────
    // Streams the file back to the browser.
    // Works for both images (thumbnail) and videos (lesson media).
    @GetMapping("/{id}")
    public ResponseEntity<?> serve(@PathVariable String id) {
        try {
            GridFSFile file = fileStorageService.findById(id);

            if (file == null) {
                return ResponseEntity.notFound().build();
            }

            String contentType = fileStorageService.getContentType(file);
            InputStreamResource resource =
                new InputStreamResource(fileStorageService.getStream(file));

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType(
                contentType != null ? contentType : "application/octet-stream"
            ));
            // inline = browser renders it directly (img src / video src)
            headers.set(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" +
                file.getFilename() + "\"");
            headers.setContentLength(file.getLength());

            return new ResponseEntity<>(resource, headers, HttpStatus.OK);

        } catch (IllegalArgumentException e) {
            // Invalid ObjectId format
            return ResponseEntity.badRequest().body("Invalid file ID.");
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Could not retrieve file: " + e.getMessage());
        }
    }
}