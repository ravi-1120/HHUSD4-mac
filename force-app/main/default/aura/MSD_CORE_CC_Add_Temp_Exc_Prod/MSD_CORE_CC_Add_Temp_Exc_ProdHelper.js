({
	addProduct : function(component, event, helper) {
        try{
            var nextConfigs = component.get('v.tabs');
            console.log('tabs debug before -->'+JSON.stringify(nextConfigs));
            var lastProdId = nextConfigs.length + 1;
            var lottabs = [{
                'id': '1',
                'label': 'Lot Details 1',
                'recId':'',
                'mode':'NEW',
                'lotParentId': '' 
            }];
            nextConfigs.push({'label': 'Product '+lastProdId, 
                              'id': JSON.stringify(lastProdId),
                              'recId': '',
                              'mode':'NEW',
                              'showLotDetailTabs':false,
                              'lottabs' : lottabs                              
                             });
            component.set("v.selectedTabId",JSON.stringify(lastProdId));
            console.log('tabs debug after-->'+JSON.stringify(nextConfigs));
            component.set('v.tabs', nextConfigs);
        }
        catch(e){}
	}
})