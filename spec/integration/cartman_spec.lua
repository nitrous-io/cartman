package.path = './spec/?.lua;./lib/?.lua;'..package.path
local redis = require 'redis'
local cjson = require 'cjson'
local http  = require 'socket.http'

local hostname = 'region.n2odev.com'
local redis_client = nil

describe('Cartman', function()
  setup(function()
    local redis_params = {
      host = os.getenv('REDIS_HOST'),
      port = os.getenv('REDIS_PORT'),
      timeout = 1000
    }
    redis_client, err = redis.connect(redis_params)
    if err then
      error('Failed to connect to Redis: '..err)
    end
    redis_client:select(os.getenv('REDIS_DB'))
    redis_client:flushdb()

    os.execute("script/test_server -c spec/integration/nginx.conf")
  end)

  teardown(function()
    os.execute("script/test_server stop")
    redis_client:quit()
  end)

  describe("when a server is running inside a container", function()
    setup(function()
      local payload = cjson.encode({ ip = "127.0.0.1",
                                     name = "sample-box",
                                     containerState = "running"
                                   })
      redis_client:hset('aio:boxes', 'sample-box', payload)
    end)

    teardown(function()
      redis_client:flushdb()
    end)

    it("proxies GET requests to the server", function()
      response, status = http.request("http://sample-box."..hostname..":6000")
      assert.same(200, status)
    end)

    it("proxies POST requests to the server", function()
      response, status = http.request("http://sample-box."..hostname..":6000", "param=value")
      assert.same(200, status)
    end)
  end)

  describe("when box does not exist", function()
    it("responds with a 503 status", function()
      response, status = http.request("http://dont-exist."..hostname..":6000")
      assert.same(503, status)
    end)
  end)

  describe("when there's no server listening to given port inside the box", function()
    setup(function()
      local payload = cjson.encode({ ip = "127.0.0.1",
                                     name = "sample-box",
                                     containerState = "running"
                                   })
      redis_client:hset('aio:boxes', 'sample-box', payload)
    end)

    teardown(function()
      redis_client:flushdb()
    end)

    it("responds with a 502 status", function()
      -- testing server listens to only port 6000, as defined in spec/integration/nginx.conf
      response, status = http.request("http://sample-box."..hostname..":6001")
      assert.same(502, status)
    end)
  end)

  describe("when the request does not contain a subdomain identifying a box", function()
    it("responds with a 503 status", function()
      response, status = http.request("http://"..hostname..":6000")
      assert.same(503, status)
    end)
  end)

  describe("when HTTP Auth credentials available for the box", function()
    setup(function()
      local payload = cjson.encode({ ip = "127.0.0.1",
                                     name = "sample-box-auth",
                                     containerState = "running",
                                     authUsername = "user",
                                     authPassword = "123"
                                   })
      redis_client:hset('aio:boxes', 'sample-box-auth', payload)
    end)

    teardown(function()
      redis_client:flushdb()
    end)

    it("responds with a 401 status for requests without username and password", function()
      response, status = http.request("http://sample-box-auth."..hostname..":6000")
      assert.same(401, status)
    end)

    it("responds with a 401 status for requests with invalid username and password", function()
      response, status = http.request("http://user1:12345@sample-box-auth."..hostname..":6000")
      assert.same(401, status)
    end)

    it("responds with a 200 status for requests with valid username and password", function()
      response, status = http.request("http://user:123@sample-box-auth."..hostname..":6000")
      assert.same(200, status)
    end)
  end)

  describe("when HTTP Auth credentials given for the box are empty", function()
    setup(function()
      local payload = cjson.encode({ ip = "127.0.0.1",
                                     name = "sample-box-empty-auth",
                                     containerState = "running",
                                     authUsername = "",
                                     authPassword = ""
                                   })
      redis_client:hset('aio:boxes', 'sample-box-empty-auth', payload)
    end)

    teardown(function()
      redis_client:flushdb()
    end)

    it("responds with a 200 status for valid requests without username and password", function()
      response, status = http.request("http://sample-box-empty-auth."..hostname..":6000")
      assert.same(200, status)
    end)
  end)

  describe("when HTTP Auth for the box are null", function()
    setup(function()
      local payload = cjson.encode({ ip = "127.0.0.1",
                                     name = "sample-box-null-auth",
                                     containerState = "running",
                                     authUsername = nil,
                                     authPassword = nil 
                                   })
      redis_client:hset('aio:boxes', 'sample-box-null-auth', payload)
    end)

    teardown(function()
      redis_client:flushdb()
    end)

    it("responds with a 200 status for valid requests without username and password", function()
      response, status = http.request("http://sample-box-null-auth."..hostname..":6000")
      assert.same(200, status)
    end)
  end)

  describe("invalidating cache for individual items", function()
    setup(function()
      local payload = cjson.encode({ ip = "127.0.0.1",
                                     name = "sample-box-cached",
                                     containerState = "running",
                                     authUsername = 'user',
                                     authPassword = '123'
                                   })

      redis_client:hset('aio:boxes', 'sample-box-null-auth', payload)

      -- make a request first, this will cache the box details
      http.request("http://sample-box-cached."..hostname..":6000")

      -- modify the box details in redis
      local modified_payload = cjson.encode({ ip = "127.0.0.1",
                                              name = "sample-box-cached",
                                              containerState = "running",
                                              authUsername = 'user2',
                                              authPassword = '12345'
                                            })
      redis_client:hset('aio:boxes', 'sample-box-cached', modified_payload)

      -- send a request to clear the cached item
      http.request("http://127.0.0.1:6002/invalidate_cache?id=sample-box-cached")
    end)

    teardown(function()
      redis_client:flushdb()
    end)

    it("responds with a 401 status for requests with old username and password", function()
      response, status = http.request("http://user:123@sample-box-cached."..hostname..":6000")
      assert.same(401, status)
    end)

    it("responds with a 200 status for requests with new username and password", function()
      response, status = http.request("http://user2:12345@sample-box-cached."..hostname..":6000")
      assert.same(200, status)
    end)
  end)

  describe("custom domains", function()
    setup(function()
      local payload = cjson.encode({ ip = "127.0.0.1",
                                     name = "sample-box",
                                     containerState = "running"
                                   })
      redis_client:hset('aio:boxes', 'sample-box', payload)

      redis_client:hset('aio:domains', 'wtf.local', 'sample-box')
    end)

    teardown(function()
      redis_client:flushdb()
    end)

    it("proxies requests for registered custom domains", function()
      response, status = http.request("http://wtf.local:6000")
      assert.same(200, status)
    end)

    it("responds with a 503 status for requests with non-registered custom domains", function()
      response, status = http.request("http://another.local:6000")
      assert.same(503, status)
    end)

  end)
end)
