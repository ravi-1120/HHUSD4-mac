public class MSD_CORE_CC_NotesTriggerHandler {

    public static void restrictInsertOnClosedCases(List<Task> lstNewTasks){
        List<Id> lstCaseIds = new List<Id>();
        List<Id> lstClosedCaseIds = new List<Id>();
        for(Task t : lstNewTasks){
            if(t.WhatId != null && String.valueOf(t.WhatId).startsWith('500')){
                lstCaseIds.add(t.WhatId);
            }
        }
        
        if(!lstCaseIds.isEmpty()){
            for(Case c : [SELECT Id, Status FROM Case WHERE Id IN :lstCaseIds]){
                if( c.Status == 'Cancelled'){   // Removed isClosed
                    lstClosedCaseIds.add(c.Id);
                }
            }
        }
        
      /* if(!lstClosedCaseIds.isEmpty()){
            for(Task t : lstNewTasks){
                if(t.WhatId != null && String.valueOf(t.WhatId).startsWith('500')){
                    if(lstClosedCaseIds.contains(t.WhatId)){
                        t.addError('You are not allowed to add/update Tasks on Closed Cases.');
                    }
                }
            }
        }  */
    }
    
    public static void restrictDeleteOnClosedCases(List<Task> lstOldTasks){
        List<Id> lstCaseIds = new List<Id>();
        List<Id> lstClosedCaseIds = new List<Id>();
        for(Task t : lstOldTasks){
            if(t.WhatId != null && String.valueOf(t.WhatId).startsWith('500')){
                lstCaseIds.add(t.WhatId);
            }
        }
        
        if(!lstCaseIds.isEmpty()){
            for(Case c : [SELECT Id, Status FROM Case WHERE Id IN :lstCaseIds]){
                if(c.Status == 'Closed' || c.Status == 'Cancelled'){
                    lstClosedCaseIds.add(c.Id);
                }
            }
        }
        
        if(!lstClosedCaseIds.isEmpty()){
            for(Task t : lstOldTasks){
                if(t.WhatId != null && String.valueOf(t.WhatId).startsWith('500')){
                    if(lstClosedCaseIds.contains(t.WhatId)){
                        t.addError('You are not allowed to delete Tasks on Closed Cases.');
                    }
                }
            }
        }
    }
    
}