mongo: mongod --port $MADEYE_MONGO_PORT --dbpath ./.meteor/local/db --smallfiles
redis: redis-server $MADEYE_HOME/madeye-dev/redis.conf
bolide: node ../bolide/app.js
azkaban: ../azkaban/node_modules/.bin/coffee ../azkaban/app.coffee
apogee: meteor --settings "$PWD/settings.json" --port $MADEYE_APOGEE_PORT
boggart: ../boggart/node_modules/.bin/coffee ../boggart/boggart.coffee
nurmengard: ../nurmengard/node_modules/.bin/coffee ../nurmengard/app.coffee
