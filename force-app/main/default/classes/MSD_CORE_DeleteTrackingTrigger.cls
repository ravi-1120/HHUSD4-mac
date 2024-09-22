/*
 *  MSD_CORE_DeleteTrackingTrigger
 *  Created By:     Samuel Rosen
 *  Created Date:   6/30/2014
 *  Description:    This is a trigger handler which calls a utility when
 *					a record is deleted so that a generic delete tracking
 *					record can be created.
 */
public with sharing class MSD_CORE_DeleteTrackingTrigger implements TriggersMVN.HandlerInterface {
    public void handle() {
    	// Excluding from testing since the utility below was created and is maintained
    	// by the Veeva Team
        if(!Test.isRunningTest()) {
            Map<String, String> status = MSD_CORE_RecordsOperationServices.postDeletedRecordsForTracking(Trigger.old); 
        }
    }
}