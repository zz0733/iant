var $document = $(document);
$document.ready(function() {
    var $linkmore = $("#linkmore");
    // $linkmore.delegate(".link-left > a.link-href[tid]",'click', function(e) {
    // 	var self = $(this);
    // 	// self.attr('disabled',"disabled");
    // 	var tid = self.attr('tid');
    // 	var sBase = window.location.origin;
    // 	var sUrl = sBase+"/api/movie/link.json";
    // 	console.log('sUrl:'+sUrl+',tid:'+tid)
    // 	$.getJSON(sUrl, {
    // 		'id' : tid
    // 	}, function(result) {
    // 	   console.log('result:'+JSON.stringify(result))
    // 	   if(result && result.data ) {
    // 	   	   var data = result.data
    // 	   	   var link = data.link;
    // 	   	   if (/^b/ig.test(tid)) {
    // 	   	   	    // console.log('link:' + link)
    // 				window.location.href= link
    // 	   	   } else {
    // 		   	   var thunder = urlcodesc.encode(link, "thunder");
    //                   // console.log('thunder:' + thunder)
    //                   location.href= thunder
    //                      return false;
    // 	   	   }

    // 	   }
    // 	});
    // });

    $linkmore.delegate("div.up:has(.link-digg)", 'click', function(e) {
        var self = $(this);
        self.attr('disabled', "disabled");
        var tidEls = self.parents(".link-box").find(".link-href[tid]");
        // console.log('tidEls:'+ JSON.stringify(tidEls.first()))

        var link_id = tidEls.first().attr('tid');
        var tid = null;
        if (/detail\/([0-9]+)\.html/i.test(location.href)) {
            tid = RegExp.$1
        }
        var sBase = window.location.origin;
        var sUrl = sBase + "/api/movie/link.json?method=incr_bury_digg&id=" + link_id;
        // console.log('sUrl:'+sUrl+',link_id:'+link_id+",tid:" + tid)
        $.ajax({
            type: "POST",
            url: sUrl,
            data: JSON.stringify({
                tid: tid,
                digg: 1
            }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function(data) {
                console.log('data:' + JSON.stringify(data))
            },
            failure: function(error) {
                console.log('error:' + JSON.stringify(error))
            }
        });
    });

    $linkmore.delegate("div.down:has(.link-bury)", 'click', function(e) {
        var self = $(this);
        var tidEls = self.parents(".link-box").find(".link-href[tid]");
        var link_id = tidEls.first().attr('tid');
        var tid = null;
        if (/detail\/([0-9]+)\.html/i.test(location.href)) {
            tid = RegExp.$1
        }
        var sBase = window.location.origin;
        var sUrl = sBase + "/api/movie/link.json?method=incr_bury_digg&id=" + link_id;
        console.log('sUrl:' + sUrl + ',link_id:' + link_id + ",tid:" + tid)
        $.ajax({
            type: "POST",
            url: sUrl,
            data: JSON.stringify({
                tid: tid,
                bury: 1
            }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function(data) {
                console.log('data:' + JSON.stringify(data))
            },
            failure: function(error) {
                console.log('error:' + JSON.stringify(error))
            }
        });

        var boxEls = self.parents('div.link-box');
        boxEls.remove();

    });

    // 元素下方没显示的高度值小于TRIGGER_SCROLL_SIZE时，触发滚动
    // var TRIGGER_SCROLL_SIZE = 50;
    // var isLoading = false;
    // // $container 为显示数据内容的元素
    // $(document).scroll(function () {
    //   var $container = $(this)
    //   if(!isLoading){
    //     var totalHeight = $container.prop("scrollHeight");
    //     var scrollTop = $container.scrollTop();
    //     var height = $container.height();
    //     		      console.log("totalHeight:"+totalHeight)
    //     		      console.log("scrollTop:"+scrollTop)
    //     		      console.log("height:"+height)
    //     if(totalHeight - (height + scrollTop) <= TRIGGER_SCROLL_SIZE){
    //       isLoading = true;
    //       // 加载更多数据
    //       console.log("scrollTopxxxx:"+scrollTop)
    //     }
    //   }
    // });

    var did = $('#did').val()
    var title = $('#title').val()
    var albumId = $('#albumId').val();
    var epindex = parseInt($('#epindex').val());
    var way = null
    var from = 0

    function loadLinkPage() {
        var moreCls = $linkmore.attr("class")
        if ("link-more" != moreCls) {
            return false;
        }
        title = encodeURI(title)
        var sBase = window.location.origin;
        var sUrl = sBase + "/api/movie/link_post.json?method=next_links";

        // console.log('sUrl:' + sUrl + ",epindex:" + epindex)
        var oParams = {
            'did': did,
            'title': title,
            'albumId': albumId,
            'epindex': epindex,
            'way': way,
            'from': from
        }
        return $.ajax({
            type: 'POST',
            url: sUrl,
            data: JSON.stringify(oParams),
            success: doSuccess,
            dataType: "json"
        });

        function doSuccess(result) {
            // console.log('result:'+JSON.stringify(result))
            if (result && result.data) {
                var data = result.data;
                from = data.from;
                way = data.way;
                var hits = data.hits;
                var hasCount = (hits && hits.length) || 0
                if (hasCount > 0) {
                    var template = ''
                    template += '<div class="link-box">'
                    template += '   <div class="link-left">'
                    template += '    <a href="{{link_url}}" class="{{link_class}}" tid="{{v._id}}">'
                    template += '	   	<div class="link-tip">'
                    template += '		    <span class="badge link-index">{{str_index}}</span>'
                    template += '		    {{str_space_html}}'
                    template += ' 	    </div>'
                    template += ' 	  	 <div class="link-title">'
                    template += ' 	  			{*v._source.title*}'
                    template += ' 	  	</div>'
                    template += '	 	  <div class="link-down">'
                    template += '		 	   	  <sapn class="link-time">{{str_time}}</sapn>'
                    template += '		 	   	  <sapn class="link-source">{{btn_txt}}</sapn>'
                    template += '	 	 </div>'
                    template += ' 	 </a>'
                    template += '   </div>'
                    template += '   <div class="link-right">'
                    template += '     <div class="up">'
                    template += '     	 <span class="link-digg glyphicon glyphicon-thumbs-up" aria-hidden="true">{{digg_num}}</span>'
                    template += '     </div>'
                    template += '     <div class="mid"></div>'
                    template += '     <div class="down">'
                    template += '     	  <span class="link-bury glyphicon glyphicon-remove-circle"></span>'
                    template += '     </div>'
                    template += '   </div>'
                    template += '</div>'
                    var fromIndex = $linkmore.find('div.link-box').length;
                    // console.log('result.hits:'+JSON.stringify(hits))
                    for (var i = 0; i < hits.length; i++) {
                        var hit = hits[i]
                        var curIndex = fromIndex + i + 1;
                        var str_index = ""
                        if (curIndex < 10) {
                            str_index = "0"
                        }
                        str_index += curIndex;
                        var icon_cls = "icon10";
                        var str_time = "2017-05-03";
                        var btn_txt = "离线下载";
                        var id = hit._id;
                        var v_source = hit._source;
                        var update_time = v_source.ctime
                        var space = v_source.space || 0
                        var str_space_html = ""
                        var link_class = "link-href"
                        if (/^b[0-9]+$/.test(id)) {
                            btn_txt = "百度云盘";
                            if (v_source.space) {
                                if ((v_source.space == 0 || v_source.space == 1024)) {
                                    icon_cls = "icon61"
                                } else {
                                    space = space / 1024 / 1024
                                    var str_space;
                                    if (space > 1024) {
                                        space = space / 1024
                                        space = space.toFixed(2)
                                        str_space = space + "G";
                                    } else {
                                        space = space.toFixed(2)
                                        str_space = space + "M";
                                    }
                                    str_space_html = '<span class="link-space">{{str_space}}</span>'
                                    str_space_html = str_space_html.replace('{{str_space}}', str_space)
                                }
                            }
                            if (v_source.issuseds) {
                                var issuseds = v_source.issuseds
                                for (var si = 0; si < issuseds.length; si++) {
                                    var issused = issuseds[si]
                                    if (issused.time) {
                                        update_time = issused.time
                                    }
                                }
                            }
                        }
                        if (update_time) {
                            var updateDate = new Date(update_time * 1000)
                            var mm = updateDate.getMonth() + 1;
                            var dd = updateDate.getDate();
                            mm = mm < 10 ? '0' + mm : mm;
                            dd = dd < 10 ? '0' + dd : dd;
                            str_time = mm + '-' + dd
                        }
                        var destHtml = template
                        var contentId =  hit._id || hit._source.id
                        var title = hit._source.title
                        title = title.trim()
                        destHtml = destHtml.replace('{{link_class}}', link_class)
                        if (hit._source.media == 1) {
                        	btn_txt = "在线观看"
                        	destHtml = destHtml.replace('{{link_url}}', '/movie/detail/' + contentId + '.html')
                        } else {
                        	destHtml = destHtml.replace('{{link_url}}', '/movie/torrent/' + contentId + '.html')
                        }
                        destHtml = destHtml.replace('{{v._id}}', contentId)
                        destHtml = destHtml.replace('{{str_index}}', str_index)
                        destHtml = destHtml.replace('{{str_space_html}}', str_space_html)
                        // destHtml = destHtml.replace('{{icon_cls}}',icon_cls)
                        destHtml = destHtml.replace('{*v._source.title*}', title)
                        destHtml = destHtml.replace('{{str_time}}', str_time)
                        destHtml = destHtml.replace('{{btn_txt}}', btn_txt)
                        destHtml = destHtml.replace('{{digg_num}}', '')
                        $linkmore.append(destHtml)
                    }
                }
                
                if (!data.hasMore) {
                    $linkmore.attr('class', 'link-no-more')
                } else {
                    if ($linkmore.find('.link-box').length < 1) {
                        loadLinkPage();
                    }
                }
                return data.hasMore;
            }
        }
    }
    $(window).scroll(function() {　　
        var $this = $(this);
        var scrollHeight = $document.height()
        var scrollTop = $this.scrollTop();
        var windowHeight = $this.height();
        var per = (scrollTop + windowHeight) / scrollHeight
        // console.log("per:" + per + ",windowHeight:" + windowHeight + ",scrollHeight:"+ scrollHeight);
        if (per >= 0.75) {
            loadLinkPage();　　
        }
    });
	loadLinkPage();　　
});