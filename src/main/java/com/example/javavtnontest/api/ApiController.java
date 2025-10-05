package com.example.javavtnontest.api;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.time.Duration;

@RestController
public class ApiController {

    // "/block"으로 요청이 오면 1초 동안 멈췄다가 응답하는 API
    @GetMapping("/block")
    public String block() throws InterruptedException {
        // DB 조회나 외부 API 호출 같은 I/O 작업을 1초간의 sleep으로 흉내 냅니다.
        Thread currentThread = Thread.currentThread();
        System.out.println("Thread: " + currentThread.getName() + 
                          ", Virtual: " + currentThread.isVirtual() + 
                          ", Thread Group: " + currentThread.getThreadGroup().getName());
        
        Thread.sleep(Duration.ofSeconds(1));
        return "Done";
    }
    
    // 더 현실적인 I/O 블로킹 시뮬레이션 (파일 읽기)
    @GetMapping("/io-block")
    public String ioBlock() throws InterruptedException {
        Thread currentThread = Thread.currentThread();
        System.out.println("IO-Thread: " + currentThread.getName() + 
                          ", Virtual: " + currentThread.isVirtual());
        
        // 실제 I/O 블로킹 작업 시뮬레이션
        try {
            // 파일 읽기 시뮬레이션
            java.nio.file.Files.readAllLines(
                java.nio.file.Paths.get("/dev/urandom"), 
                java.nio.charset.StandardCharsets.UTF_8
            );
        } catch (Exception e) {
            // 파일이 없으면 sleep으로 대체
            Thread.sleep(Duration.ofMillis(500));
        }
        
        return "IO-Done";
    }
    
    // 가상스레드 정보 확인용 엔드포인트
    @GetMapping("/thread-info")
    public String threadInfo() {
        Thread currentThread = Thread.currentThread();
        return String.format("Thread: %s, Virtual: %s, Thread Group: %s", 
                           currentThread.getName(), 
                           currentThread.isVirtual(),
                           currentThread.getThreadGroup().getName());
    }
}
