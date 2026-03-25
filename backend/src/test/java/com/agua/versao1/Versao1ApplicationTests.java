package com.agua.versao1;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

@Import(TestcontainersConfiguration.class)
@SpringBootTest
class Versao1ApplicationTests {

	@Test
	void contextLoads() {
	}

}
