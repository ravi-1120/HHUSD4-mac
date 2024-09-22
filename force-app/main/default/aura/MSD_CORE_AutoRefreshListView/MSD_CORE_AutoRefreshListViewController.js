({
    doInit: function(component, event, helper)
    {
        helper.getListViewDetials(component,event);     
    },
    
    handleValueChange:function(component, event, helper)
    {
        component.set('v.isValid',false);
        const intervalId = component.get('v.intervalId');
        window.clearInterval(intervalId);
        component.set('v.intervalId', null);
        helper.setIntervalTime(component); 
	}
})