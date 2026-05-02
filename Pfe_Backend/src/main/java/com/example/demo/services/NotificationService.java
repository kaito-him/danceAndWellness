package com.example.demo.services;

import com.example.demo.entities.Notification;
import com.example.demo.repositories.NotificationRepository;
import com.example.demo.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private UserRepository userRepository;

    public Notification create(String userId, String message) {
        return create(userId, message, "GENERAL", null, false);
    }

    public Notification create(String userId, String message, String type, String courseId, boolean openComments) {
        Notification n = new Notification();
        n.setUserId(userId);
        n.setMessage(message);
        n.setType(type);
        n.setCourseId(courseId);
        n.setOpenComments(openComments);
        n.setRead(false);
        n.setCreatedAt(LocalDateTime.now());
        return notificationRepository.save(n);
    }
    
    // all notifications
    public List<Notification> getForUser(String userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    // unread count
    public long countUnread(String userId) {
        return notificationRepository.countByUserIdAndReadFalse(userId);
    }

    // mark one as read
    public void markRead(String notificationId) {
        notificationRepository.findById(notificationId).ifPresent(n -> {
            n.setRead(true);
            notificationRepository.save(n);
        });
    }

    // mark all as read
    public void markAllRead(String userId) {
        List<Notification> all = notificationRepository
            .findByUserIdOrderByCreatedAtDesc(userId);
        all.stream()
           .filter(n -> !n.isRead())
           .forEach(n -> n.setRead(true));
        notificationRepository.saveAll(all);
    }

    /**
     * Sends the same notification to every user with role ADMIN.
     */
    public void notifyAllAdmins(String message, String type, String courseId, boolean openComments) {
        userRepository.findByRole("ADMIN").forEach(admin ->
            create(admin.getUserId(), message, type, courseId, openComments)
        );
    }
}