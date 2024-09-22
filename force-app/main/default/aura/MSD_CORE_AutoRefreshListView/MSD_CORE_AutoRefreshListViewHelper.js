({
    getListViewDetials:function(component,event)
    {
        var action = component.get("c.getLVDetails"); 
        var self = this;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                component.set("v.objListViewNames",data);
                if(!$A.util.isEmpty(data))
                {
                	self.checkURLChange(component);
                }
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
        
    },                               
   checkURLChange : function(component)
   {  
        window.setInterval(() => {
            component.set("v.pageURL",window.location.href);
            }, 1000);
   },
   
setIntervalTime : function(component)
{
    var self = this;
    var refreshInterval = component.get("v.refreshInterval");
    var isValid = component.get("v.isValid"); 
    var myMap = component.get("v.objListViewNames");
    let urlString = component.get("v.pageURL");
    component.set("v.pageURL",urlString);
    let isListURL = urlString.search("list");    
    if(isListURL != -1)
    {
		let currentListViewID = urlString.substring(urlString.lastIndexOf("=")+1,urlString.length);
		let currentListViewSobject = urlString.substring(urlString.lastIndexOf("o/")+2,urlString.indexOf("/list?filterName"));
		var objLVIDs = myMap[currentListViewSobject.toUpperCase()];
		if(!$A.util.isEmpty(objLVIDs) && !$A.util.isEmpty(currentListViewSobject))
		{
			for(var key in objLVIDs)
			{
				if(objLVIDs[key].listViewIDs.toUpperCase() === currentListViewID.toUpperCase())
				{
					isValid = true;
					refreshInterval = objLVIDs[key].refreshInterval
                    component.set('v.isValid',isValid);
                    component.set('v.refreshInterval',refreshInterval);
					break;
				}
            }                                   
		}                         
      
	}
    else
    {
            component.set('v.isValid',false);
            const intervalId = component.get('v.intervalId');
            window.clearInterval(intervalId);
            component.set('v.intervalId', null);
    }
        if(isValid)
        {
            const intervalId = window.setInterval(() => {
                self.refreshListView(component);
            }, refreshInterval);
                component.set('v.intervalId', intervalId);
        }
        else
        {
                component.set('v.isValid',false);
                const intervalId = component.get('v.intervalId');
                window.clearInterval(intervalId);
                component.set('v.intervalId', null);
        }
},

refreshListView : function(component) {
let navigationItemAPI = component.find("navigationItemAPI");
navigationItemAPI.getSelectedNavigationItem()
.then((response) => {
// Only refresh if viewing an object-page
if (response.pageReference && response.pageReference.type === 'standard__objectPage') {
// Do the refresh
navigationItemAPI.refreshNavigationItem()
.catch(function(error) {
console.log('Error in auto-refresh', error);
});
}
});
}                
  })