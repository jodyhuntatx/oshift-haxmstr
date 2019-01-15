package com.bnsf.vault.web;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.util.Base64;
import java.util.Date;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class WelcomeController {

	@Value("${app.message}")
	private String message = "Hello World";

	@Value("${app.username}")
	private String username;
	
	@Value("${app.password}")
	private String password;
	
	@Value("${build.number}")
	private String buildnumber;
	
	@Value("${app.keystore}")
	private String keystore;
	
	@Value("${app.keystore_password}")
	private String keystore_password;
	
	@GetMapping("/")
	public String welcome(Map<String, Object> model) {
		model.put("time", new Date());
		model.put("message", this.message);
		model.put("username", username);
		model.put("password", password);
		model.put("buildnumber", buildnumber);
		
		byte[] content = Base64.getMimeDecoder().decode(keystore);
		
		String certificate = null;
		
		try {
			ByteArrayInputStream bis = new ByteArrayInputStream(content);
			KeyStore keystore = KeyStore.getInstance(KeyStore.getDefaultType());
			keystore.load(bis, keystore_password.toCharArray());
			
			Certificate cert = keystore.getCertificate("1");
		
			certificate = cert.toString();
		} catch (CertificateException | KeyStoreException | NoSuchAlgorithmException | IOException ignored) {}
		
		model.put("certificate", certificate);
		
		return "welcome";
	}
}
