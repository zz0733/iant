local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local context = require "util.context"

local content_dao = require "dao.content_dao"

local log = ngx.log
local ERR = ngx.ERR

local str_today = ngx.today()
local m = ngx.re.match(str_today, "([0-9]{4})")
local cur_year = 2016
if m and m[1] then
	cur_year = tonumber(m[1])
end
local from_year = cur_year - 2;
local from = 0;
-- index.max_result_window = 10000
local size = 5000;
local body = {
  from = from,
  size = size,
  sort = {_score = { order = "desc"}, ["article.year"] = { order = "desc"}},
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
 -- maximum of 50,000 URLs and must be no larger than 50MB
 -- https://www.sitemaps.org/protocol.html
local dest_xml = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>http://www.lezomao.com/</loc><priority>1.0</priority><changefreq>hourly</changefreq></url>'
local resp = content_dao:search(body)
if resp and resp.hits and resp.hits.hits then
	local hits = resp.hits.hits;
	log(ERR,"sitemap,total:" .. resp.hits.total .. ",size:" .. #hits)
	for _,v in ipairs(hits) do
		local url_node = '<url><loc>http://www.lezomao.com/movie/detail/'..v._id..'.html</loc></url>'
		dest_xml = dest_xml .. url_node
	end
end
dest_xml =dest_xml .. '</urlset>'
ngx.say(dest_xml)
ngx.flush()