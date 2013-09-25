package.path = './spec/?.lua;./lib/?.lua;'..package.path
require('spec_helper')

local utils = require('utils')

describe("Utils", function()
  describe(".parse_host", function()

    it("returns the box name when box name is the only subdomain", function()
      result = utils.parse_host('box-name.region.boxhost.com', 'region.boxhost.com')
      assert.same("box-name", result.box_name)
    end)

    it("returns the box name when there are mutliple subdomains", function()
      result = utils.parse_host('custom.box-name.region.boxhost.com', 'region.boxhost.com')
      assert.same("box-name", result.box_name)
    end)

    it("returns the port if it defined as a subdomain", function()
      result = utils.parse_host('p4444.box-name.region.boxhost.com', 'region.boxhost.com')
      assert.same(4444, result.port)
    end)

    it("returns the port as nil if it is not defined as a subdomain", function()
      result = utils.parse_host('p1sbd.box-name.region.boxhost.com', 'region.boxhost.com')
      assert.same(nil, result.port)
    end)

    it("returns nil when there are no subdomains", function()
      result = utils.parse_host('region.boxhost.com', 'region.boxhost.com')
      assert.same(nil, result.box_name)
    end)

    it("returns nil when host is empty", function()
      result = utils.parse_host('', 'region.boxhost.com')
      assert.same(nil, result.box_name)
    end)

    it("returns nil when host is nil", function()
      result = utils.parse_host(nil, 'region.boxhost.com')
      assert.same(nil, result.box_name)
    end)

    it("returns nil when hostname is nil", function()
      result = utils.parse_host('box-name.region.boxhost.com', nil)
      assert.same(nil, result.box_name)
    end)

  end)

  describe(".valid_auth", function()
    it("returns false if header is not provided", function()
      result = utils.valid_auth(nil, "username", "password")
      assert.same(false, result)
    end)

    it("returns false when header type is not Basic", function()
      result = utils.valid_auth("Someother dXNlcjpwYXNzd29yZA==\n", "username", "password")
      assert.same(false, result)
    end)

    it("returns false when header is an invalid format", function()
      result = utils.valid_auth("invalid_header", "username", "password")
      assert.same(false, result)
    end)

    it("returns false when hash is not well formed", function()
      result = utils.valid_auth("Basic ", "username", "password")
      assert.same(false, result)
    end)

    it("returns false if decoded hash doesnt contain a ke-value pair", function()
      result = utils.valid_auth("Basic nokeyvalue", "username", "password")
      assert.same(false, result)
    end)

    it("returns false if username or password is not provided", function()
      result = utils.valid_auth("Basic dXNlcjpwYXNzd29yZA==\n", "username", nil)
      assert.same(false, result)
    end)

    it("returns false if decoded pair doesn't match username and password", function()
      result = utils.valid_auth("Basic invalidusernamepwd", "username", "password")
      assert.same(false, result)
    end)

    it("returns true if decoded pair matches username and password", function()
      result = utils.valid_auth("Basic dXNlcm5hbWU6cGFzc3dvcmQ=\n", "username", "password")
      assert.same(true, result)
    end)

  end)
end)
