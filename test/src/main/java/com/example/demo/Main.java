package com.example.demo;

import org.mindrot.jbcrypt.BCrypt;

public class Main {
    public static void main(String[] args) {
        String hash = "$2a$10$TQIwic0czeFe9TUbm9Mw/uuPbatDPrZjQF2tVx.6IOtp3PctfmEbi";
        String password = "Maja123*";

       System.out.println(BCrypt.checkpw(password, hash));
     }
}