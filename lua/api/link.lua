-- ngx.say("errx:")
local elasticsearch = require "elasticsearch"

local client = elasticsearch.client{
    hosts = {
      { -- Ignoring any of the following hosts parameters is allowed.
        -- The default shall be set
        protocol = "http",
        host = "localhost",
        port = 9200
      }
    },
    -- Optional parameters
    params = {
      pingTimeout = 2
    }
  }

local data, err = client:info()

if not data then
	ngx.say("err:" .. err)
else
	ngx.ngx.say('data:' + data)
end