fuser -k 8080/tcp 2>/dev/null


/usr/local/java/java21/bin/java -Dserver.port=8080 -jar ~/gateway/target/hello.jar > log   2>&1 &
