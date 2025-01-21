fuser -k 8761/tcp 2>/dev/null


nohup /usr/local/java/java21/bin/java -Dserver.port=8761 -jar ~/eureka/target/hello.jar > /dev/null 2>&1 &

