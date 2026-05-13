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
import java.io.InputStream;
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
    // Supports HTTP Range requests (required by Android video_player for seeking).
    @GetMapping("/{id}")
    public ResponseEntity<?> serve(
            @PathVariable String id,
            @RequestHeader(value = HttpHeaders.RANGE, required = false) String rangeHeader) {
        try {
            GridFSFile file = fileStorageService.findById(id);

            if (file == null) {
                return ResponseEntity.notFound().build();
            }

            String contentType = fileStorageService.getContentType(file);
            if (contentType == null) contentType = "application/octet-stream";

            long fileLength = file.getLength();

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType(contentType));
            headers.set(HttpHeaders.CONTENT_DISPOSITION,
                    "inline; filename=\"" + file.getFilename() + "\"");
            headers.set(HttpHeaders.ACCEPT_RANGES, "bytes");

            // ── Range request (partial content) ──────────────────────────
            if (rangeHeader != null && rangeHeader.startsWith("bytes=")) {
                String[] parts = rangeHeader.substring(6).split("-");
                long start = Long.parseLong(parts[0]);
                long end   = (parts.length > 1 && !parts[1].isEmpty())
                             ? Long.parseLong(parts[1])
                             : fileLength - 1;

                if (start > end || start >= fileLength) {
                    headers.set(HttpHeaders.CONTENT_RANGE, "bytes */" + fileLength);
                    return ResponseEntity.status(HttpStatus.REQUESTED_RANGE_NOT_SATISFIABLE)
                            .headers(headers).build();
                }

                end = Math.min(end, fileLength - 1);
                long contentLength = end - start + 1;

                InputStream fullStream = fileStorageService.getStream(file);
                long remaining = start;
                while (remaining > 0) {
                    long skipped = fullStream.skip(remaining);
                    if (skipped <= 0) {
                        fullStream.close();
                        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                .body("Could not seek to requested range.");
                    }
                    remaining -= skipped;
                }

                headers.set(HttpHeaders.CONTENT_RANGE,
                        "bytes " + start + "-" + end + "/" + fileLength);
                headers.setContentLength(contentLength);

                return ResponseEntity.status(HttpStatus.PARTIAL_CONTENT)
                        .headers(headers)
                        .body(new InputStreamResource(fullStream));
            }

            // ── Full file ─────────────────────────────────────────────────
            headers.setContentLength(fileLength);
            InputStream stream = fileStorageService.getStream(file);
            return new ResponseEntity<>(new InputStreamResource(stream), headers, HttpStatus.OK);

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body("Invalid file ID.");
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Could not retrieve file: " + e.getMessage());
        }
    }
}