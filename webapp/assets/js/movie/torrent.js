var $document = $(document);
$document.ready(function() {
		initClipboard()

		$('.btn-down:contains(百度离线)').on('click',function(){
             var self = this
             var toURL= 'http://pan.baidu.com/disk/home'
             window.open(toURL)
		})
		$('.btn-down:contains(百度云盘)').on('click',function(){
             var self = this
             var toURL= $('#link').val()
             window.open(toURL)
		})
		$('.btn-down:contains(迅雷离线)').on('click',function(){
             var self = this
             var toURL= 'http://lixian.xunlei.com/xl9/space.html'
             window.open(toURL)
		})
		$('.btn-down:contains(迅雷下载)').on('click',function(){
             var self = this
             var toURL= $('#link').val()
             var toURL = urlcodesc.encode(toURL, "thunder");
             window.location.href = toURL
		})

});

function initClipboard(){
	var btnClips = document.querySelectorAll('.btn-clipboard');
	for (var i = 0; i < btnClips.length; i++) {
	  btnClips[i].addEventListener('mouseleave', clearTooltip);
	  btnClips[i].addEventListener('blur', clearTooltip);
	}

	function clearTooltip(e) {
	  if(!e.currentTarget) {
	    return false
	  }
	  var target = e.currentTarget;
	  var sLabel = target.getAttribute('aria-label')
	  if(!sLabel) {
	    return false
	  }
	  var sCls = target.getAttribute('class')
	  sCls = sCls.replace(/tooltipped[-a-zA-Z]*/g,'')
	  e.currentTarget.setAttribute('class', sCls);
	  e.currentTarget.removeAttribute('aria-label');
	}

	function showTooltip(elem, msg) {
	  elem.setAttribute('class', 'btn-clipboard tooltipped tooltipped-s');
	  elem.setAttribute('aria-label', msg);
	}

	var tClipboard = new Clipboard('.btn-clipboard');
	tClipboard.on('success', function(e) {
	  e.clearSelection();
	  showTooltip(e.trigger, '复制成功');
	});
	tClipboard.on('error', function(e) {
	  e.clearSelection();
	  showTooltip(e.trigger, '复制失败');
	});
}