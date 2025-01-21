ports=("3333" "3334")
ip="127.0.0.1"

# 3333과 3334포트에 spring boot가 띄워져 있는지 확인
for port in "${ports[@]}";
do
  echo "http://$ip:$port/management/health_check"
  RESPONSE=$(curl -s http://$ip:$port/management/health_check)
  IS_ACTIVE=$(echo ${RESPONSE} | grep 'UP' | wc -l)

  if [ $IS_ACTIVE -eq 1 ];
  then
    echo -e "$port에 spring boot가 실행중입니다."
  else
    echo -e "$port에 spring boot가 실행 중이 아닙니다."
    echo -e "$port에 spring boot를 실행시킵니다."
    nohup /usr/local/java/java21/bin/java -Dserver.port=$PORT_2 -jar ~/api/target/target/api.jar > log_$PORT_2 2>&1 &

    for retry in {1..10}
    do
      RESPONSE=$(curl -s http://$ip:$port/management/health_check)
      PORT_HEALTH=$(echo ${RESPONSE} | grep 'UP' | wc -l)
      if [ $PORT_HEALTH -eq 1 ]
      then
        break
      else
        echo -e "$ip:$port가 켜져있지 않습니다. 10초 슬립하고 다시 헬스체크를 수행합니다."
        sleep 10
      fi
    done
  fi
done


