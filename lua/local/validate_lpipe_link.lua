local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local client_utils = require("util.client_utils")
local util_time = require "util.time"

local content_dao = require "dao.content_dao"
local link_dao = require "dao.link_dao"
local task_dao = require "dao.task_dao"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local content_fields = {"link"}

local message = {}
message.code = 200

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local post_body = util_request.post_body(ngx.req)
-- log(ERR,"params:" ..tostring(post_body))
local message = {}
message.code = 200
if  not post_body then
    message.error = "illegal playload"
    message.code = 400
    local body = cjson_safe.encode(message)
    ngx.say(body)
    return
end

local params = cjson_safe.decode(post_body)

local fields = false
local year = util_time.year()
local from = params.from or 0
local size = params.size or 50
local filters = {}
local filter = {range = {["article.year"] = { lte = year }}}
table.insert(filters, filter)
local body = {
  from = from,
  size = size,
  sort = { ["lpipe.time"] = { order = "desc"},["article.year"] = { order = "desc"}},
  query = {
    bool = {
    filter = filters,
    must = {
         range = {
          lcount = { gte = 1}
        }
     }
    }
  }
}
local resp = content_dao:search(body)
local source_reg = "bdp-.*";
local content_fields = {"link"}
local task_count = 0
if resp and resp.hits then
    local hits = resp.hits.hits
    local task_docs = {}
    local lid_map = {}
    for _,v in ipairs(hits) do
     local target_id = v._id
     local from = 0
     local size = 10000
     local lresp = link_dao:query_by_targetid_source(target_id,source_reg,from, size,content_fields)
     if lresp and lresp.hits and lresp.hits.total > 0 then
         local hits = lresp.hits.hits;
         local shits = cjson_safe.encode(hits)
         -- log(ERR,"link-hits:" .. shits)
         for _,lv in ipairs(hits) do
            if not lid_map[lv._id] then
                local str_url = lv._source.link
                if not string.match(str_url, "^http") then
                    str_url = "https://pan.baidu.com/s/" .. str_url;
                end
                local task = {}
                task.type = "bdp-link-convert"
                task.url = str_url
                task.level = 0
                task.status = 0
                task.params = {tid = target_id,lid = lv._id, retry = { total = 5 } }
                table.insert(task_docs, task)
                task_count = task_count + 1
                lid_map[lv._id] = 1
            end
         end
     end
    end
    task_dao:insert_tasks(task_docs)
end
message.data = {task = task_count}
local body = cjson_safe.encode(message)
ngx.say(body)