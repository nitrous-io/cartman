package.path = './spec/?.lua;./lib/?.lua;'..package.path

local utils = require('utils')

describe("Utils", function()
  describe(".parse_host", function()

    describe("when boxname is the only subdomain", function()
      it("returns the box name", function()
        result = utils.parse_host('box-name.region.boxhost.com', 'region.boxhost.com')
        assert.same("box-name", result.box_name)
      end)
    end)

    describe("when there are multiple subdomains", function()
      it("returns the box name", function()
        result = utils.parse_host('custom.box-name.region.boxhost.com', 'region.boxhost.com')
        assert.same("box-name", result.box_name)
      end)
    end)

    describe("when there are no subdomains", function()
      it("returns nil", function()
        result = utils.parse_host('region.boxhost.com', 'region.boxhost.com')
        assert.same(nil, result.box_name)
      end)
    end)

    describe("when host is empty", function()
      it("returns nil", function()
        result = utils.parse_host('', 'region.boxhost.com')
        assert.same(nil, result.box_name)
      end)
    end)

  end)
end)
