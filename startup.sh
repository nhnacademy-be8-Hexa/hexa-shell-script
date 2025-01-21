#!/bin/bash

# 포트 배열과 IP 설정
ports=("3333" "3334")
ip="127.0.0.1"
NGINX_CONF="/etc/nginx/nginx.conf"

# 각 포트를 점검하며 Spring Boot 상태 확인 및 배포 수행
for port in "${ports[@]}";
do
  echo -e "===== http://$ip:$port/acutator/health 확인 중 ====="
  RESPONSE=$(curl -s http://$ip:$port/actuator/health)
  IS_ACTIVE=$(echo ${RESPONSE} | grep 'UP' | wc -l)

  if [ $IS_ACTIVE -eq 1 ]; then
    echo -e "$port에 Spring Boot가 실행 중입니다."
    echo -e "nginx 설정파일에서 $port를 제거합니다."

    # Nginx에서 현재 포트를 제외
    echo "nhnacademy" |  sudo -S sed -i "/127.0.0.1:$port/d" "$NGINX_CONF"
    echo "nhnacademy" |  sudo -S nginx -t
    echo "nginx를 reload합니다."
    echo "nhnacademy" | sudo -S nginx -s reload
    sleep 3

    # 기존 프로세스 종료
    echo -e "$port 포트의 기존 애플리케이션 종료"
    fuser -s -k -TERM $port/tcp
    sleep 10

    # 새 애플리케이션 실행
    echo -e "jar 파일을 $port 포트에 실행합니다."
    nohup /usr/local/java/java21/bin/java -Dserver.port=${port} -Dspring.profiles.active=prod,local -jar ~/target/target/hello.jar > log_$port 2>&1 &

    # Health Check 재확인
    for retry in {1..10}; do
      echo -e "$ip:$port Health Check 재확인 중 (시도 $retry)"
      RESPONSE=$(curl -s http://$ip:$port/actuator/health)
      PORT_HEALTH=$(echo ${RESPONSE} | grep 'UP' | wc -l)

      if [ $PORT_HEALTH -eq 1 ]; then
        echo -e "$ip:$port에 Spring Boot가 정상적으로 실행 중입니다."
        break
      else
        echo -e "$ip:$port가 아직 켜져있지 않습니다. 10초 후 재시도합니다."
        sleep 10
      fi
    done

    # 최종 Health Check 결과 확인
    if [ $PORT_HEALTH -ne 1 ]; then
      echo -e "Error: $ip:$port에 애플리케이션이 정상 실행되지 않았습니다. 종료합니다."
      exit 1
    fi

    # Nginx 설정에 새 포트 추가
    echo -e "nginx 설정파일에 $ip:$port를 추가합니다."
    echo "nhnacademy" | sudo -S sed -i "/ip_hash;/ a \    server 127.0.0.1:$port;" "$NGINX_CONF"
    echo "nhnacademy" | sudo -S nginx -t
    echo "nginx를 reload합니다."
    echo "nhnacademy" | sudo -S  nginx -s reload
    sleep 3

     

  else
    echo -e "$port 포트에 Spring Boot가 실행 중이 아닙니다. 새 애플리케이션을 실행합니다."
    nohup /usr/local/java/java21/bin/java -Dserver.port=${port} -Dspring.profiles.active=prod,local -jar ~/target/target/hello.jar > log_$port 2>&1 &

    # Health Check 수행
    for retry in {1..10}; do
      echo -e "$ip:$port Health Check 중 (시도 $retry)"
      RESPONSE=$(curl -s http://$ip:$port/actuator/health)
      PORT_HEALTH=$(echo ${RESPONSE} | grep 'UP' | wc -l)

      if [ $PORT_HEALTH -eq 1 ]; then
        echo -e "$ip:$port에 Spring Boot가 정상적으로 실행 중입니다."
        break
      else
        echo -e "$ip:$port가 아직 켜져있지 않습니다. 10초 후 재시도합니다."
        sleep 10
      fi
    done

    if [ $PORT_HEALTH -ne 1 ]; then
      echo -e "Error: $ip:$port에 애플리케이션이 정상 실행되지 않았습니다. 종료합니다."
      exit 1
    fi

    
  fi
done

echo -e "===== 모든 포트에 대한 Spring Boot 점검 및 배포 완료 ====="


