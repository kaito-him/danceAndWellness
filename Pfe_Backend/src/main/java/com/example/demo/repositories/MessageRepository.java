package com.example.demo.repositories;

import com.example.demo.entities.Message;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import java.util.List;

public interface MessageRepository extends MongoRepository<Message, String> {

    @Query("{ $or: [ { senderId: ?0, receiverId: ?1 }, { senderId: ?1, receiverId: ?0 } ] }")
    List<Message> findThread(String userId1, String userId2);

    @Query("{ $or: [ { senderId: ?0 }, { receiverId: ?0 } ] }")
    List<Message> findAllByUser(String userId);

    long countByReceiverIdAndSenderIdAndReadFalse(String receiverId, String senderId);

    @Query("{ receiverId: ?0, senderId: ?1, read: false }")
    List<Message> findUnreadFrom(String receiverId, String senderId);
}