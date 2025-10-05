#!/bin/bash

echo "=========================================="
echo "  가상스레드 vs 플랫폼스레드 완전 비교 테스트"
echo "=========================================="
echo ""

# 서버 URL
SERVER_URL="http://localhost:8080"

# 테스트 설정
CONCURRENT_REQUESTS=200
TOTAL_REQUESTS=1000

echo "📊 테스트 설정:"
echo "   - 동시 요청 수: $CONCURRENT_REQUESTS"
echo "   - 총 요청 수: $TOTAL_REQUESTS"
echo "   - 플랫폼 스레드 수: 10개 (제한됨)"
echo "   - I/O 블로킹 시간: 500ms"
echo ""

# 결과 저장용 배열
declare -a results

run_test() {
    local test_name="$1"
    local endpoint="$2"
    
    echo "🚀 $test_name 테스트 시작..."
    echo "   시작 시간: $(date '+%H:%M:%S')"
    
    local start_time=$(date +%s.%N)
    
    # Apache Bench 실행 및 결과 파싱
    local ab_result=$(ab -n $TOTAL_REQUESTS -c $CONCURRENT_REQUESTS "$SERVER_URL/$endpoint" 2>/dev/null)
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l)
    
    # 결과 파싱
    local rps=$(echo "$ab_result" | grep "Requests per second" | awk '{print $4}')
    local avg_time=$(echo "$ab_result" | grep "Time per request.*mean" | awk '{print $4}')
    local failed_requests=$(echo "$ab_result" | grep "Failed requests" | awk '{print $3}')
    
    echo "   완료 시간: $(date '+%H:%M:%S')"
    echo "   총 소요 시간: $(printf "%.2f" $duration)초"
    echo "   초당 요청 수: $rps"
    echo "   평균 응답 시간: ${avg_time}ms"
    echo "   실패 요청 수: $failed_requests"
    echo ""
    
    # 결과 저장
    results+=("$test_name|$rps|$avg_time|$duration")
}

# 1단계: 가상스레드 활성화 테스트
echo "=========================================="
echo "  1단계: 가상스레드 활성화 환경"
echo "=========================================="
echo ""

echo "⚙️  가상스레드 활성화로 서버 시작 중..."
# 기존 프로세스 종료
pkill -f "java.*javavtnontest" 2>/dev/null || true
sleep 2

# 가상스레드 활성화로 서버 시작 (백그라운드)
./gradlew bootRun > /dev/null 2>&1 &
SERVER_PID=$!

# 서버 시작 대기
echo "   서버 시작 대기 중..."
for i in {1..30}; do
    if curl -s "$SERVER_URL/thread-info" > /dev/null 2>&1; then
        echo "   ✅ 서버 시작 완료"
        break
    fi
    sleep 1
    if [ $i -eq 30 ]; then
        echo "   ❌ 서버 시작 실패"
        exit 1
    fi
done

# 스레드 정보 확인
echo "   현재 스레드 설정:"
curl -s "$SERVER_URL/thread-info"
echo ""
echo ""

# 테스트 실행
run_test "가상스레드 + I/O 블로킹" "io-block"

# 서버 종료
kill $SERVER_PID 2>/dev/null || true
sleep 3

echo "=========================================="
echo "  2단계: 가상스레드 비활성화 환경"
echo "=========================================="
echo ""

echo "⚙️  가상스레드 비활성화로 서버 시작 중..."
# 가상스레드 비활성화로 서버 시작 (백그라운드)
./gradlew bootRun --args="--spring.profiles.active=virtual-false" > /dev/null 2>&1 &
SERVER_PID=$!

# 서버 시작 대기
echo "   서버 시작 대기 중..."
for i in {1..30}; do
    if curl -s "$SERVER_URL/thread-info" > /dev/null 2>&1; then
        echo "   ✅ 서버 시작 완료"
        break
    fi
    sleep 1
    if [ $i -eq 30 ]; then
        echo "   ❌ 서버 시작 실패"
        exit 1
    fi
done

# 스레드 정보 확인
echo "   현재 스레드 설정:"
curl -s "$SERVER_URL/thread-info"
echo ""
echo ""

# 테스트 실행
run_test "플랫폼스레드 + I/O 블로킹" "io-block"

# 서버 종료
kill $SERVER_PID 2>/dev/null || true

echo "=========================================="
echo "  📈 최종 결과 비교"
echo "=========================================="
echo ""

printf "%-25s %-12s %-15s %-12s\n" "테스트 환경" "초당요청수" "평균응답시간" "총소요시간"
echo "------------------------------------------------------------"

for result in "${results[@]}"; do
    IFS='|' read -r name rps avg_time duration <<< "$result"
    printf "%-25s %-12s %-15s %-12s\n" "$name" "$rps" "${avg_time}ms" "$(printf "%.2fs" $duration)"
done

echo ""
echo "💡 분석:"
echo "   - 가상스레드가 활성화되면 높은 동시성에서 더 나은 성능을 보입니다"
echo "   - 플랫폼 스레드 수(10개) < 동시 요청 수(200개) 조건에서 차이가 극명해집니다"
echo "   - I/O 블로킹 작업에서 가상스레드의 이점이 가장 잘 드러납니다"
echo ""
echo "🎯 결론: 가상스레드는 I/O 집약적 워크로드에서 확장성과 효율성을 크게 향상시킵니다!"
