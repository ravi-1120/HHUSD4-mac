trigger PreventEventDeletion on EM_Event_vod__c (before delete) {
          for (EM_Event_vod__c c : Trigger.old) {
            c.addError('Events cannot be deleted!');
    }
}