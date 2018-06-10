var $document = $(document);
$document.ready(function() {
    var options = {
        schema: {
            type: "object",
            properties: {
                name: { "type": "string" }
            }
        }
    }
    JSONEditor.defaults.options.theme = 'bootstrap2';
    $(".data-edit textarea").each(function(index, ele) {
        var self = $(ele)
        var $formGroup = self.parents('.form-group').first()
        var $updateBtn = $formGroup.find('div.update-btn')
        var $itemLi = self.parents('.item-box').first()
        var $inputImg = $itemLi.find('[id^=input-img]').first()
        var $videoCover = $itemLi.find('.video-cover').first()
        var $videoBoxCms = $itemLi.find('.video-box-cms').first()
        var editor = new JSONEditor(ele, options);
        var str_json = self.attr('data-link')
        str_json = str_json || "{}"
        // console.log('str_json:' + str_json);
        var data_json = JSON.parse(str_json)
        editor.setValue(data_json);
        editor.on("change", function() {
            var json = editor.getValue();
            ele.value = JSON.stringify(json, null, 2);
        })

        function validateJSON() {
            try {
                editor.setValue(JSON.parse(ele.value));
            } catch (e) {
                $formGroup.removeClass('has-success').addClass('has-error')
                $updateBtn.attr('disabled', true)
                return false;
            }
            var errors = editor.validate();
            if (errors.length) {
                $formGroup.removeClass('has-success').addClass('has-error')
                $updateBtn.attr('disabled', true)
            } else {
                $formGroup.removeClass('has-error').addClass('has-success')
                $updateBtn.attr('disabled', false)
            }
        }

        $formGroup.on('input propertychange', 'textarea', function() {
            validateJSON()
        })

        $('body').on('paste', function(e) {
            console.log('paste......');
            console.log('e:' + JSON.stringify(e.target));
            console.log('eeee:' + e);
        });

        //          var inputText = e.originalEvent.clipboardData.getData('text');
        //          console.log('inputText:' + inputText);
        // if(/http.*?\\.(jpg|png|gif)/i.test(inputText)) {
        //  var sImgURL = inputText
        //              console.log('pastedData:' + sImgURL);
        //              var xhr = new XMLHttpRequest();
        //           xhr.open('GET', sImgURL, true);
        //           xhr.responseType = "blob";
        //           // xhr.setRequestHeader("client_type", "DESKTOP_WEB");
        //           // xhr.setRequestHeader("desktop_web_access_key", _desktop_web_access_key);
        //           xhr.onload = function() {
        //               if (this.status == 200) {
        //                   var blob = this.response;
        //                   var img = document.createElement("img");
        //                   img.onload = function(e) {
        //                       window.URL.revokeObjectURL(img.src); 
        //                   };
        //                   img.src = window.URL.createObjectURL(blob);
        //                   console.log('sImgURL.img.src:' + img.src);
        //                   $("#hasmore").html(img);   
        //               }
        //           }
        //           xhr.send();
        // }
        $updateBtn.on('click', function() {
            if ($updateBtn.attr('disabled')) {
                return false
            }
            $formGroup.removeClass('has-success has-error')
            var data = editor.getValue()
            // console.log('data:' + JSON.stringify(data));
            var sBase = window.location.origin;
            var sUrl = sBase + "/api/movie/link.json?method=update_by_id";
            $.ajax({
                type: "POST",
                url: sUrl,
                data: JSON.stringify(data),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function(data) {
                    console.log('data:' + JSON.stringify(data))
                    $updateBtn.attr('disabled', true)
                },
                failure: function(errMsg) {
                    console.log('error:' + JSON.stringify(error))
                }
            });
        })

        var imgURL = $inputImg.attr('data-src')

        var btnCust = '';
        var tFooter = '<div class="file-thumbnail-footer">\n' + '    {progress}\n{actions}\n' + '</div>';
        var tPreview = '<div class="file-preview {class}">\n' + '    {close}' + '    <div class="{dropClass}">\n' + '    <div class="file-preview-thumbnails">\n' + '    </div>\n' + '    <div class="clearfix"></div>' + '    <div class="file-preview-status text-center text-success"></div>\n' + '    </div>\n' + '</div>';

        $inputImg.fileinput({
            uploadUrl: "/api/movie/image.upload",
            resizeImage: true,
            /**use to resize*/
            maxImageWidth: 515,
            maxImageHeight: 270,
            resizeImageQuality: 0.6,
            resizePreference: 'width',
            maxFileCount: 1,
            // maximum file size for upload in KB
            maxFileSize: 800,
            showClose: false,
            showRemove: false,
            showUpload: true,
            showCaption: false,
            showBrowse: false,
            browseOnZoneClick: true,
            msgErrorClass: 'alert alert-block alert-danger',
            defaultPreviewContent: '<img src="' + imgURL + '" alt="Your Avatar" class="video-img">',
            layoutTemplates: { main2: '{preview} ' + btnCust + ' {remove} {browse}', footer: tFooter, preview: tPreview },
            allowedFileExtensions: ["jpg", "png", "gif"]
        });
        $inputImg.on('filepreupload', function(event, data, previewId, index) {
            var form = data.form,
                files = data.files,
                extra = data.extra,
                response = data.response,
                reader = data.reader;
            console.log('File pre upload triggered:' + JSON.stringify(data));
        });
        $inputImg.on('fileuploaded', function(event, data, previewId, index) {
            var respJSON = data.response
            console.error("fileuploaded:...." + JSON.stringify(respJSON));
            if (respJSON.code != 200) {
                return
            }
            var imgURL = respJSON.data
            var index = imgURL.lastIndexOf('/')
            var imgName = imgURL.substring(index + 1)
            var data_json = editor.getValue();
            data_json.feedimg = imgName
            data_json.video = 1
            editor.setValue(data_json);
            // change image of defaultPreviewContent
            var fileinput = $inputImg.data('fileinput')
            var imgEle = $(fileinput.defaultPreviewContent)[0]
            imgEle.src = imgURL
            fileinput.defaultPreviewContent = imgEle.outerHTML
            $inputImg.fileinput('reset');
            $updateBtn.attr('disabled', false)
            $videoBoxCms.attr('captured', 'uploaded')
        });

        $inputImg.on('doupload', function(event) {
            $inputImg.fileinput('addToStack', event.originalEvent.detail.imgblob);
            var files = $inputImg.fileinput('getFileStack');
            if (files && files.length > 0) {
                $inputImg.fileinput('upload');
            }
        });

    })


    var $scriptEle = document.createElement('script');
    $scriptEle.src = '/assets/js/movie/stream.js'
    document.body.appendChild($scriptEle)
});