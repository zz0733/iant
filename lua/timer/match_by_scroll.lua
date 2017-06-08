-- init_worker_by_lua
local link_dao = require "dao.link_dao"
local content_dao = require "dao.content_dao"
local cjson_safe = require("cjson.safe")
local delay = 1  -- in seconds
local done_wait = 60*60*5  -- in seconds
local new_timer = ngx.timer.at

local client_utils = require("util.client_utils")

local log = ngx.log
local ERR = ngx.ERR
local INFO = ngx.ERR
local CRIT = ngx.CRIT

local shared_dict = ngx.shared.shared_dict
local key_match_to_date = "match_to_date"
shared_dict:delete(key_match_to_date)

local key_match_scroll_id = "match_scroll_id"
shared_dict:delete(key_match_scroll_id)


local sourceClient = client_utils.client()
local sourceIndex = "content";
local query = {};
-- local scrollId = shared_dict:get(key_match_scroll_id)
local scroll = "1m";
local scanParams = {};
local bulkParams = {};

-- Performing a search query
scanParams.index = sourceIndex
-- scanParams.search_type = "scan"
scanParams.scroll = scroll
-- scanParams.sort = {"_doc"}
scanParams.size = 10
scanParams.body = query

local scan_count = 0

local match = ngx.re.match
local last_worker = ngx.worker.count() - 1

local intact = require("util.intact")
local util_table = require "util.table"
local extract = require("util.extract")
local similar = require("util.similar")
local match_handler = require("handler.match_handler")



local check

 check = function(premature)
     if not premature then
         local scrollId = nil
         local index = 0
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
             if data == nil or not data["_scroll_id"] or #data["hits"]["hits"] == 0 then
                local ok, err = new_timer(done_wait, check)
                if not ok then
                     log(CRIT, "done.failed to create timer: ", err)
                     return
                else
                    log(ERR, "done.wait["..done_wait.."],index:"..index..",scan:"..scan_count..",create timer: ")
                end
                scrollId = nil
                scan_count = 0
                break
             else
                 local total = data.hits.total
                 local hits = data.hits.hits
                 local shits = cjson_safe.encode(hits)
                 -- log(ERR,"hits:" .. shits)
                 scan_count = scan_count + #hits
                 ngx.update_time()
                 local cost = (ngx.now() - start)
                 cost = tonumber(string.format("%.3f", cost))
                 log(ERR,"scrollId["..tostring(scrollId) .. "],total:" .. total ..",hits:" .. tostring(#hits) 
                        .. ",scan:" .. tostring(scan_count)..",index:"..index..",cost:" .. cost)
                 match_handler.build_similars(hits)
                 scrollId = data["_scroll_id"]
             end
        end
     end
 end

 if 0 == ngx.worker.id() then
     log(ERR, "match_timer["..ngx.worker.id() .."] start")
     local ok, err = new_timer(delay, check)
     if not ok then
         log(ERR, "match_timer fail to run: ", err)
         return
     end
 end