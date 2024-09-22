// bootstrap

// hide ourselves from the sidebar navigation
var componentName = 'JSPlugins';
jQuery("h2:contains('" + componentName + "')").parent().parent().hide();

// parse the salesforce pod out of URL
var pod = location.hostname.split('.')[0];

// build visual force url
var scriptURL = '//c.' + pod + '.visual.force.com/apex/MRK_JSPlugins';

// load script
jQuery.getScript(scriptURL);
