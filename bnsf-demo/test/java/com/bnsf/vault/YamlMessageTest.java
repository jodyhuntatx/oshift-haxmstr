package com.bnsf.vault;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest
public class YamlMessageTest {

	@Value("${app.message}")
	private String message;
	
	
	@Test
	public void testSecretMessage( ) {
		System.out.println(message);
	}
}
