local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ssdb_idf = require("ssdb.idf"):new()

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local method = args.method

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT
local exptime = 600

local find = ngx.re.find

local postBody = util_request.post_body(ngx.req)
-- ngx.say('insert_scripts.body,script:' .. script)
local from, to, err = ngx.re.find(postBody, "(\r\n\r\n)", "jo")
if to and to > 0 then
  postBody = string.sub(postBody, to)
  from, to, err = ngx.re.find(postBody, "(\r\n[\\-]+[0-9a-z]+[\\-]+\r\n)", "jo")
  if not err and from > 0 then
     postBody = string.sub(postBody,0, from)
  end
end
local uCount = 0
local line_arr = string.split(postBody,'\n')
for _,line in ipairs(line_arr) do
  local unit_arr = string.split(line,"%s")
  local idf_key = unit_arr[1]
  local idf_val = unit_arr[2]
  if idf_key and idf_val then
      local bSet = ssdb_idf:setValue(idf_key,idf_val)
      if bSet == false then
         log(ERR,"fail.ssdb_idf_set," .. idf_key .. "=" .. idf_val)
      else
         uCount = uCount + 1
      end
  end
end


local message = {}
message.data = {total = #line_arr, update= uCount}
message.code = 200
local body = cjson_safe.encode(message)
ngx.say(body)