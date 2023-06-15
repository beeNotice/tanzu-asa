package com.tanzu.asa.hello.web;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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

    private static final Logger LOG = LoggerFactory.getLogger(HelloResource.class);

    @Value("${tanzu.env}")
    private String env;

    private DiscoveryClient discoveryClient;

    public HelloResource(DiscoveryClient discoveryClient){
        this.discoveryClient = discoveryClient;
    }

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
        // hello-service matches the name of the application declared in asa-e
        String response = restTemplate.getForObject("http://hello-service", String.class);
        return String.format("Invoking hello-service : %s!", response);
    }
}