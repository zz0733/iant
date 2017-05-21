  function urlcodesc(){
    var oFormat = this.oFormat = {};
    oFormat['qqdl'] = 'qqdl://encode("sourceUrl")';
    oFormat['flashget'] = 'flashget://encode("[FLASHGET]sourceUrl[FLASHGET]")';
    oFormat['thunder'] = 'thunder://encode("AAsourceUrlZZ")';
  }

  urlcodesc.prototype.extractModel = function(sUrl){
    if(/^([a-zA-Z]+):\/\//.test(sUrl)){
      var sModel = RegExp.$1;
      return sModel.toLowerCase();
      }
  };
  urlcodesc.prototype.encode = function(sUrl,model){
    var self =  this;
    var sFormat = self.oFormat[model];
    if(!sFormat){
      return sUrl;
    }
    if(/(encode\(.*\))/.test(sFormat)){
        var sEncode = RegExp.$1;
        sUrl = (unescape(encodeURIComponent(sUrl)))

        var sEncodeFn =sEncode.replace('encode','btoa');
        sEncodeFn =sEncodeFn.replace('sourceUrl',sUrl);
        var sEncodeUrl = eval(sEncodeFn);
        return sFormat.replace(sEncode,sEncodeUrl);
    }

  };
  urlcodesc.prototype.decode = function(sUrl){
    var self =  this;
    var sModel = self.extractModel(sUrl);
    var sFormat = self.oFormat[sModel];
    if(!sFormat){
      return sUrl;
    }
    if(/(encode\(.*\))/.test(sFormat)){
        var sEncode = RegExp.$1;
        var sEncodeFn =sEncode.replace('encode','atob');
        sEncodeFn =sEncodeFn.replace('sourceUrl',sUrl);
        var sDecodeUrl = eval(sEncodeFn);
        sDecodeUrl = decodeURIComponent(escape(sDecodeUrl));
        return sDecodeUrl;
    }
  };
  
  var urlcodesc = new urlcodesc();
