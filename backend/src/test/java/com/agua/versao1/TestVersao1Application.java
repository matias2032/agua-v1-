package com.agua.versao1;

import org.springframework.boot.SpringApplication;

public class TestVersao1Application {

	public static void main(String[] args) {
		SpringApplication.from(Versao1Application::main).with(TestcontainersConfiguration.class).run(args);
	}

}
