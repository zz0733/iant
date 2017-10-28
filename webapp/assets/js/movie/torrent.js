var $document = $(document);
$document.ready(function() {
     initClipboard()
		$('.btn-down:contains(百度离线)').on('click',function(){
             var self = this
             var toURL= 'http://pan.baidu.com/disk/home'
             doCopy()
             openPage(toURL)
        		 // initTour()
		})
		$('.btn-down:contains(百度云盘)').on('click',function(){
             var self = this
             var toURL= $('#link').val()
             if($('#btn-copy:contains("复制密码")').size() > 0){
               doCopy()
               window.open(toURL)
             } else {
               window.location.href = toURL
             }
            
		})
		$('.btn-down:contains(迅雷离线)').on('click',function(){
             var self = this
             var toURL= 'http://lixian.xunlei.com/xl9/space.html'
             doCopy()
             openPage(toURL)
		})
		$('.btn-down:contains(迅雷下载)').on('click',function(){
             var self = this
             var toURL= $('#link').val()
             var toURL = urlcodesc.encode(toURL, "thunder");
             window.location.href = toURL
		})
    if(/\/movie\/torrent\/b[0-9]+\.html$/.test(location.pathname) 
        && $('#btn-copy:contains("复制密码")').size() < 1){
             $('.btn-down:contains(百度云盘)').click()
    }
});

function openPage(toURL){
  if (isMobile()) {
      window.location.href = toURL
  } else {
      window.open(toURL)
  }
}

function isMobile(){
  return /^\/m\/movie/.test(location.pathname) 
}

function doCopy(){
  $('#btn-copy').select().click()
}

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

function initTour(){

var tour = new Tour({
  name: "tour",
  steps: [],
  container: "body",
  smartPlacement: true,
  keyboard: true,
  storage: window.localStorage,
  debug: false,
  backdrop: false,
  backdropContainer: 'body',
  backdropPadding: 0,
  redirect: true,
  orphan: false,
  duration: false,
  delay: false,
  basePath: "",
  template: '<div class="popover tour-tour tour-tour-1 fade top in" role="tooltip" id="step-1" style="top: 334.85px; left: 502px; display: block;"> <div class="arrow" style="left: 50%;"></div><div class="popover-content">Easy is better, right? The tour is up and running with just a few options and steps.</div> <div class="popover-navigation"> <div class="btn-group"> <button class="btn btn-sm btn-default" data-role="prev">« Prev</button> <button class="btn btn-sm btn-default" data-role="next">Next »</button>  </div> <button class="btn btn-sm btn-default" data-role="end">End tour</button> </div> </div>',
  afterGetState: function (key, value) {},
  afterSetState: function (key, value) {},
  afterRemoveState: function (key, value) {},
  onStart: function (tour) {},
  onEnd: function (tour) {},
  onShow: function (tour) {},
  onShown: function (tour) {},
  onHide: function (tour) {},
  onHidden: function (tour) {},
  onNext: function (tour) {},
  onPrev: function (tour) {},
  onPause: function (tour, duration) {},
  onResume: function (tour, duration) {},
  onRedirectError: function (tour) {}
});
  tour.addStep({
    element: "#btn-copy",
    placement: "right",
    title: "第一步",
    content: "①复制资源链接"
  })
  tour.addStep({
    element: "#btn-list",
    placement: "bottom",
    title: "第二步",
    content: "②获取资源"
  })
    console.log('init.......')
  // Initialize the tour
  tour.init();
  console.log('start.......')
  // Start the tour
  tour.start(true);
}