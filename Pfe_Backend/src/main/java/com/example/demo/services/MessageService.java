package com.example.demo.services;

import com.example.demo.dto.ConversationDTO;
import com.example.demo.entities.Instructor;
import com.example.demo.entities.Message;
import com.example.demo.entities.User;
import com.example.demo.repositories.InstructorRepository;
import com.example.demo.repositories.MessageRepository;
import com.example.demo.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class MessageService {

    @Autowired private MessageRepository messageRepo;
    @Autowired private UserRepository userRepo;
    @Autowired private InstructorRepository instructorRepo;

    public Message send(String senderId, String receiverId, String content) {
        return messageRepo.save(Message.builder()
            .senderId(senderId)
            .receiverId(receiverId)
            .content(content)
            .sentAt(LocalDateTime.now())
            .read(false)
            .build());
    }

    public List<Message> getThread(String userId1, String userId2) {
        return messageRepo.findThread(userId1, userId2)
            .stream()
            .sorted(Comparator.comparing(Message::getSentAt))
            .collect(Collectors.toList());
    }

    public List<ConversationDTO> getConversations(String currentUserId) {
        List<Message> all = messageRepo.findAllByUser(currentUserId);

        // Latest message per partner
        Map<String, Message> latestByPartner = new LinkedHashMap<>();
        all.stream()
            .sorted(Comparator.comparing(Message::getSentAt).reversed())
            .forEach(m -> {
                String partner = m.getSenderId().equals(currentUserId)
                    ? m.getReceiverId() : m.getSenderId();
                latestByPartner.putIfAbsent(partner, m);
            });

        List<ConversationDTO> result = new ArrayList<>();
        for (Map.Entry<String, Message> entry : latestByPartner.entrySet()) {
            String partnerId = entry.getKey();
            Message latest = entry.getValue();

            Optional<User> partnerOpt = userRepo.findById(partnerId);
            if (partnerOpt.isEmpty()) continue;
            User partner = partnerOpt.get();

            // Prefer instructor photo if partner is an instructor
            String photo = instructorRepo.findByUserId(partnerId)
                .map(Instructor::getPhoto)
                .orElse(partner.getPhoto());

            long unread = messageRepo.countByReceiverIdAndSenderIdAndReadFalse(currentUserId, partnerId);

            result.add(ConversationDTO.builder()
                .otherUserId(partnerId)
                .otherUsername(partner.getUsername())
                .otherUserPhoto(photo)
                .lastMessage(latest.getContent())
                .lastMessageWasMine(latest.getSenderId().equals(currentUserId))
                .lastMessageAt(latest.getSentAt())
                .unreadCount(unread)
                .build());
        }
        return result;
    }

    public void markThreadAsRead(String currentUserId, String otherUserId) {
        messageRepo.findUnreadFrom(currentUserId, otherUserId)
            .forEach(m -> { m.setRead(true); messageRepo.save(m); });
    }
}