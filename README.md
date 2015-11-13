#Apogee

##Building Docker Container
1. `git submodule update --init --recursive`
2. `docker build -t apogee:dev .`

##Running in dev mode
1. docker run -p 0.0.0.0:3000:3000 --link mongo --link azkaban --link bolide --name apogee -it --rm --volume /root/apogee:/app  apogee:dev /bin/bash
2. ./runDev.sh
