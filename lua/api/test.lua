
local name = [[继承人2017]]
local name = [[1901继承人2017]]
local name = [[190继承人2017.ab]]
local name = [[<em>继承人</em>‎ (<em>2017</em>)]]

 local it, err = ngx.re.gmatch(name, "<em>(.+?)<\\/em>", "ijo")
 if not it then
     ngx.log(ngx.ERR, "error: ", err)
     return
 end

 while true do
     local m, err = it()
     if err then
         ngx.log(ngx.ERR, "error: ", err)
         return
     end

     if not m then
         -- no match found (any more)
         break
     end

     -- found a match
     ngx.say(m[1])
     -- ngx.say(m[1])
 end
 ngx.say("end")