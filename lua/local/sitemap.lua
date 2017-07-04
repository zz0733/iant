local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local client_utils = require("util.client_utils")

local log = ngx.log
local ERR = ngx.ERR


local str_today = ngx.today()
local m = ngx.re.match(str_today, "([0-9]{4})")
local cur_year = 2016
if m and m[1] then
	cur_year = tonumber(m[1])
end
local from_year = cur_year - 2;
-- index.max_result_window = 10000
local body = {
  from = from,
  size = size,
  _source = false,
  sort = {["article.year"] = { order = "desc"}},
  query = {
   bool = {
	  filter = {
	      range = {
	        ["article.year"] = {
	          lte = cur_year,
	          gte = from_year
	        }
	      }
	   }
    }
  }
}

local sourceClient = client_utils.client()
local sourceIndex = "content";
local scroll = "1m";
local scanParams = {};
scanParams.index = sourceIndex
scanParams.scroll = scroll
-- scanParams.sort = {"_doc"}
scanParams.size = 100
scanParams.body = body

local scan_count = 0
local scrollId = nil
local index = 0
local total = nil
local begin = ngx.now()
local dest_xml = ""
while true do
     index = index + 1;
     local data,err;
     local start = ngx.now()
     if not scrollId then
         data, err = sourceClient:search(scanParams)
     else
        data, err = sourceClient:scroll{
          scroll_id = scrollId,
          scroll = scroll
        }
     end
     -- local shits = cjson_safe.encode(data)
     -- log(ERR,"data:" .. shits .. ",err:" .. tostring(err))
     if data == nil or not data["_scroll_id"] or #data["hits"]["hits"] == 0 then
        local cost = (ngx.now() - begin)
         cost = tonumber(string.format("%.3f", cost))
        log(ERR, "create.sitemap,index:"..index..",scan:"..scan_count..",total:" .. tostring(total) .. ",cost:" .. cost)
        break
     else
		 total = data.hits.total
		 local hits = data.hits.hits
		 local shits = cjson_safe.encode(hits)
		 log(ERR,"hits:" .. shits)
		 scan_count = scan_count + #hits
        for _,v in ipairs(hits) do
            local url_node = '<url><loc>http://www.lezomao.com/movie/detail/'..v._id..'.html</loc></url>'
			dest_xml = dest_xml .. url_node .. "\n"
        end
        scrollId = data["_scroll_id"]
     end
end
ngx.say(dest_xml)
ngx.flush()