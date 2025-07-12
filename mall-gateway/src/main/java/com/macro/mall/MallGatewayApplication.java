package com.macro.mall;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.context.ConfigurableApplicationContext;

@EnableDiscoveryClient
@SpringBootApplication
public class MallGatewayApplication {

    public static void main(String[] args) {
        // 检测环境变量是否加载
        String nacosAddr = System.getenv("NACOS_ADDR");
        System.out.println("环境变量 NACOS_ADDR: " + (nacosAddr != null ? nacosAddr : "未设置，使用默认值"));

        ConfigurableApplicationContext context = SpringApplication.run(MallGatewayApplication.class, args);

        String serverAddr = context.getEnvironment().getProperty("spring.cloud.nacos.discovery.server-addr");
        System.out.println("✅ 最终连接的 Nacos Server 地址: " + serverAddr);
    }

}
