mongo: mongod --port $MADEYE_MONGO_PORT --dbpath ./.meteor/local/db
redis: redis-server $MADEYE_HOME/madeye-dev/redis.conf
bolide: node ../bolide/app.js
azkaban: ../azkaban/node_modules/.bin/coffee ../azkaban/app.coffee
apogee: mrt --port $MADEYE_APOGEE_PORT
