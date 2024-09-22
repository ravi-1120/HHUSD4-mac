({
    doInit : function(cmp, event, helper) {
        if(history.length < 6 || history.length >= 3)
            window.close();
        
        console.log('history.length');
        console.log(history.length);
        
        var workspaceAPI = cmp.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId; 
            var action = cmp.get("c.getIcon");
            action.setParams({ caseId: response.recordId});
            action.setCallback(this,
                               $A.getCallback(function(response1)
                                              {
                                                  var state = response1.getState();    
                                                  console.log('state'+state);
                                                  if (state == "SUCCESS")  
                                                  {
                                                      var result= response1.getReturnValue();
                                                      //var finalString=result.split("-");
                                                      //console.log('finalString');
                                                      //console.log(finalString);
                                                      //workspaceAPI.setTabIcon({tabId: focusedTabId, icon: "standard:"+ finalString[0], iconAlt: finalString[1]});   
                                                      if(result.indexOf('Adverse Event') != -1)
                                                          workspaceAPI.setTabIcon({tabId: focusedTabId, icon : "custom:custom3", iconAlt: result});   
                                                      else if(result.indexOf('Combo') != -1)
                                                          workspaceAPI.setTabIcon({tabId: focusedTabId, icon : "custom:custom86", iconAlt: result});   
                                                      else if(result.indexOf('Product Complaint') != -1)
                                                          workspaceAPI.setTabIcon({tabId: focusedTabId, icon : "custom:custom56", iconAlt: result});   
                                                      else if(result.indexOf('CR Request') != -1)
                                                          workspaceAPI.setTabIcon({tabId: focusedTabId, icon : "custom:custom41", iconAlt: result});   
                                                      else if(result.indexOf('Request') != -1)
                                                          workspaceAPI.setTabIcon({tabId: focusedTabId, icon : "custom:custom18", iconAlt: result});   
                                                      else if(result.indexOf('Temp') != -1)
                                                          workspaceAPI.setTabIcon({tabId: focusedTabId, icon : "custom:custom97", iconAlt: result});    
                                                  }
                                              }
                                             ));
            $A.enqueueAction(action);         
        });
    }
})