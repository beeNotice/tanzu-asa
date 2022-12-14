package com.tanzu.asa.hello.resource;

import java.util.List;

import javax.inject.Inject;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.client.ServiceInstance;
import org.springframework.cloud.client.discovery.DiscoveryClient;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RefreshScope
@RestController
public class HelloResource {

  @Inject
  private DiscoveryClient discoveryClient;

  @Value("${tanzu.env}")
  private String env;

  @GetMapping("/")
  public String index() {
    return String.format("Greetings from %s!", env);
  }

  // hello-service
  @GetMapping("/service-instances/{applicationName}")
  public List<ServiceInstance> serviceInstancesByApplicationName(@PathVariable String applicationName) {
    return discoveryClient.getInstances(applicationName);
  }

  @GetMapping(value = "/invoke-hello")
  public String invokeServiceHello() {
    RestTemplate restTemplate = new RestTemplate();
    // hello-service matches the name of the application declared in asa
    String response = restTemplate.getForObject("http://hello-service", String.class);
    return String.format("Invoking hello-service : %s!", response);
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