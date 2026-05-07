package com.example.demo.services;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ClassPathResource;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

@Service
public class EmailService {

    @Autowired private JavaMailSender  mailSender;
    @Autowired private TemplateEngine  templateEngine;

    public void sendInstructorWelcomeEmail(String toEmail, String username) throws MessagingException {

        // 1. Build Thymeleaf context — variables used in the template
        Context ctx = new Context();
        ctx.setVariable("username", username);


        String htmlContent = templateEngine.process("instructor-welcome", ctx);

        // 3. Build a MimeMessage (supports HTML)
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

        helper.setTo(toEmail);
        helper.setSubject("Welcome to Dance&Wellness – Application Received");
        helper.setText(htmlContent, true);   // true = isHtml

        mailSender.send(message);
    }
    
    public void sendInstructorApprovedEmail(String toEmail, String username) throws MessagingException {
        Context ctx = new Context();
        ctx.setVariable("username", username);
 
        String htmlContent = templateEngine.process("instructor-approved", ctx);
 
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
        helper.setTo(toEmail);
        helper.setSubject("🎉 Welcome to Dance&Wellness – You're Approved!");
        helper.setText(htmlContent, true);
        
        // Attach logo as inline image
        ClassPathResource logo = new ClassPathResource("static/images/Dicone.png");
        helper.addInline("logo", logo);
        
        mailSender.send(message);
    }
    
    public void sendInstructorDeclinedEmail(String toEmail, String username) throws MessagingException {
        Context ctx = new Context();
        ctx.setVariable("username", username);
 
        String htmlContent = templateEngine.process("instructor-declined", ctx);
 
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
        helper.setTo(toEmail);
        helper.setSubject("Dance&Wellness – Update on Your Instructor Application");
        helper.setText(htmlContent, true);
        
        // Attach logo as inline image
        ClassPathResource logo = new ClassPathResource("static/images/Dicone.png");
        helper.addInline("logo", logo);
        
        mailSender.send(message);
    }
    
    public void sendAccountBannedEmail(String toEmail, String username) throws MessagingException {
        Context ctx = new Context();
        ctx.setVariable("username", username);
 
        String htmlContent = templateEngine.process("account-banned", ctx);
 
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
        helper.setTo(toEmail);
        helper.setSubject("Notice: Your Account has been suspended");
        helper.setText(htmlContent, true);
        mailSender.send(message);
    }

    public void sendAccountUnbannedEmail(String toEmail, String username) throws MessagingException {
        Context ctx = new Context();
        ctx.setVariable("username", username);
 
        String htmlContent = templateEngine.process("account-unbanned", ctx);
 
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
        helper.setTo(toEmail);
        helper.setSubject("Good News: Your Account has been reinstated");
        helper.setText(htmlContent, true);
        mailSender.send(message);
    }

    public void sendPasswordResetCode(String toEmail, String username, String code) throws MessagingException {
        Context ctx = new Context();
        ctx.setVariable("username", username);
        ctx.setVariable("code", code);

        String htmlContent = templateEngine.process("password-reset", ctx);

        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
        helper.setTo(toEmail);
        helper.setSubject("Dance&Wellness – Your Password Reset Code");
        helper.setText(htmlContent, true);
        mailSender.send(message);
    }
}