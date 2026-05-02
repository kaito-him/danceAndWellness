package com.example.demo.Controllers;

import com.example.demo.dto.ConversationDTO;
import com.example.demo.entities.Message;
import com.example.demo.entities.User;
import com.example.demo.repositories.UserRepository;
import com.example.demo.services.MessageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/messages")
@CrossOrigin(origins = "*")
public class MessageController {

    @Autowired private MessageService messageService;
    @Autowired private UserRepository userRepo;

    /** Resolves the currently-authenticated username → userId */
    private String uid(String username) {
        return userRepo.findByUsername(username)
            .map(User::getUserId)
            .orElseThrow(() -> new RuntimeException("User not found: " + username));
    }

    @PostMapping("/send")
    public ResponseEntity<Message> send(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal String username) {         // ← String, not UserDetails

        String content    = body.get("content");
        String receiverId = body.get("receiverId");

        if (receiverId == null || content == null || content.isBlank())
            return ResponseEntity.badRequest().build();

        return ResponseEntity.ok(messageService.send(uid(username), receiverId, content));
    }

    @GetMapping("/thread/{otherUserId}")
    public ResponseEntity<List<Message>> thread(
            @PathVariable String otherUserId,
            @AuthenticationPrincipal String username) {         // ← String, not UserDetails

        return ResponseEntity.ok(messageService.getThread(uid(username), otherUserId));
    }

    @GetMapping("/conversations")
    public ResponseEntity<List<ConversationDTO>> conversations(
            @AuthenticationPrincipal String username) {         // ← String, not UserDetails

        return ResponseEntity.ok(messageService.getConversations(uid(username)));
    }

    @PostMapping("/read/{otherUserId}")
    public ResponseEntity<Void> markRead(
            @PathVariable String otherUserId,
            @AuthenticationPrincipal String username) {         // ← String, not UserDetails

        messageService.markThreadAsRead(uid(username), otherUserId);
        return ResponseEntity.ok().build();
    }
}