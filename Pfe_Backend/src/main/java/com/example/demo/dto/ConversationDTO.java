package com.example.demo.dto;

import lombok.*;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class ConversationDTO {
    private String otherUserId;
    private String otherUsername;
    private String otherUserPhoto;        // GridFS id
    private String lastMessage;
    private boolean lastMessageWasMine;
    private LocalDateTime lastMessageAt;
    private long unreadCount;
}