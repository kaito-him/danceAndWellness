package com.example.demo.exceptions;


@SuppressWarnings("serial")
public class AccountStatusException extends RuntimeException {
    public AccountStatusException(String status) { 
    	super(status); 
    }
}