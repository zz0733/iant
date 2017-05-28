$(function(){
    /*
     * 复制到剪切板
     * @see https://github.com/zenorocha/clipboard.js
     */
    if(typeof Clipboard != 'function'){
        return false; /*避免未引入Clipboard抛错*/
    }
    var clipboard = new Clipboard('#idCopy');
    clipboard.on('success', function(e) {
        console.log('复制成功');
    });
});

function Checker(target) {
  var self = this
  self.progress = 0
  self.target = target
  // self.target.secret = 'target'
  self.results = []
  var checkers = self.checkers = []
  var task = {}
  task.execute = function(doc, cb) {
    var html = ''
    var success = true
    var count = 1
    if (doc.link) {
      html += '<div class="alert alert-success" role="alert">'
      html += '<strong>(' + count + ').</strong>获取资源，【' + doc.title + '】'
      if (doc.secret) {
        var copyEle = $('#idCopy')
        if (copyEle) {
          copyEle.attr('data-clipboard-text', doc.secret)
        }
        html += '(提取码：' + doc.secret + '&nbsp;)&nbsp;'
        html += '<a id="jumpTo" class="jumpTo alert-link" href="javascript:void(0)"  onclick="doCopy(); jumpTo(\'' + doc.link + '\')">复制提取码并跳转[?]</a> '
      } else {
        html += '<a id="jumpTo" class="jumpTo alert-link" href="javascript:void(0)" onclick="jumpTo(\'' + doc.link + '\')">直接跳转[?]</a> '
      }
      html += '</div>'
    } else {
      html += '<div class="alert alert-danger" role="alert">'
      html += '<strong>(' + count + ').</strong>获取资源， 资源失效或不存在！'
      html += '</div>'
      success = false
    }
    var ret = {
      success: success,
      html: html
    }
    return cb(ret)
  }
  checkers.push(task)

  task = {}
  task.execute = function(doc, cb) {
    var period = self.target.secret ? 5000 : 200
    setTimeout(function() {
      var success = true
      var ret = {
        success: success
      }
      return cb(ret)
    }, period);
  }
  checkers.push(task)

  task = {}
  task.execute = function(doc, cb) {
    var html = ''
    var success = true
    var count = 2
    html += '<div class="alert alert-success" role="alert">'
    html += '<strong>(' + count + ').</strong>检测完成，正在前往百度云...'
    html += '</div>'
    var ret = {
      success: success,
      html: html
    }
    return cb(ret)
  }
  checkers.push(task)

}

Checker.prototype.start = function() {
  var self = this
  self.doProgress()
    // 
  self.success = -1
  var per = 100 / self.checkers.length
  per = Math.ceil(per)
  // console.log('checkers:' + self.checkers.length + ",per:" + per)

  var index = 0
  function handle(ret) {
    // console.log('handle:' + (++index) + ",ret:" + JSON.stringify(ret))
    if (ret) {
      ret.incr = per
      self.results.push(ret);
    }
    if (ret.success) {
      var task = self.checkers.shift()
      if (task) {
        task.execute(self.target, handle)
      } else {
        self.success = 1
      }
    } else {
      self.success = 0
    }
  }
  self.checkers.shift().execute(self.target, handle)

}

Checker.prototype.stop = function() {
  var self = this
  self.tprogress && clearTimeout(self.tprogress)
}

Checker.prototype.end = function() {
  var self = this
  jumpTo(self.target.link)
}

Checker.prototype.doIncr = function(incr) {
  var self = this
  if (!incr) {
    return
  }
  self.progress = self.progress + incr
  self.progress = self.progress > 100 ? 100 : self.progress
}

Checker.prototype.doProgress = function() {
  var self = this
  if (self.success < 0) {
    var incr = random(1, 5)
    if (incr + self.progress < 98) {
      self.doIncr(incr)
    }
  }
  var task = self.results.shift()
  if (task) {
    self.doIncr(task.incr)
    if (task.html) {
      $('#checking').append(task.html)
    }
  }

  var num = self.progress;
  var pEle = $("#progress");
  // pEle.attr('aria-valuenow', ""+ num);
  pEle.attr('style', "width: " + num + "%;");
  pEle.text(num + "%")

  self.tprogress = setTimeout(function() {
    if (self.progress < 100) {
      self.doProgress()
    } else {
      self.end()
    }
  }, random(100, 1000));

}
var chekcer = new Checker(target)
chekcer.start()

function random(min, max) {
  return Math.floor(Math.random() * (max - min + 1) + min);
};

function doCopy() {
  $('#idCopy').click()
  return false;
}
function jumpTo(tid) {
  if (!tid) {
    return false
  }
  var jumpEle = $("#jumpTo")
  chekcer.stop()
  jumpEle.attr('disabled', "disabled");
  location.href = tid
  return false;
}