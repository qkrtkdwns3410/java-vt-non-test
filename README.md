# Java Virtual Thread 성능 비교 테스트

## 🎯 프로젝트 목적

Java 21의 **가상스레드(Virtual Threads)**와 기존 **플랫폼스레드(Platform Threads)** 간의 성능 차이를 실제 부하테스트를 통해 검증하는 프로젝트입니다.

## 📋 테스트 내용

### 테스트 시나리오
- **I/O 블로킹 작업**: 파일 읽기, 네트워크 호출 등을 시뮬레이션
- **동시성 테스트**: 200개 동시 요청 vs 10개 플랫폼 스레드 제한
- **부하테스트**: Apache Bench를 활용한 성능 측정

### 비교 대상
1. **가상스레드 활성화**: `spring.threads.virtual.enabled=true`
2. **가상스레드 비활성화**: `spring.threads.virtual.enabled=false`

## 🚀 실행 방법

### 자동화된 비교 테스트
```bash
# 완전 자동화된 성능 비교 테스트 실행
./full_comparison_test.sh
```

### 수동 테스트
```bash
# 가상스레드 활성화
./gradlew bootRun

# 가상스레드 비활성화
./gradlew bootRun --args="--spring.profiles.active=virtual-false"
```

## 📊 테스트 API

| 엔드포인트 | 설명 | 블로킹 타입 |
|-----------|------|------------|
| `GET /block` | 1초 Thread.sleep | CPU 블로킹 |
| `GET /io-block` | 파일 I/O 시뮬레이션 | I/O 블로킹 |
| `GET /thread-info` | 현재 스레드 정보 확인 | - |

## 🔧 기술 스택

- **Java**: 21 (가상스레드 정식 지원)
- **Spring Boot**: 3.5.6
- **빌드 도구**: Gradle
- **부하테스트**: Apache Bench (ab)

## 📈 기대 결과

가상스레드는 다음과 같은 상황에서 성능상 이점을 보입니다:

- **높은 동시성**: 플랫폼 스레드 수 < 동시 요청 수
- **I/O 집약적 작업**: 데이터베이스 조회, 외부 API 호출
- **확장성**: 수천 개의 동시 연결 처리

## 🎯 테스트 목표

가상스레드가 실제로 **확장성과 효율성**을 크게 향상시키는지, 특히 **I/O 블로킹 상황에서의 성능 개선**을 검증합니다.
