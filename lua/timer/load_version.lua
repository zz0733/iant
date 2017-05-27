-- load new version for asset

 if 0 == ngx.worker.id() then
     require("util.context").version(ngx.time())
 end