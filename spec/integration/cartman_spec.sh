#!/usr/env bash

# explicitly set the hostname
HOSTNAME=region.n2odev.com

# Other ENV variables are loaded from .env file.

# clean redis
echo "Cleaning Redis"
redis-cli -h $REDIS_HOST -p $REDIS_PORT -n $REDIS_DB flushdb

# stop the server
echo "Stopping Nginx"
script/test_server stop

# add entry to redis hash
echo "Preparing Redis database"
BOX="{\"ip\":\"127.0.0.1\",\"name\":\"sample-box\",\"containerState\":\"running\"}"
BOX_WITH_AUTH="{\"ip\":\"127.0.0.1\",\"name\":\"sample-box-auth\",\"authUsername\":\"user\",\"authPassword\":\"123\",\"containerState\":\"running\"}"
BOX_WITH_NULL_AUTH="{\"ip\":\"127.0.0.1\",\"name\":\"sample-box-null-auth\",\"authUsername\":null,\"authPassword\":null,\"containerState\":\"running\"}"
BOX_WITH_EMPTY_AUTH="{\"ip\":\"127.0.0.1\",\"name\":\"sample-box-null-auth\",\"authUsername\":\"\",\"authPassword\":\"\",\"containerState\":\"running\"}"
BOX_WITH_MODIFIED_AUTH="{\"ip\":\"127.0.0.1\",\"name\":\"sample-box-auth\",\"authUsername\":\"user\",\"authPassword\":\"12345\",\"containerState\":\"running\"}"
STOPPED_BOX="{\"ip\":\"127.0.0.1\",\"name\":\"sample-box-stopped\",\"containerState\":\"stopped\"}"

redis-cli -h $REDIS_HOST -p $REDIS_PORT -n $REDIS_DB hset aio:boxes sample-box "$BOX"
redis-cli -h $REDIS_HOST -p $REDIS_PORT -n $REDIS_DB hset aio:boxes sample-box-auth "$BOX_WITH_AUTH"
redis-cli -h $REDIS_HOST -p $REDIS_PORT -n $REDIS_DB hset aio:boxes sample-box-null-auth "$BOX_WITH_NULL_AUTH"
redis-cli -h $REDIS_HOST -p $REDIS_PORT -n $REDIS_DB hset aio:boxes sample-box-empty-auth "$BOX_WITH_EMPTY_AUTH"
redis-cli -h $REDIS_HOST -p $REDIS_PORT -n $REDIS_DB hset aio:boxes sample-box-stopped "$STOPPED_BOX"

# start the sample nginx server with conf
echo "Starting Nginx\n"
script/test_server -c spec/integration/nginx.conf

echo "Running tests"

test () {
  if [ "$1" -eq "$2" ]; then
    printf "."
  else
    printf "F"
    echo "\nexpected HTTP status to be $2, got $1"
  fi
}

# proxy to a server that has empty auth username and password
test `curl -sL -w "%{http_code}" http://sample-box-empty-auth.$HOSTNAME:6000 -o /dev/null` 200

# proxy to a server running on a available box (200)
test `curl -sL -w "%{http_code}" http://sample-box.$HOSTNAME:6000 -o /dev/null` 200

# proxy to a server running on a available box for post requests (200)
test `curl -sL -w "%{http_code}" --data "param=value" http://sample-box.$HOSTNAME:6000 -o /dev/null` 200

# give an error if the requested box is not available (503)
test `curl -sL -w "%{http_code}" http://dont-exist.$HOSTNAME:6000 -o /dev/null` 503

# give an error if the requested box is not running (503)
test `curl -sL -w "%{http_code}" http://sample-box-stopped.$HOSTNAME:6000 -o /dev/null` 503

# give an error if theres no server listening on given port in the proxied box (503)
test `curl -sL -w "%{http_code}" http://sample-box.$HOSTNAME:6001 -o /dev/null` 503

# give an error if theres no box speicified as a subdomain (503)
test `curl -sL -w "%{http_code}" http://$HOSTNAME:6000 -o /dev/null` 503

# request authorization if a box has enabled HTTP Auth and user provided invalid credentials (401)
test `curl -sL -w "%{http_code}" http://sample-box-auth.$HOSTNAME:6000 -o /dev/null` 401

# should not request authorization if a box has null Auth user name and password (401)
test `curl -sL -w "%{http_code}" http://sample-box-null-auth.$HOSTNAME:6000 -o /dev/null` 200

# proxy to server correctly if a box has enabled HTTP Auth and user provided valid credentials (200)
test `curl -sL -w "%{http_code}" -u user:123 http://sample-box-auth.$HOSTNAME:6000 -o /dev/null` 200

## test for the cache invalidation ##
# make a request first, this will cache the box details
curl -sL -u user:123 http://sample-box-auth.$HOSTNAME:6000 -o /dev/null

# modify box details in redis
redis-cli -h $REDIS_HOST -p $REDIS_PORT -n $REDIS_DB hset aio:boxes sample-box-auth "$BOX_WITH_MODIFIED_AUTH"

# send a request to clear the cached record
curl -sL http://127.0.0.1:6002/invalidate_cache?id=sample-box-auth -o /dev/null

# old password should give an auth error
test `curl -sL -w "%{http_code}" -u user:123 http://sample-box-auth.$HOSTNAME:6000 -o /dev/null` 401

# new password should work
test `curl -sL -w "%{http_code}" -u user:12345 http://sample-box-auth.$HOSTNAME:6000 -o /dev/null` 200

echo "\nCompleted the tests\n"

# clean redis
echo "Cleaning Redis"
redis-cli -h $REDIS_HOST -p $REDIS_PORT -n $REDIS_DB flushdb

# stop the server
echo "Stopping Nginx"
script/test_server stop
