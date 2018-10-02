$(document).ready(function() {
    $("a[href]:has(>[id^=form])").on('click', function(e) {
        var oForm = $(this).find('[id^=form]');
        oForm.submit();
        console.log('oForm')
        return false;
    });

    $('.link-group-left').delegate(".link-title[href]", 'click', function(e) {
        var oTargets = $(this).parents('.link-box').find('.btn.target-btn')
        if (oTargets && oTargets[0]) {
            oTargets[0].click()
        }
        return false;
    });
    $('.link-group-left').delegate(".target-btn[tid]", 'click', function(e) {
        var self = $(this);
        self.attr('disabled', "disabled");
        var tid = self.attr('tid');
        var sBase = window.location.origin;
        var sUrl = sBase + "/api/movie/link.json";
        console.log('sUrl:' + sUrl + ',tid:' + tid)
        $.getJSON(sUrl, {
            'id': tid
        }, function(result) {
            console.log('result:' + JSON.stringify(result))
            if (result && result.data) {
                var data = result.data
                var thunder = urlcodesc.encode(data.link, "thunder");
                console.log('thunder:' + thunder)
                window.location.href = thunder
            }
        });
    });
    var way = null
    var from = 0
    $('.link-group-left').delegate(".link-more", 'click', function(e) {
        var self = $(this);
        var did = $('#did').val()
        var title = $('#title').val()
        var albumId = $('#albumId').val();
        var epindex = parseInt($('#epindex').val());
        title = encodeURI(title)
        var sBase = window.location.origin;
        var sUrl = sBase + "/api/movie/link_post.json?method=next_links";
        console.log('sUrl:' + sUrl + ",epindex:" + epindex)
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
            console.log('result:'+JSON.stringify(result))
            if (result && result.data) {
                var data = result.data;
                from = data.from;
                way = data.way;
                var hits = data.hits;
                var template = ''
                template += '<li class="list-group-item link-box">'
                template += '     <span class="badge left-badge">{{str_index}}</span>'
                template += '     <span class="link-icon {{icon_cls}}"></span>'
                template += '     <div>'
                template += '       <a href="javascript:void(0)" class="link-title">'
                template += '     	{{title}}'
                template += '      </a>'
                template += '    </div>'
                template += '    <span>{{str_time}}</span>'
                template += '    {{link_tempate}}'
                template += '</li>'
                var hasCount = (hits && hits.length) || 0
                if (hasCount > 0) {
                    var fromIndex = self.parent().find('li.link-box').length;
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
                        // id = 'v0476600749'
                        var v_source = hit._source;
                        var update_time = v_source.ctime
                        var link_tempate = '<button type="button" class="btn target-btn" tid= "{{v._id}}">{{btn_txt}}</button>'
                        var link_tempate = '<a href="/movie/torrent/{{v._id}}.html" rel="nofollow" target="_blank" role="button" class="btn target-btn" >{{btn_txt}}</a>'
                        if (/^b[0-9]+$/.test(id)) {
                            btn_txt = "百度云盘";
                            link_tempate = '<a href="/movie/torrent/{{v._id}}.html" rel="nofollow" target="_blank" role="button" class="btn target-btn" >{{btn_txt}}</a>'
                            if (v_source.space && (v_source.space == 0 || v_source.space == 1024)) {
                                icon_cls = "icon61"
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
                        } else if (/^m[0-9]+$/.test(id)) {
                            btn_txt = "磁力资源";
                            link_tempate = '<a href="/movie/torrent/{{v._id}}.html" rel="nofollow" target="_blank" role="button" class="btn target-btn" >{{btn_txt}}</a>'
                            if (v_source.space && (v_source.space == 0 || v_source.space == 1024)) {
                                icon_cls = "icon61"
                            }
                        } else if (/^v[0-9]+$/.test(id)) {
                            btn_txt = "在线播放";
                            link_tempate = '<a href="/movie/play/{{v._id}}.html" rel="nofollow" target="_blank" role="button" class="btn target-btn" >{{btn_txt}}</a>'
                            if (v_source.space && (v_source.space == 0 || v_source.space == 1024)) {
                                icon_cls = "icon61"
                            }
                            // 暂不可用了
                            continue
                        }
                        if (update_time) {
                            var updateDate = new Date(update_time * 1000)
                            var yyyy = updateDate.getFullYear();
                            var mm = updateDate.getMonth() + 1;
                            var dd = updateDate.getDate();
                            mm = mm < 10 ? '0' + mm : mm;
                            dd = dd < 10 ? '0' + dd : dd;
                            str_time = yyyy + '-' + mm + '-' + dd
                        }
                        link_tempate = link_tempate.replace('{{v._id}}', hit._id)
                        link_tempate = link_tempate.replace('{{btn_txt}}', btn_txt)
                        var destHtml = template
                        destHtml = destHtml.replace('{{str_index}}', str_index)
                        destHtml = destHtml.replace('{{icon_cls}}', icon_cls)
                        destHtml = destHtml.replace('{{title}}', hit._source.title)
                        destHtml = destHtml.replace('{{str_time}}', str_time)
                        destHtml = destHtml.replace('{{link_tempate}}', link_tempate)
                        self.before(destHtml)
                    }
                }
                if (!data.hasMore) {
                    var hasCount = self.parent().find('li.link-box').length;
                    var tip = "已获取全部资源"
                    if (hasCount < 1) {
                        tip = "暂无资源"
                    }
                    self.find('li').text(tip);
                    self.attr('class', 'link-no-more')
                    self.unbind()
                } else if (data.hasMore) {
                	if (hasCount < 1 ) {
						self.click()
                	} else {
                       self.find('li').text("获取更多资源");
                	}
                }
                // console.log('data:' + JSON.stringify(data))
            }
        }
    });

    var moreEle = $(".link-no-more");
    moreEle.attr('class', "link-more")
    moreEle.click();
    var videoURL = 'https://aikanapi.duapp.com/odflv1217/index.php?url=http://www.iqiyi.com/v_19rrf3gvu8.html'
    var videoHtml = '<iframe id="iframepage" allowfullscreen="ture" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" src="VIDEO_URL" height="100%" width="100%"></iframe>'
    videoHtml = videoHtml.replace('VIDEO_URL', videoURL)
    // $('.container-fluid > div.row').replaceWith(videoHtml)

});