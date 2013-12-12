package.path = './spec/?.lua;./lib/?.lua;'..package.path
require('spec_helper')

local utils = require('utils')

describe("Utils", function()
  describe(".box_name_from_host", function()

    it("returns the box name when box name is the only subdomain", function()
      result = utils.box_name_from_host('box-name.region.boxhost.com')
      assert.same("box-name", result)
    end)

    it("returns the box name when there are mutliple subdomains", function()
      result = utils.box_name_from_host('custom.box-name.region.boxhost.com')
      assert.same("box-name", result)
    end)

    it("returns nil when there are no subdomains", function()
      result = utils.box_name_from_host('region.boxhost.com')
      assert.same(nil, result)
    end)

    it("returns nil when host is empty", function()
      result = utils.box_name_from_host('')
      assert.same(nil, result)
    end)

    it("returns nil when host is nil", function()
      result = utils.box_name_from_host(nil)
      assert.same(nil, result)
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

    it("returns true if username and password are empty", function()
      result = utils.valid_auth(nil, "", "")
      assert.same(true, result)
    end)
  end)
end)
