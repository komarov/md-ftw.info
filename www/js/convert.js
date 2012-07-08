$(document).ready(function() {
    var options = {
        beforeSubmit: function() {
            $('#convert').attr('disabled', 'disabled');
        },
        success: function(task_id) {
            var delay = 550;
            var download = function(task_id) {
                $.get('/convert/' + task_id + '/status', function(status) {
                    if (status === 'ready') {
                        var link_name = $('input[name="src_file"]').val();
                        link_name = link_name.replace(/.*[/\\]/, '');
                        link_name += '.pdf';
                        var download_url = '/convert/' + task_id + '/download?filename=' + link_name;
                        document.location.href = download_url;
                        $('#links').prepend('<div><a href="' + download_url + '"><i class="icon-download-alt" />' + link_name + '</a></div>');
                        $('#convert').text('Converted');
                    } else {
                        setTimeout(function(){download(task_id)}, delay);
                    }
                });
            };
            setTimeout(function(){download(task_id)}, delay);
        }
    };
    $('form').ajaxForm(options);
    $('input[name="src_file"]').change(function() {
        $('#convert').removeAttr('disabled');
        $('#convert').text('Convert');
    });
});
