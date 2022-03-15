ip=$(hostname -I | awk '{gsub(/^\s+|\s+$/, "");print}')
nohup java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=${ip}:5005 -jar jrudf-jar-with-dependencies.jar >jrudf.log 2>&1 &