package com.bnsf.vault;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest
public class YamlDbTest {

	@Value("${app.username}")
	private String username;
	@Value("${app.password}")
	private String password;
	
	@Test
	public void testDbSecret() {
		System.out.println(username);
		System.out.println(password);
	}
}
