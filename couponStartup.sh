
PORT_1=8083
PORT_2=8084

# 1. 8083을 DOWN 상태로 설정
echo "Setting $PORT_1 to DOWN in Eureka..."
# Health Check 수행
for i in {1..10}; do
    echo "Checking health of the new application on port $PORT_1 (attempt $i)"
    if curl -s http://localhost:$PORT_1/actuator/health | grep -q '"status":"UP"'; then
        echo "Application running on port $PORT_1"
        break
    fi
    sleep 5
done
curl -X POST http://localhost:$PORT_1/actuator/status/down
if [ $? -ne 0 ]; then
  echo "Failed to set $PORT_1 to DOWN."
fi

fuser -k $PORT_1/tcp 2>/dev/null

nohup /usr/local/java/java21/bin/java -Dserver.port=$PORT_1 -Dspring.profiles.active=prod -jar ~/coupon/target/coupon-api.jar > log_$PORT_1 2>&1 &
# Health Check 수행
for i in {1..10}; do
    echo "Checking health of the new application on port $PORT_1 (attempt $i)"
    if curl -s http://localhost:$PORT_1/actuator/health | grep -q '"status":"UP"'; then
        echo "New application is running successfully on port $PORT_1"
        break
    fi
    sleep 5
done
# 2. 8084를 DOWN 상태로 변경
echo "Setting $PORT_2 to Down in Eureka..."
# Health Check 수행
for i in {1..10}; do
    echo "Checking health of the new application on port $PORT_2 (attempt $i)"
    if curl -s http://localhost:$PORT_2/actuator/health | grep -q '"status":"UP"'; then
        echo "Application running on port $PORT_2"
        break
    fi
    sleep 5
done
curl -X POST http://localhost:$PORT_2/actuator/status/down
if [ $? -ne 0 ]; then
  echo "Failed to set $PORT_2 to DOWN."
fi
fuser -k $PORT_2/tcp 2>/dev/null
nohup /usr/local/java/java21/bin/java -Dserver.port=$PORT_2 -Dspring.profiles.active=prod -jar ~/coupon/target/coupon-api.jar > log_$PORT_2 2>&1 &
# Health Check 수행
for i in {1..10}; do
    echo "Checking health of the new application on port $PORT_2 (attempt $i)"
    if curl -s http://localhost:$PORT_2/actuator/health | grep -q '"status":"UP"'; then
        echo "New application is running successfully on port $PORT_2"
        break
    fi
    sleep 5
done
