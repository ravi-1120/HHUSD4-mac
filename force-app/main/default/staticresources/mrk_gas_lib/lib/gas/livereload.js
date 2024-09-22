(function() {
    
    window.livereload = {

        reloadPageIfScriptChanges: function(patterns, pollInterval) {
        	patterns = $.isArray(patterns) ? patterns : [patterns];
        	$.ajaxSetup({ cache: false });
        	var digests = {};

            var urlsToCheck = [];

            $('script[src]').each(function() {
        		var src = $(this).attr('src');

        		if( $.grep(patterns, function(p) {
        			return p.test(src);
        		}).length == 0) {
        			return;
        		}
        		urlsToCheck.push(src);
        	});

            var changeCheck = function(urls) {

            	$.each(urls, function(idx, src) {
            	    console.log(src);
            	    $.ajax({
                         url: src,
                         dataType: 'text', // Notice! JSONP <-- P (lowercase)
                         success:function(data){
                            console.log(data);

                 			var md5 = hex_md5(data);
                 			if ( (typeof digests[src] === 'undefined') ) {
                 				digests[src] = md5;
                 			} else if (digests[src] !== md5) {
                 				console.log(src + ' changed.  reloading page');
                 				location.href = location.href;
                 			}

                         },
                         error:function(a, b, c){
                             console.log(a);
                             console.log(b);
                             console.log(c);
                         }
                    });

                    // $.get(src, function(data) {
                    //  var md5 = hex_md5(data);
                    //  if ( (typeof digests[src] === 'undefined') ) {
                    //      digests[src] = md5;
                    //  } else if (digests[src] !== md5) {
                    //      console.log(src + ' changed.  reloading page');
                    //      location.href = location.href;
                    //  }
                    // }, 'html');


            	});


            };

            // set for first run
            setInterval(function() {
                changeCheck(urlsToCheck);
            }, pollInterval);
        }
        
    };
    
})();
