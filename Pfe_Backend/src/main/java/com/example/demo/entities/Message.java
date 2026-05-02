package com.example.demo.entities;

import java.time.LocalDateTime;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;

@Document(collection = "messages")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Message {
    @Id
    private String id;

    private String senderId; // userId of sender
    private String receiverId; // userId of receiver
    private String content;

    @Builder.Default
    private LocalDateTime sentAt = LocalDateTime.now();

    @Builder.Default
    private boolean read = false;
}