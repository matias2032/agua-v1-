package com.agua.versao1;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync      
public class Versao1Application {

	public static void main(String[] args) {
		SpringApplication.run(Versao1Application.class, args);
	}

}
