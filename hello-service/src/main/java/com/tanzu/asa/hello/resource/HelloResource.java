package com.tanzu.asa.hello.resource;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RefreshScope
@RestController
public class HelloResource {

  @Value("${tanzu.env}")
  private String env;

  @GetMapping("/")
  public String index() {
    return String.format("Greetings from %s!", env);
  }

  // 900003883
  @GetMapping("/prime/{number}")
  public String prime(@PathVariable long number) {
    for (long i = 2; i <= number / 2; ++i) {
      if (number % i == 0) {
        return String.format("%s is not a prime number", number);
      }
    }
    return String.format("%s is a prime number", number);
  }

}