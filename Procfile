#NOTE with hombrew nginx logs to /usr/local/var/log/nginx/
#specify the rest of the versions in here
#nginx version should == 1.4.3
nginx: nginx -c $PWD/../nginx.conf -p $MADEYE_HOME/integration-tests
mongo: mongod --port $MADEYE_MONGO_PORT --dbpath ./.meteor/local/db --smallfiles --replSet rs0
redis: redis-server $MADEYE_HOME/integration-tests/madeye-dev/redis.conf
bolide: node ../bolide/app.js
azkaban: ../azkaban/node_modules/.bin/coffee ../azkaban/app.coffee
apogee: mrt --settings "$PWD/settings.json" --port $MADEYE_APOGEE_PORT --raw-logs
