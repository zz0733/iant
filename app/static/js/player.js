$(document).ready(function () {
    $('#topics-body').on('DOMNodeInserted', function (e) {
        var mediaElements = $('#topics-body div.video-box:not(:has(.mejs__offscreen)) video')
        mediaElements.mediaelementplayer({
            pluginPath: 'https://cdn.bootcss.com/mediaelement/4.2.9/',
            shimScriptAccess: 'always',
            stretching: 'fill',
            success: function (mediaElement, originalNode, instance) {
                console.log("mediaElement:" + mediaElement)
            }
        });
        return false;
    });
});