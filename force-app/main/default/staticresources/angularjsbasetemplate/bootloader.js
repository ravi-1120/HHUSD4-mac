
// sssl script loader - https://gist.github.com/aFarkas/936413

(function(){var d=document.getElementsByTagName("script")[0],f=d.parentNode,g=/ded|co/,e=function(b,c){var a=document.createElement("script");a.onload=a.onreadystatechange=function(){if(!this.readyState||g.test(this.readyState)){a.onload=a.onreadystatechange=null;c&&c(a);a=null}};a.async=true;a.src=b;f.insertBefore(a,d)};window.sssl=function(b,c){if(typeof b=="string")e(b,c);else{var a=b.shift();e(a,function(){if(b.length)window.sssl(b,c);else c&&c()})}}})();

function loadScripts(scripts, docRoot, callback) {
		docRoot = docRoot || document
    if (typeof scripts !== 'object') {
        alert('loadScripts(scripts) without array argument');
    }

    if (scripts.length === 0) {
    	callback();
      return;
    }
    
    // pull off 1st script in array
    var scriptDefinition = scripts.shift();

    // build script tag
    var headElement = docRoot.getElementsByTagName("head")[0];         
    var scriptElement = docRoot.createElement('script');
    scriptElement.type = 'text/javascript';
    scriptElement.src = scriptDefinition;
    
    var scriptLoadCompletedFunction = function() {        
        // load the rest (tail of array) of the scripts
        loadScripts(scripts, docRoot, callback);
    };
    
    // for ie
    scriptElement.onreadystatechange = function () {
        if (scriptElement.readyState == 'loaded' || scriptElement.readyState == 'complete') {
            scriptLoadCompletedFunction();
        }
    }

    scriptElement.onload = scriptLoadCompletedFunction;    

    // add script tag
    headElement.appendChild(scriptElement);    
}

/*
var link = document.createElement('link');
link.setAttribute('rel', 'stylesheet');
link.setAttribute('type', 'text/css');
link.setAttribute('href', '//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css');
document.getElementsByTagName('head')[0].appendChild(link);
*/

loadScripts(['https://localhost:35729/livereload.js?snipver=1', '//ajax.googleapis.com/ajax/libs/jquery/2.0.3/jquery.min.js'], document, function() {
	var $bodyEl = $('#bodyCell');
	var w = $bodyEl.width();
	var h = $bodyEl.height();

	$bodyEl.html('');

	var $iframe = $('<iframe src="/apex/blank" frameborder="0" scrolling="no" id="app-frame"></iframe>'); 
	$bodyEl.append($iframe);



	$iframe.width(w);
	$iframe.height(h);
	//$iframe.css('background', 'blue');

	window.$iframe = $iframe;

	$iframe.contents().ready(function() {


		var link = document.createElement('link');
		link.setAttribute('rel', 'stylesheet');
		link.setAttribute('type', 'text/css');
		link.setAttribute('href', '//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css');
		$iframe.contents().get(0).getElementsByTagName('head')[0].appendChild(link);


		loadScripts(['//static-01.s3.amazonaws.com/projects/angularjs-base-template/libs.js','//static-01.s3.amazonaws.com/projects/angularjs-base-template/app.js'], $iframe.contents().get(0), function() {

		});

	});


});

/*
sssl(['//ajax.googleapis.com/ajax/libs/jquery/2.0.3/jquery.min.js'], function() {

	var $bodyEl = $('#bodyCell');
	var w = $bodyEl.width();
	var h = $bodyEl.height();
	$bodyEl.html('');

	var $iframe = $('<iframe src="about:blank" frameborder="0" scrolling="no" id="app-frame"></iframe>'); 
	$bodyEl.append($iframe);

	$iframe.width(w);
	$iframe.height(600);
	$iframe.css('background', 'blue');

	var $head = $iframe.contents().find('head');
	var $script = $("<script>parent.window.sssl(['https://localhost:35729/livereload.js?snipver=1','//static-01.s3.amazonaws.com/projects/angularjs-base-template/libs.js','//static-01.s3.amazonaws.com/projects/angularjs-base-template/app.js']);</script>");
	$head.append($script);
	window.$iframe = $iframe;

});
*/

/*

sssl([
    'https://localhost:35729/livereload.js?snipver=1',
    '//static-01.s3.amazonaws.com/projects/angularjs-base-template/libs.js'
], function() {


function createIframe(id, appendToEl) {

    var iframe = document.createElement('iframe');
    //iframe.style.display = "none";
    iframe.src = 'about:blank';
    iframe.id = id;
    //iframe.height = '200px';
    //iframe.width = '100%';
    iframe.marginheight = '0';
    iframe.frameBorder  = '0';
    //document.body.appendChild(iframe);
    appendToEl.appendChild(iframe);
    frameDoc = iframe.contentDocument || iframe.contentWindow.document;
    frameDoc.documentElement.innerHTML = "";

    return iframe;
}

function autoResize(id){
    var newheight;
    var newwidth;

    if(document.getElementById){
        newheight=document.getElementById(id).contentWindow.document.body.scrollHeight;
        console.log(newheight);
        newwidth=document.getElementById(id).contentWindow.document.body.scrollWidth;
    }

    document.getElementById(id).height= (newheight) + "px";
    document.getElementById(id).width= (newwidth) + "px";
}

//autoResize(iframe.id);

var $bodyEl = $('#bodyCell');
var w = $bodyEl.width();
var h = $bodyEl.height();
$bodyEl.html('');

var id = 'app-frame';
var iframeEl = createIframe(id, $bodyEl.get(0));
var $iframeEl = $(iframeEl);
$iframeEl.width(w);
//$iframeEl.height(h);
$iframeEl.height(600);
$iframeEl.css('background', 'blue');

$iframeHeadEl = $($('#app-frame').get(0).contentDocument).find('head');

var cssLink = $("<link rel='stylesheet' type='text/css' href='//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css'>");
$iframeHeadEl.append(cssLink);


sssl(['//static-01.s3.amazonaws.com/projects/angularjs-base-template/app.js'], function() {});


});
*/