#!/usr/env bash

REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_DB=5
HOSTNAME=`hostname`

# add entry to redis hash
echo "Preparing Redis database"
BOX_DATA="{\"ip\":\"127.0.0.1\",\"name\":\"sample-box\"}"
BOX_WITH_AUTH_DATA="{\"ip\":\"127.0.0.1\",\"authUsername\":\"user\",\"authPassword\":\"123\",\"name\":\"sample-box-auth\"}"

redis-cli -h $REDIS_HOST -p $REDIS_PORT -n $REDIS_DB hset aio:boxes sample-box "$BOX_DATA"
redis-cli -h $REDIS_HOST -p $REDIS_PORT -n $REDIS_DB hset aio:boxes sample-box-auth "$BOX_WITH_AUTH_DATA"

# start the sample nginx server with conf
echo "Starting Nginx\n"
script/server -c spec/integration/nginx.conf

echo "Running tests"

test () {
  if [ "$1" -eq "$2" ]; then
    printf "."
  else
    printf "F"
    echo "\nexpected HTTP status to be $2, got $1"
  fi
}

# proxy to a server running on a available box (200)
test `curl -sL -w "%{http_code}" http://sample-box.$HOSTNAME:6000 -o /dev/null` 200

# proxy to a server running on a available box for post requests (200)
test `curl -sL -w "%{http_code}" --data "param=value" http://sample-box.$HOSTNAME:6000 -o /dev/null` 200

# give an error if the requested box is not available (503)
test `curl -sL -w "%{http_code}" http://dont-exist.$HOSTNAME:6000 -o /dev/null` 503

# give an error if theres no server listening on given port in the proxied box (503)
test `curl -sL -w "%{http_code}" http://sample-box.$HOSTNAME:6001 -o /dev/null` 503

# give an error if theres no box speicified as a subdomain (503)
test `curl -sL -w "%{http_code}" http://$HOSTNAME:6000 -o /dev/null` 503

# give an authorization error if a box has enabled HTTP Auth and user provided invalid credentials (401)
test `curl -sL -w "%{http_code}" http://sample-box-auth.$HOSTNAME:6000 -o /dev/null` 401

# proxy to server correctly if a box has enabled HTTP Auth and user provided valid credentials (200)
test `curl -sL -w "%{http_code}" -u user:123 http://sample-box-auth.$HOSTNAME:6000 -o /dev/null` 200

echo "\nCompleted the tests\n"

# clean redis
echo "Cleaning Redis"
redis-cli -h $REDIS_HOST -p $REDIS_PORT -n $REDIS_DB flushdb

# stop the server
echo "Stopping Nginx"
script/server stop
